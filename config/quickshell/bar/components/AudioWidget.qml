import QtQuick
import "../../services" as Svc

// Bar indicator: volume icon + percentage. Scroll to adjust, click for panel,
// middle-click to mute.
Item {
    id: root

    property var barWindow

    implicitWidth: row.implicitWidth + 12
    implicitHeight: parent ? parent.height : 32

    Rectangle {
        anchors.fill: parent
        radius: Svc.Theme.radiusMedium
        color: mouse.containsMouse || panel.visible ? Svc.Theme.hover : "transparent"
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 4

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Svc.Audio.sinkIcon()
            font.family: Svc.Theme.iconFont
            font.pixelSize: 16
            color: Svc.Audio.sinkMuted ? Svc.Theme.subtext : Svc.Theme.text
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Svc.Audio.sinkMuted ? "muted" : Math.round(Svc.Audio.sinkVolume * 100) + "%"
            color: Svc.Theme.text
            font.pixelSize: 12
            font.family: Svc.Theme.fontFamily
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor
        onClicked: (m) => {
            if (m.button === Qt.MiddleButton)
                Svc.Audio.toggleSinkMute();
            else
                panel.visible = !panel.visible;
        }
        onWheel: (w) => {
            Svc.Audio.stepSink(w.angleDelta.y > 0 ? 0.05 : -0.05);
        }
    }

    AudioPanel {
        id: panel
        barWindow: root.barWindow
        anchorItem: root
    }
}
