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
    anchor.rect.y: Svc.Theme.popupTop

    implicitWidth: 300
    implicitHeight: content.implicitHeight
    // `shown` drives the open state; the window stays mapped until the
    // fade-out finishes so closing animates too.
    property bool shown: false
    visible: shown || content.opacity > 0
    color: "transparent"

    HyprlandFocusGrab {
        windows: [pop]
        active: pop.shown
        onCleared: pop.shown = false
    }

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
            padding: 12
            spacing: 10

            Text {
                font.family: Svc.Theme.fontFamily
                text: "Battery"
                color: Svc.Theme.subtext
                font.pixelSize: Svc.Theme.fontXs
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
                    font.pixelSize: Svc.Theme.fontHero
                    color: pop.levelColor(Svc.Battery.percent, Svc.Battery.charging)
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Text {
                        font.family: Svc.Theme.fontFamily
                        text: Math.round(Svc.Battery.percent * 100) + "%"
                        color: Svc.Theme.text
                        font.pixelSize: Svc.Theme.font3xl
                        font.bold: true
                    }
                    Row {
                        spacing: 6
                        Text {
                            text: (Svc.Battery.charging ? String.fromCodePoint(0xF06A5) + "  " : "")
                                  + Svc.Battery.stateText()
                            font.family: Svc.Theme.iconFont
                            color: Svc.Theme.subtext
                            font.pixelSize: Svc.Theme.fontSm
                        }
                    }
                    Text {
                        font.family: Svc.Theme.fontFamily
                        visible: Svc.Battery.secondsRemaining > 0
                        text: (Svc.Battery.charging ? "Full in " : "")
                              + Svc.Battery.formatTime(Svc.Battery.secondsRemaining)
                              + (Svc.Battery.charging ? "" : " remaining")
                        color: Svc.Theme.subtext
                        font.pixelSize: Svc.Theme.fontSm
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
                    font.pixelSize: Svc.Theme.fontLg
                    color: Svc.Theme.subtext
                }
                Text {
                    font.family: Svc.Theme.fontFamily
                    text: "Health: " + Math.round(Svc.Battery.healthPercent) + "%"
                    color: Svc.Theme.subtext
                    font.pixelSize: Svc.Theme.fontSm
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
                font.family: Svc.Theme.fontFamily
                visible: Svc.Battery.peripherals.length > 0
                text: "Devices"
                color: Svc.Theme.subtext
                font.pixelSize: Svc.Theme.fontXs
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
                        font.pixelSize: Svc.Theme.font2xl
                        color: pop.levelColor(modelData.percentage, false)
                    }
                    Text {
                        font.family: Svc.Theme.fontFamily
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 90
                        elide: Text.ElideRight
                        text: modelData.model || "Device"
                        color: Svc.Theme.text
                        font.pixelSize: Svc.Theme.fontMd
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Math.round(modelData.percentage * 100) + "%"
                        color: Svc.Theme.subtext
                        font.pixelSize: Svc.Theme.fontMd
                        font.family: Svc.Theme.fontFamily
                    }
                }
            }
        }
    }
}
