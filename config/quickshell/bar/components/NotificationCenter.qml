import Quickshell
import Quickshell.Hyprland
import QtQuick
import "../../services" as Svc

// Dropdown notification history / center.
PopupWindow {
    id: pop

    property var barWindow
    property Item anchorItem

    anchor.window: barWindow
    anchor.rect.x: {
        if (!anchorItem || !barWindow)
            return 0;
        var p = anchorItem.mapToItem(barWindow.contentItem, 0, 0);
        return Math.round(p.x + anchorItem.width - width);
    }
    anchor.rect.y: barWindow ? barWindow.height : 32

    implicitWidth: 380
    implicitHeight: content.implicitHeight
    visible: false
    color: "transparent"

    HyprlandFocusGrab {
        windows: [pop]
        active: pop.visible
        onCleared: pop.visible = false
    }

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
            padding: 12
            spacing: 8

            // ---- Header --------------------------------------------------
            Item {
                width: parent.width - 24
                height: 24

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Notifications"
                    color: Svc.Theme.text
                    font.pixelSize: 15
                    font.bold: true
                }

                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 12

                    // Do-not-disturb toggle
                    Text {
                        text: String.fromCodePoint(
                            Svc.Notifications.doNotDisturb ? 0xF009C : 0xF009B)
                        font.family: Svc.Theme.iconFont
                        font.pixelSize: 16
                        color: Svc.Notifications.doNotDisturb ? Svc.Theme.danger : Svc.Theme.subtext
                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -4
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Svc.Notifications.toggleDnd()
                        }
                    }

                    // Clear all
                    Text {
                        text: String.fromCodePoint(0xF05E9) // delete-sweep
                        font.family: Svc.Theme.iconFont
                        font.pixelSize: 16
                        color: clearMouse.containsMouse ? Svc.Theme.danger : Svc.Theme.subtext
                        visible: Svc.Notifications.count > 0
                        MouseArea {
                            id: clearMouse
                            anchors.fill: parent
                            anchors.margins: -4
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Svc.Notifications.dismissAll()
                        }
                    }
                }
            }

            Rectangle { width: parent.width - 24; height: 1; color: Svc.Theme.hi }

            // ---- Empty state ---------------------------------------------
            Item {
                width: parent.width - 24
                height: 80
                visible: Svc.Notifications.count === 0
                Column {
                    anchors.centerIn: parent
                    spacing: 6
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: String.fromCodePoint(0xF009B)
                        font.family: Svc.Theme.iconFont
                        font.pixelSize: 28
                        color: Svc.Theme.hi
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Svc.Notifications.doNotDisturb
                            ? "Do not disturb is on" : "No notifications"
                        color: Svc.Theme.subtext
                        font.pixelSize: 12
                    }
                }
            }

            // ---- History list --------------------------------------------
            ListView {
                width: parent.width - 24
                height: Math.min(contentHeight, 460)
                clip: true
                spacing: 6
                visible: Svc.Notifications.count > 0
                model: Svc.Notifications.list
                boundsBehavior: Flickable.StopAtBounds

                delegate: Rectangle {
                    required property var modelData
                    width: ListView.view.width
                    implicitHeight: Math.max(52, row.implicitHeight + 16)
                    radius: Svc.Theme.radiusCard
                    color: Svc.Theme.base

                    Row {
                        id: row
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 8
                        spacing: 10

                        Item {
                            width: 32; height: 32

                            Image {
                                id: hi
                                anchors.fill: parent
                                source: modelData.image && modelData.image !== ""
                                    ? modelData.image
                                    : (modelData.appIcon ? "image://icon/" + modelData.appIcon : "")
                                sourceSize.width: 64
                                sourceSize.height: 64
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                                asynchronous: true
                                visible: status === Image.Ready
                            }
                            Rectangle {
                                anchors.fill: parent
                                radius: Svc.Theme.radiusSmall
                                visible: hi.status !== Image.Ready
                                color: Svc.Theme.hi
                                Text {
                                    anchors.centerIn: parent
                                    text: (modelData.appName || "?").slice(0, 1).toUpperCase()
                                    color: Svc.Theme.text
                                    font.pixelSize: 14
                                    font.bold: true
                                }
                            }
                        }

                        Column {
                            width: parent.width - 32 - 10 - 20
                            spacing: 2
                            Text {
                                width: parent.width
                                text: modelData.appName || ""
                                color: Svc.Theme.accent
                                font.pixelSize: 9
                                font.bold: true
                                elide: Text.ElideRight
                                visible: text.length > 0
                            }
                            Text {
                                width: parent.width
                                text: modelData.summary || ""
                                color: Svc.Theme.text
                                font.pixelSize: 12
                                font.bold: true
                                wrapMode: Text.Wrap
                                maximumLineCount: 2
                                elide: Text.ElideRight
                            }
                            Text {
                                width: parent.width
                                text: modelData.body || ""
                                color: Svc.Theme.subtext
                                font.pixelSize: 11
                                textFormat: Text.StyledText
                                wrapMode: Text.Wrap
                                maximumLineCount: 3
                                elide: Text.ElideRight
                                visible: text.length > 0
                                onLinkActivated: (link) => Quickshell.execDetached(["xdg-open", link])
                            }
                        }
                    }

                    Text {
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: 8
                        text: String.fromCodePoint(0xF0156)
                        font.family: Svc.Theme.iconFont
                        font.pixelSize: 12
                        color: itemClose.containsMouse ? Svc.Theme.danger : Svc.Theme.subtext
                        MouseArea {
                            id: itemClose
                            anchors.fill: parent
                            anchors.margins: -6
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Svc.Notifications.dismiss(modelData)
                        }
                    }
                }
            }
        }
    }
}
