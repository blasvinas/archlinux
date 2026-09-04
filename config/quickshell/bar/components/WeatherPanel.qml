import Quickshell
import Quickshell.Hyprland
import QtQuick
import "../../services" as Svc

// Dropdown with current conditions, details, and a 3-day forecast.
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

    implicitWidth: 320
    implicitHeight: content.implicitHeight
    visible: false
    color: "transparent"

    onVisibleChanged: if (visible) Svc.Weather.refresh()

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
            padding: Svc.Theme.panelPadding
            spacing: 10

            // Header: location + unit toggle + refresh
            Item {
                width: parent.width - 24
                height: 20

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 60
                    text: Svc.Weather.location || "Weather"
                    color: Svc.Theme.text
                    font.pixelSize: 14
                    font.bold: true
                    elide: Text.ElideRight
                }

                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 12

                    Text {
                        text: Svc.Weather.useFahrenheit ? "°F" : "°C"
                        color: Svc.Theme.accent
                        font.pixelSize: 13
                        font.bold: true
                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -4
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Svc.Weather.toggleUnit()
                        }
                    }
                    Text {
                        text: String.fromCodePoint(0xF0450) // refresh
                        font.family: Svc.Theme.iconFont
                        font.pixelSize: 15
                        color: Svc.Weather.loading ? Svc.Theme.accent : Svc.Theme.subtext
                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -4
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Svc.Weather.refresh()
                        }
                        RotationAnimation on rotation {
                            running: Svc.Weather.loading
                            loops: Animation.Infinite
                            from: 0; to: 360; duration: 1000
                        }
                    }
                }
            }

            // Current conditions
            Row {
                width: parent.width - 24
                spacing: 12

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Svc.Weather.currentIcon()
                    font.family: Svc.Theme.iconFont
                    font.pixelSize: 46
                    color: Svc.Theme.accent
                }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    Text {
                        text: Svc.Weather.temp + Svc.Weather.unit
                        color: Svc.Theme.text
                        font.pixelSize: 30
                        font.bold: true
                    }
                    Text {
                        text: Svc.Weather.description
                        color: Svc.Theme.subtext
                        font.pixelSize: 12
                    }
                    Text {
                        text: "Feels like " + Svc.Weather.feels + Svc.Weather.unit
                        color: Svc.Theme.subtext
                        font.pixelSize: 11
                    }
                }
            }

            Rectangle { width: parent.width - 24; height: 1; color: Svc.Theme.hi }

            // Detail chips
            Grid {
                width: parent.width - 24
                columns: 2
                rowSpacing: 6
                columnSpacing: 12

                Repeater {
                    model: [
                        { g: 0xF058E, label: Svc.Weather.humidity + "%  humidity" },
                        { g: 0xF059D, label: Svc.Weather.wind + " " + Svc.Weather.windUnit + "  " + Svc.Weather.windDir },
                        { g: 0xF059B, label: "Sunrise " + Svc.Weather.sunrise },
                        { g: 0xF059C, label: "Sunset " + Svc.Weather.sunset }
                    ]
                    delegate: Row {
                        required property var modelData
                        width: (parent.width - 12) / 2
                        spacing: 6
                        Text {
                            text: String.fromCodePoint(modelData.g)
                            font.family: Svc.Theme.iconFont
                            font.pixelSize: 15
                            color: Svc.Theme.subtext
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: modelData.label
                            color: Svc.Theme.text
                            font.pixelSize: 12
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }

            Rectangle { width: parent.width - 24; height: 1; color: Svc.Theme.hi }

            // 3-day forecast
            Row {
                width: parent.width - 24
                Repeater {
                    model: Svc.Weather.forecast
                    delegate: Column {
                        required property var modelData
                        width: (parent.width) / 3
                        spacing: 3
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: modelData.day
                            color: Svc.Theme.subtext
                            font.pixelSize: 11
                            font.bold: true
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Svc.Weather.iconFor(modelData.code, true)
                            font.family: Svc.Theme.iconFont
                            font.pixelSize: 22
                            color: Svc.Theme.text
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: (Svc.Weather.useFahrenheit ? modelData.maxF : modelData.maxC) + "°"
                            color: Svc.Theme.text
                            font.pixelSize: 12
                            font.bold: true
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: (Svc.Weather.useFahrenheit ? modelData.minF : modelData.minC) + "°"
                            color: Svc.Theme.subtext
                            font.pixelSize: 11
                        }
                    }
                }
            }
        }
    }
}
