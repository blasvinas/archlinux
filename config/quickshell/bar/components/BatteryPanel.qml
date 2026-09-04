import Quickshell
import Quickshell.Hyprland
import QtQuick
import "../../services" as Svc

// Dropdown panel: battery details + connected battery peripherals.
PopupWindow {
    id: pop

    property var barWindow
    property Item anchorItem

    function levelColor(pct, charging) {
        if (charging) return Svc.Theme.success;
        if (pct <= 0.15) return Svc.Theme.danger;
        if (pct <= 0.30) return Svc.Theme.warning;
        return Svc.Theme.text;
    }

    anchor.window: barWindow
    anchor.rect.x: {
        if (!anchorItem || !barWindow)
            return 0;
        var p = anchorItem.mapToItem(barWindow.contentItem, 0, 0);
        return Math.round(p.x + anchorItem.width - width);
    }
    anchor.rect.y: barWindow ? barWindow.height : 32

    implicitWidth: 300
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
            spacing: 10

            Text {
                text: "Battery"
                color: Svc.Theme.subtext
                font.pixelSize: 11
                font.bold: true
            }

            // ---- Primary battery -----------------------------------------
            Row {
                width: parent.width - 24
                spacing: 12

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Svc.Battery.batteryIcon()
                    font.family: Svc.Theme.iconFont
                    font.pixelSize: 34
                    color: pop.levelColor(Svc.Battery.percent, Svc.Battery.charging)
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Text {
                        text: Math.round(Svc.Battery.percent * 100) + "%"
                        color: Svc.Theme.text
                        font.pixelSize: 22
                        font.bold: true
                    }
                    Row {
                        spacing: 6
                        Text {
                            text: (Svc.Battery.charging ? String.fromCodePoint(0xF06A5) + "  " : "")
                                  + Svc.Battery.stateText()
                            font.family: Svc.Theme.iconFont
                            color: Svc.Theme.subtext
                            font.pixelSize: 12
                        }
                    }
                    Text {
                        visible: Svc.Battery.secondsRemaining > 0
                        text: (Svc.Battery.charging ? "Full in " : "")
                              + Svc.Battery.formatTime(Svc.Battery.secondsRemaining)
                              + (Svc.Battery.charging ? "" : " remaining")
                        color: Svc.Theme.subtext
                        font.pixelSize: 12
                    }
                }
            }

            // Health
            Row {
                visible: Svc.Battery.healthSupported && Svc.Battery.healthPercent > 0
                width: parent.width - 24
                spacing: 8
                Text {
                    text: String.fromCodePoint(0xF02D1) // heart-pulse
                    font.family: Svc.Theme.iconFont
                    font.pixelSize: 14
                    color: Svc.Theme.subtext
                }
                Text {
                    text: "Health: " + Math.round(Svc.Battery.healthPercent) + "%"
                    color: Svc.Theme.subtext
                    font.pixelSize: 12
                }
            }

            // ---- Peripherals ---------------------------------------------
            Rectangle {
                visible: Svc.Battery.peripherals.length > 0
                width: parent.width - 24
                height: 1
                color: Svc.Theme.hi
            }

            Text {
                visible: Svc.Battery.peripherals.length > 0
                text: "Devices"
                color: Svc.Theme.subtext
                font.pixelSize: 11
                font.bold: true
            }

            Repeater {
                model: Svc.Battery.peripherals
                delegate: Row {
                    required property var modelData
                    width: parent.width - 24
                    spacing: 10

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Svc.Battery.iconFor(modelData.percentage, false)
                        font.family: Svc.Theme.iconFont
                        font.pixelSize: 18
                        color: pop.levelColor(modelData.percentage, false)
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 90
                        elide: Text.ElideRight
                        text: modelData.model || "Device"
                        color: Svc.Theme.text
                        font.pixelSize: 13
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Math.round(modelData.percentage * 100) + "%"
                        color: Svc.Theme.subtext
                        font.pixelSize: 13
                        font.family: Svc.Theme.fontFamily
                    }
                }
            }
        }
    }
}
