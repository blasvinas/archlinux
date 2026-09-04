import Quickshell
import Quickshell.Hyprland
import QtQuick
import "../../services" as Svc

// Dropdown panel listing Bluetooth devices with connect / disconnect controls.
PopupWindow {
    id: pop

    property var barWindow
    property Item anchorItem
    property string selectedAddr: ""   // device whose action row is expanded

    anchor.window: barWindow
    anchor.rect.x: {
        if (!anchorItem || !barWindow)
            return 0;
        var p = anchorItem.mapToItem(barWindow.contentItem, 0, 0);
        return Math.round(p.x + anchorItem.width - width);
    }
    anchor.rect.y: barWindow ? barWindow.height : 32

    implicitWidth: 340
    implicitHeight: content.implicitHeight
    visible: false
    color: "transparent"

    HyprlandFocusGrab {
        windows: [pop]
        active: pop.visible
        onCleared: pop.visible = false
    }

    onVisibleChanged: if (!visible) selectedAddr = ""

    Rectangle {
        id: content
        anchors.fill: parent
        implicitHeight: layout.implicitHeight
        radius: Svc.Theme.radiusLarge
        color: Svc.Theme.popupBg
        border.color: Svc.Theme.border
        border.width: 1

        Column {
            id: layout
            width: parent.width
            padding: 10
            spacing: 8

            // ---- Header --------------------------------------------------
            Item {
                width: parent.width - 20
                height: 24

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Bluetooth"
                    color: Svc.Theme.text
                    font.pixelSize: 15
                    font.bold: true
                }

                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 10

                    // Scan / discovery toggle
                    Text {
                        text: String.fromCodePoint(0xF0450)
                        font.family: Svc.Theme.iconFont
                        font.pixelSize: 16
                        color: Svc.Bt.discovering ? Svc.Theme.accent : Svc.Theme.subtext
                        visible: Svc.Bt.enabled
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Svc.Bt.setDiscovering(!Svc.Bt.discovering)
                        }
                        RotationAnimation on rotation {
                            running: Svc.Bt.discovering
                            loops: Animation.Infinite
                            from: 0; to: 360; duration: 1000
                        }
                    }

                    // Power toggle
                    Rectangle {
                        width: 40; height: 20; radius: Svc.Theme.radiusPill
                        color: Svc.Bt.enabled ? Svc.Theme.accent : Svc.Theme.hi
                        Rectangle {
                            width: 16; height: 16; radius: Svc.Theme.radiusPill
                            color: Svc.Theme.white
                            anchors.verticalCenter: parent.verticalCenter
                            x: Svc.Bt.enabled ? parent.width - width - 2 : 2
                            Behavior on x { NumberAnimation { duration: 120 } }
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Svc.Bt.setEnabled(!Svc.Bt.enabled)
                        }
                    }
                }
            }

            Rectangle { width: parent.width - 20; height: 1; color: Svc.Theme.hi }

            Text {
                visible: !Svc.Bt.available
                text: "No Bluetooth adapter"
                color: Svc.Theme.subtext
                font.pixelSize: 13
            }
            Text {
                visible: Svc.Bt.available && !Svc.Bt.enabled
                text: "Bluetooth is turned off"
                color: Svc.Theme.subtext
                font.pixelSize: 13
            }

            // ---- Device list ---------------------------------------------
            ListView {
                id: list
                visible: Svc.Bt.enabled
                width: parent.width - 20
                height: Math.min(contentHeight, 380)
                clip: true
                spacing: 2
                model: Svc.Bt.sortedDevices
                boundsBehavior: Flickable.StopAtBounds

                delegate: Column {
                    required property var modelData
                    width: list.width
                    readonly property bool expanded: pop.selectedAddr === modelData.address

                    Rectangle {
                        width: parent.width
                        height: 40
                        radius: Svc.Theme.radiusMedium
                        color: mouse.containsMouse || parent.expanded ? Svc.Theme.hi : "transparent"

                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: 8
                            anchors.right: parent.right
                            anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 10

                            Text {
                                text: Svc.Bt.deviceIcon(modelData.icon)
                                font.family: Svc.Theme.iconFont
                                font.pixelSize: 18
                                color: modelData.connected ? Svc.Theme.accent : Svc.Theme.text
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 120
                                Text {
                                    text: modelData.name || modelData.address
                                    color: modelData.connected ? Svc.Theme.accent : Svc.Theme.text
                                    font.pixelSize: 13
                                    font.bold: modelData.connected
                                    elide: Text.ElideRight
                                    width: parent.width
                                }
                                Text {
                                    property string st: modelData.connected ? "Connected"
                                        : (modelData.paired ? "Paired" : "Not paired")
                                    text: modelData.batteryAvailable
                                        ? st + "  •  " + Math.round(modelData.battery * 100) + "%"
                                        : st
                                    color: Svc.Theme.subtext
                                    font.pixelSize: 10
                                }
                            }

                            // Connection status dot / spinner
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.pairing ? String.fromCodePoint(0xF0450)
                                    : String.fromCodePoint(modelData.connected ? 0xF00B1 : 0xF00AF)
                                font.family: Svc.Theme.iconFont
                                font.pixelSize: 14
                                color: modelData.connected ? Svc.Theme.success : Svc.Theme.subtext
                                RotationAnimation on rotation {
                                    running: modelData.pairing
                                    loops: Animation.Infinite
                                    from: 0; to: 360; duration: 1000
                                }
                            }
                        }

                        MouseArea {
                            id: mouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: pop.selectedAddr =
                                pop.selectedAddr === modelData.address ? "" : modelData.address
                        }
                    }

                    // ---- Expanded action row -----------------------------
                    Item {
                        width: parent.width
                        height: parent.expanded ? 40 : 0
                        clip: true
                        visible: height > 0
                        Behavior on height { NumberAnimation { duration: 120 } }

                        Row {
                            anchors.fill: parent
                            anchors.margins: 4
                            layoutDirection: Qt.RightToLeft
                            spacing: 6

                            Rectangle {
                                width: 110; height: 30; radius: Svc.Theme.radiusMedium
                                color: modelData.connected ? Svc.Theme.danger : Svc.Theme.accent
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.connected ? "Disconnect" : "Connect"
                                    color: Svc.Theme.crust
                                    font.pixelSize: 12
                                    font.bold: true
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Svc.Bt.toggleConnection(modelData)
                                }
                            }

                            Rectangle {
                                visible: modelData.paired || modelData.bonded
                                width: 90; height: 30; radius: Svc.Theme.radiusMedium
                                color: "transparent"
                                border.color: Svc.Theme.danger
                                border.width: 1
                                Text {
                                    anchors.centerIn: parent
                                    text: "Forget"
                                    color: Svc.Theme.danger
                                    font.pixelSize: 12
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: { modelData.forget(); pop.selectedAddr = ""; }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
