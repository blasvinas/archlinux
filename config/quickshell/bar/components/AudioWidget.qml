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
        color: mouse.containsMouse || panel.shown ? Svc.Theme.hover : "transparent"
        Behavior on color { ColorAnimation { duration: 120; easing.type: Easing.OutQuad } }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 0

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Svc.Audio.sinkIcon()
            font.family: Svc.Theme.iconFont
            font.pixelSize: Svc.Theme.iconSize
            color: Svc.Audio.sinkMuted ? Svc.Theme.subtext : Svc.Theme.icon
        }

        RevealLabel {
            anchors.verticalCenter: parent.verticalCenter
            text: Svc.Audio.sinkMuted ? "muted" : Math.round(Svc.Audio.sinkVolume * 100) + "%"
            revealed: mouse.containsMouse || panel.shown || flash.running
        }
    }

    // Briefly show the level after volume / mute changes (keys, scroll, apps).
    Timer { id: flash; interval: 1500 }
    Connections {
        target: Svc.Audio
        function onSinkVolumeChanged() { flash.restart(); }
        function onSinkMutedChanged() { flash.restart(); }
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
                panel.shown = !panel.shown;
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
