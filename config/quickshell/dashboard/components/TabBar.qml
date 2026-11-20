import QtQuick
import "../../services" as Svc

// Pill-style tab selector. `tabs` is an array of { glyph, label }; the current
// index is exposed via `currentIndex` and updated on click.
Row {
    id: root

    property var tabs: []
    property int currentIndex: 0
    spacing: 6

    Repeater {
        model: root.tabs
        delegate: Rectangle {
            required property int index
            required property var modelData
            readonly property bool active: root.currentIndex === index

            height: 32
            width: tabRow.width + 24
            radius: Svc.Theme.radiusPill
            color: active ? Svc.Theme.accent
                          : (ma.containsMouse ? Svc.Theme.hover : Svc.Theme.surface0)
            Behavior on color { ColorAnimation { duration: 120 } }

            Row {
                id: tabRow
                anchors.centerIn: parent
                spacing: 6

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: modelData.glyph
                    font.family: Svc.Theme.iconFont
                    font.pixelSize: Svc.Theme.fontLg
                    color: active ? Svc.Theme.accentFg : Svc.Theme.icon
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: modelData.label
                    font.family: Svc.Theme.fontFamily
                    font.pixelSize: Svc.Theme.fontSm
                    font.bold: active
                    color: active ? Svc.Theme.accentFg : Svc.Theme.text
                }
            }

            MouseArea {
                id: ma
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.currentIndex = index
            }
        }
    }
}
