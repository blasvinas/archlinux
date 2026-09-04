import QtQuick
import "../../services" as Svc

// Simple horizontal slider. Value is 0..1. Emits `moved` while dragging.
Item {
    id: root

    property real value: 0
    property color fillColor: Svc.Theme.accent
    property color trackColor: Svc.Theme.hi

    signal moved(real value)

    implicitHeight: 16

    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 6
        radius: Svc.Theme.radiusPill
        color: root.trackColor

        Rectangle {
            width: parent.width * Math.max(0, Math.min(root.value, 1))
            height: parent.height
            radius: Svc.Theme.radiusPill
            color: root.fillColor
        }
    }

    Rectangle {
        width: 14
        height: 14
        radius: Svc.Theme.radiusPill
        color: Svc.Theme.white
        anchors.verticalCenter: parent.verticalCenter
        x: (root.width - width) * Math.max(0, Math.min(root.value, 1))
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onPressed: (m) => setFromX(m.x)
        onPositionChanged: (m) => setFromX(m.x)

        function setFromX(px) {
            root.moved(Math.max(0, Math.min(px / root.width, 1)));
        }
    }
}
