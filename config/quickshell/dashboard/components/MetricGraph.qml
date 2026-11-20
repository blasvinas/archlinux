import QtQuick
import "../../services" as Svc

// A Card showing one metric: glyph + title, a big current-value readout, an
// optional sub-caption, and an area graph of its recent history.
Card {
    id: root

    property string glyph: ""
    property string metricTitle: ""
    property string valueText: ""
    property string caption: ""
    property var values: []
    property real maxValue: 100
    property color accent: Svc.Theme.accent

    // Card.title is left empty; we render a richer custom header instead.
    title: ""

    Column {
        anchors.fill: parent
        spacing: 8

        // Header: icon + name on the left, big value on the right.
        Item {
            width: parent.width
            height: 34

            Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.glyph
                    font.family: Svc.Theme.iconFont
                    font.pixelSize: Svc.Theme.font2xl
                    color: root.accent
                }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 0
                    Text {
                        text: root.metricTitle
                        font.family: Svc.Theme.fontFamily
                        font.pixelSize: Svc.Theme.fontSm
                        font.bold: true
                        color: Svc.Theme.text
                    }
                    Text {
                        visible: root.caption.length > 0
                        text: root.caption
                        font.family: Svc.Theme.fontFamily
                        font.pixelSize: Svc.Theme.fontXxs
                        color: Svc.Theme.subtext
                    }
                }
            }

            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: root.valueText
                font.family: Svc.Theme.fontFamily
                font.pixelSize: Svc.Theme.font3xl
                font.bold: true
                color: root.accent
            }
        }

        Graph {
            width: parent.width
            height: parent.height - 34 - 8
            values: root.values
            maxValue: root.maxValue
            lineColor: root.accent
        }
    }
}
