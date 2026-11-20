import QtQuick
import "../../services" as Svc

// Per-core CPU utilisation shown as a strip of vertical bars.
Column {
    id: root
    spacing: 6

    function barColor(p) {
        if (p >= 90) return Svc.Theme.danger;
        if (p >= 70) return Svc.Theme.warning;
        return Svc.Theme.accent;
    }

    Text {
        text: "Per-core"
        font.family: Svc.Theme.fontFamily
        font.pixelSize: Svc.Theme.fontXs
        color: Svc.Theme.subtext
    }

    Row {
        spacing: 4
        Repeater {
            model: Svc.SysInfo.cpuCores
            delegate: Rectangle {
                required property var modelData
                width: 13
                height: 52
                radius: 4
                color: Svc.Theme.surface0

                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    radius: 4
                    color: root.barColor(modelData)
                    height: Math.max(2, parent.height * (modelData / 100))
                    Behavior on height { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
                }
            }
        }
    }
}
