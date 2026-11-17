import QtQuick
import "../../services" as Svc

// Row of spectrum bars driven by the Cava service. Designed to sit behind the
// media card content as an ambient backdrop.
Item {
    id: root

    readonly property var values: Svc.Cava.values
    property color barColor: Svc.Theme.accent

    Row {
        id: row
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: parent.height
        spacing: 3

        Repeater {
            model: root.values.length
            delegate: Item {
                required property int index
                width: (row.width - (root.values.length - 1) * row.spacing) / Math.max(1, root.values.length)
                height: row.height

                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    radius: width / 2
                    color: root.barColor
                    height: Math.max(2, parent.height * (root.values[index] || 0))
                    Behavior on height { NumberAnimation { duration: 90; easing.type: Easing.OutQuad } }
                }
            }
        }
    }
}
