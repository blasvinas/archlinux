import Quickshell
import Quickshell.Hyprland
import QtQuick
import "../../services" as Svc

// Dropdown panel listing Wi-Fi networks with connect / disconnect controls.
PopupWindow {
    id: pop

    property var barWindow
    property Item anchorItem
    // SSID whose action row (password / disconnect) is expanded.
    property string selectedSsid: ""

    anchor.window: barWindow
    anchor.rect.x: {
        if (!anchorItem || !barWindow)
            return 0;
        var p = anchorItem.mapToItem(barWindow.contentItem, 0, 0);
        return Math.round(p.x + anchorItem.width - width);
    }
    anchor.rect.y: Svc.Theme.popupTop

    implicitWidth: 340
    implicitHeight: content.implicitHeight
    // `shown` drives the open state; the window stays mapped until the
    // fade-out finishes so closing animates too.
    property bool shown: false
    visible: shown || content.opacity > 0
    color: "transparent"

    // Click outside to dismiss.
    HyprlandFocusGrab {
        id: grab
        windows: [pop]
        active: pop.shown
        onCleared: pop.shown = false
    }

    onVisibleChanged: if (!visible) selectedSsid = ""

    Rectangle {
        id: content
        anchors.fill: parent
        implicitHeight: layout.implicitHeight
        radius: Svc.Theme.radiusLarge
        color: Svc.Theme.popupBg
        opacity: pop.shown ? 1 : 0
        transform: Translate { y: pop.shown ? 0 : -8; Behavior on y { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } } }
        Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutQuad } }
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
                    font.family: Svc.Theme.fontFamily
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Wi-Fi"
                    color: Svc.Theme.text
                    font.pixelSize: Svc.Theme.fontLg
                    font.bold: true
                }

                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 10

                    // Refresh / rescan
                    Text {
                        text: String.fromCodePoint(0xF0450)
                        font.family: Svc.Theme.iconFont
                        font.pixelSize: Svc.Theme.fontXl
                        color: Svc.Network.scanning ? Svc.Theme.accent : Svc.Theme.subtext
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Svc.Network.refresh(true)
                        }
                        RotationAnimation on rotation {
                            running: Svc.Network.scanning
                            loops: Animation.Infinite
                            from: 0; to: 360; duration: 1000
                        }
                    }

                    // Wi-Fi radio toggle
                    Rectangle {
                        width: 40; height: 20; radius: Svc.Theme.radiusPill
                        color: Svc.Network.wifiEnabled ? Svc.Theme.accent : Svc.Theme.hi
                        Rectangle {
                            width: 16; height: 16; radius: Svc.Theme.radiusPill
                            color: Svc.Theme.white
                            anchors.verticalCenter: parent.verticalCenter
                            x: Svc.Network.wifiEnabled ? parent.width - width - 2 : 2
                            Behavior on x { NumberAnimation { duration: 120 } }
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Svc.Network.setWifiEnabled(!Svc.Network.wifiEnabled)
                        }
                    }
                }
            }

            Rectangle { width: parent.width - 20; height: 1; color: Svc.Theme.hi }

            // ---- Network list --------------------------------------------
            Text {
                font.family: Svc.Theme.fontFamily
                visible: !Svc.Network.wifiEnabled
                text: "Wi-Fi is turned off"
                color: Svc.Theme.subtext
                font.pixelSize: Svc.Theme.fontMd
            }

            ListView {
                id: list
                visible: Svc.Network.wifiEnabled
                width: parent.width - 20
                height: Math.min(contentHeight, 360)
                clip: true
                spacing: 2
                model: Svc.Network.networks
                boundsBehavior: Flickable.StopAtBounds

                delegate: Column {
                    required property var modelData
                    width: list.width
                    readonly property bool expanded: pop.selectedSsid === modelData.ssid

                    Rectangle {
                        width: parent.width
                        height: 36
                        radius: Svc.Theme.radiusMedium
                        color: mouse.containsMouse || parent.expanded ? Svc.Theme.hi : "transparent"
                        Behavior on color { ColorAnimation { duration: 120; easing.type: Easing.OutQuad } }

                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 8

                            Text {
                                text: Svc.Network.signalIcon(modelData.signal, modelData.secure)
                                font.family: Svc.Theme.iconFont
                                font.pixelSize: Svc.Theme.fontXl
                                color: modelData.active ? Svc.Theme.accent : Svc.Theme.text
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                font.family: Svc.Theme.fontFamily
                                text: modelData.ssid
                                color: modelData.active ? Svc.Theme.accent : Svc.Theme.text
                                font.pixelSize: Svc.Theme.fontMd
                                font.bold: modelData.active
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        Row {
                            anchors.right: parent.right
                            anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 6

                            Text {
                                font.family: Svc.Theme.fontFamily
                                visible: modelData.active
                                text: "connected"
                                color: Svc.Theme.subtext
                                font.pixelSize: Svc.Theme.fontXs
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                visible: modelData.secure
                                text: String.fromCodePoint(0xF033E)
                                font.family: Svc.Theme.iconFont
                                font.pixelSize: Svc.Theme.fontMd
                                color: Svc.Theme.subtext
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            id: mouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (modelData.active) {
                                    pop.selectedSsid = pop.selectedSsid === modelData.ssid ? "" : modelData.ssid;
                                } else if (modelData.secure) {
                                    pop.selectedSsid = pop.selectedSsid === modelData.ssid ? "" : modelData.ssid;
                                    pw.text = "";
                                } else {
                                    Svc.Network.connectToSsid(modelData.ssid, "");
                                }
                            }
                        }
                    }

                    // ---- Expanded action area --------------------------
                    Item {
                        width: parent.width
                        height: parent.expanded ? 40 : 0
                        clip: true
                        visible: height > 0
                        Behavior on height { NumberAnimation { duration: 120 } }

                        // Disconnect (for the active network)
                        Row {
                            visible: modelData.active
                            anchors.fill: parent
                            anchors.margins: 4
                            layoutDirection: Qt.RightToLeft
                            Rectangle {
                                width: 110; height: 30; radius: Svc.Theme.radiusMedium
                                color: Svc.Theme.danger
                                Text {
                                    font.family: Svc.Theme.fontFamily
                                    anchors.centerIn: parent
                                    text: "Disconnect"
                                    color: Svc.Theme.crust
                                    font.pixelSize: Svc.Theme.fontSm
                                    font.bold: true
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: { Svc.Network.disconnect(); pop.selectedSsid = ""; }
                                }
                            }
                        }

                        // Password entry (for secured, non-active networks)
                        Row {
                            visible: !modelData.active && modelData.secure
                            anchors.fill: parent
                            anchors.margins: 4
                            spacing: 6

                            Rectangle {
                                width: parent.width - 90
                                height: 30
                                radius: Svc.Theme.radiusMedium
                                color: Svc.Theme.crust
                                border.color: pw.activeFocus ? Svc.Theme.accent : Svc.Theme.hi
                                TextInput {
                                    id: pw
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    verticalAlignment: TextInput.AlignVCenter
                                    color: Svc.Theme.text
                                    font.pixelSize: Svc.Theme.fontMd
                                    echoMode: TextInput.Password
                                    clip: true
                                    onAccepted: {
                                        Svc.Network.connectToSsid(modelData.ssid, text);
                                        pop.selectedSsid = "";
                                    }
                                    Text {
                                        font.family: Svc.Theme.fontFamily
                                        anchors.fill: parent
                                        verticalAlignment: Text.AlignVCenter
                                        text: "Password"
                                        color: Svc.Theme.subtext
                                        font.pixelSize: Svc.Theme.fontMd
                                        visible: pw.text.length === 0 && !pw.activeFocus
                                    }
                                }
                            }
                            Rectangle {
                                width: 84; height: 30; radius: Svc.Theme.radiusMedium
                                color: Svc.Theme.accent
                                Text {
                                    font.family: Svc.Theme.fontFamily
                                    anchors.centerIn: parent
                                    text: "Connect"
                                    color: Svc.Theme.crust
                                    font.pixelSize: Svc.Theme.fontSm
                                    font.bold: true
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        Svc.Network.connectToSsid(modelData.ssid, pw.text);
                                        pop.selectedSsid = "";
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
