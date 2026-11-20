import QtQuick
import "../../services" as Svc

// A bar label that slides open/closed. Put it in a Row with spacing: 0 —
// the gap to the preceding icon is part of this item so it collapses fully.
Item {
    id: root

    property alias text: label.text
    property alias color: label.color
    property bool revealed: true
    property int gap: 5

    implicitWidth: revealed ? label.implicitWidth + gap : 0
    implicitHeight: label.implicitHeight
    clip: true
    opacity: revealed ? 1 : 0

    Behavior on implicitWidth { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
    Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }

    Text {
        id: label
        x: root.gap
        anchors.verticalCenter: parent.verticalCenter
        color: Svc.Theme.text
        font.pixelSize: Svc.Theme.fontMd
        font.family: Svc.Theme.fontFamily
    }
}
