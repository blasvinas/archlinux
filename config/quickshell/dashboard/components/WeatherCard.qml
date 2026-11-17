import QtQuick
import "../../services" as Svc

// Compact current-conditions + 3-day forecast pane.
Card {
    id: root
    title: "Weather"

    Column {
        anchors.fill: parent
        spacing: 10

        // Current conditions
        Row {
            width: parent.width
            spacing: 12

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Svc.Weather.currentIcon()
                font.family: Svc.Theme.iconFont
                font.pixelSize: 44
                color: Svc.Theme.icon
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                Text {
                    text: Svc.Weather.ready ? (Svc.Weather.temp + Svc.Weather.unit) : "--"
                    font.family: Svc.Theme.fontFamily
                    font.pixelSize: 22
                    font.bold: true
                    color: Svc.Theme.text
                }
                Text {
                    text: Svc.Weather.description
                    font.family: Svc.Theme.fontFamily
                    font.pixelSize: 11
                    color: Svc.Theme.subtext
                    elide: Text.ElideRight
                    width: 150
                }
                Text {
                    text: Svc.Weather.location
                    font.family: Svc.Theme.fontFamily
                    font.pixelSize: 10
                    color: Svc.Theme.muted
                    elide: Text.ElideRight
                    width: 150
                }
            }
        }

        Rectangle { width: parent.width; height: 1; color: Svc.Theme.border }

        // 5-day forecast
        Row {
            width: parent.width
            property int shown: Math.min(5, Svc.Weather.forecast.length)
            Repeater {
                model: Svc.Weather.forecast.slice(0, 5)
                delegate: Column {
                    required property var modelData
                    width: parent.shown > 0 ? parent.width / parent.shown : parent.width
                    spacing: 3
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: modelData.day
                        font.family: Svc.Theme.fontFamily
                        font.pixelSize: 11
                        color: Svc.Theme.subtext
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Svc.Weather.iconFor(modelData.code, true)
                        font.family: Svc.Theme.iconFont
                        font.pixelSize: 22
                        color: Svc.Theme.icon
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: (Svc.Weather.useFahrenheit ? modelData.maxF : modelData.maxC) + "° / "
                            + (Svc.Weather.useFahrenheit ? modelData.minF : modelData.minC) + "°"
                        font.family: Svc.Theme.fontFamily
                        font.pixelSize: 10
                        color: Svc.Theme.text
                    }
                }
            }
        }
    }
}
