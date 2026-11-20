import Quickshell
import Quickshell.Hyprland
import QtQuick
import "../../services" as Svc

// Dropdown: current conditions, details, hourly strip and a 7-day forecast.
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
    anchor.rect.y: Svc.Theme.popupTop

    implicitWidth: 360
    implicitHeight: content.implicitHeight
    // `shown` drives the open state; the window stays mapped until the
    // fade-out finishes so closing animates too.
    property bool shown: false
    visible: shown || content.opacity > 0
    color: "transparent"

    onVisibleChanged: if (visible) Svc.Weather.refresh()

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
            padding: Svc.Theme.panelPadding
            spacing: 10

            readonly property real innerWidth: width - 2 * padding

            // Header: location + unit toggle + refresh
            Item {
                width: parent.innerWidth
                height: 20

                Text {
                    font.family: Svc.Theme.fontFamily
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 60
                    text: Svc.Weather.location || "Weather"
                    color: Svc.Theme.text
                    font.pixelSize: Svc.Theme.fontLg
                    font.bold: true
                    elide: Text.ElideRight
                }

                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 12

                    Text {
                        font.family: Svc.Theme.fontFamily
                        text: Svc.Weather.useFahrenheit ? "°F" : "°C"
                        color: Svc.Theme.accent
                        font.pixelSize: Svc.Theme.fontMd
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
                        font.pixelSize: Svc.Theme.fontLg
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
                width: parent.innerWidth
                spacing: 12

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Svc.Weather.currentIcon()
                    font.family: Svc.Theme.iconFont
                    font.pixelSize: Svc.Theme.fontDisplay
                    color: Svc.Theme.accent
                }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    Text {
                        font.family: Svc.Theme.fontFamily
                        text: Svc.Weather.temp + Svc.Weather.unit
                        color: Svc.Theme.text
                        font.pixelSize: Svc.Theme.fontHero
                        font.bold: true
                    }
                    Text {
                        font.family: Svc.Theme.fontFamily
                        text: Svc.Weather.description
                        color: Svc.Theme.subtext
                        font.pixelSize: Svc.Theme.fontSm
                    }
                    Text {
                        font.family: Svc.Theme.fontFamily
                        text: "Feels like " + Svc.Weather.feels + Svc.Weather.unit
                        color: Svc.Theme.subtext
                        font.pixelSize: Svc.Theme.fontXs
                    }
                }
            }

            Rectangle { width: parent.innerWidth; height: 1; color: Svc.Theme.hi }

            // Detail chips
            Grid {
                width: parent.innerWidth
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
                            font.pixelSize: Svc.Theme.fontLg
                            color: Svc.Theme.subtext
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            font.family: Svc.Theme.fontFamily
                            text: modelData.label
                            color: Svc.Theme.text
                            font.pixelSize: Svc.Theme.fontSm
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }

            Rectangle { width: parent.innerWidth; height: 1; color: Svc.Theme.hi }

            // Hourly forecast (horizontally scrollable)
            ListView {
                id: hourlyView
                width: parent.innerWidth
                height: 84
                orientation: ListView.Horizontal
                clip: true
                spacing: 4
                boundsBehavior: Flickable.StopAtBounds
                model: Svc.Weather.hourly

                delegate: Column {
                    required property var modelData
                    width: 46
                    height: hourlyView.height
                    spacing: 4

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: modelData.hour
                        font.family: Svc.Theme.fontFamily
                        font.pixelSize: Svc.Theme.fontXs
                        font.bold: modelData.hour === "Now"
                        color: modelData.hour === "Now" ? Svc.Theme.accent : Svc.Theme.subtext
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Svc.Weather.iconFor(modelData.code, modelData.isDay)
                        font.family: Svc.Theme.iconFont
                        font.pixelSize: Svc.Theme.font3xl
                        color: Svc.Theme.text
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: (Svc.Weather.useFahrenheit ? modelData.tempF : modelData.tempC) + "°"
                        font.family: Svc.Theme.fontFamily
                        font.pixelSize: Svc.Theme.fontSm
                        font.bold: true
                        color: Svc.Theme.text
                    }
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 1
                        visible: modelData.pop > 0
                        Text {
                            text: String.fromCodePoint(0xF0597)
                            font.family: Svc.Theme.iconFont
                            font.pixelSize: Svc.Theme.fontXxs
                            color: Svc.Theme.accent
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: modelData.pop + "%"
                            font.family: Svc.Theme.fontFamily
                            font.pixelSize: Svc.Theme.fontXxs
                            color: Svc.Theme.accent
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }

            Rectangle { width: parent.innerWidth; height: 1; color: Svc.Theme.hi }

            // 7-day forecast (one row per day)
            Column {
                width: parent.innerWidth
                spacing: 2

                Repeater {
                    model: Svc.Weather.forecast
                    delegate: Item {
                        required property var modelData
                        width: parent.width
                        height: 26

                        Text {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            width: 46
                            text: modelData.day
                            font.family: Svc.Theme.fontFamily
                            font.pixelSize: Svc.Theme.fontSm
                            font.bold: modelData.day === "Today"
                            color: modelData.day === "Today" ? Svc.Theme.text : Svc.Theme.subtext
                        }
                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 54
                            anchors.verticalCenter: parent.verticalCenter
                            text: Svc.Weather.iconFor(modelData.code, true)
                            font.family: Svc.Theme.iconFont
                            font.pixelSize: Svc.Theme.fontXl
                            color: Svc.Theme.icon
                        }
                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 84
                            anchors.right: hilo.left
                            anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.desc
                            font.family: Svc.Theme.fontFamily
                            font.pixelSize: Svc.Theme.fontXs
                            color: Svc.Theme.subtext
                            elide: Text.ElideRight
                        }
                        Row {
                            id: hilo
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 6
                            Text {
                                text: (Svc.Weather.useFahrenheit ? modelData.maxF : modelData.maxC) + "°"
                                font.family: Svc.Theme.fontFamily
                                font.pixelSize: Svc.Theme.fontSm
                                font.bold: true
                                color: Svc.Theme.text
                            }
                            Text {
                                text: (Svc.Weather.useFahrenheit ? modelData.minF : modelData.minC) + "°"
                                font.family: Svc.Theme.fontFamily
                                font.pixelSize: Svc.Theme.fontSm
                                color: Svc.Theme.muted
                            }
                        }
                    }
                }
            }
        }
    }
}
