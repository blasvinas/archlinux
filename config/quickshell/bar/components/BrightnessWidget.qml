import QtQuick
import "../../services" as Svc

// Bar indicator: brightness icon + percentage. Scroll to adjust, click for slider.
Item {
    id: root

    property var barWindow

    visible: Svc.Brightness.available
    implicitWidth: visible ? row.implicitWidth + 12 : 0
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
            text: Svc.Brightness.brightnessIcon()
            font.family: Svc.Theme.iconFont
            font.pixelSize: Svc.Theme.iconSize
            color: Svc.Theme.icon
        }

        RevealLabel {
            anchors.verticalCenter: parent.verticalCenter
            text: Math.round(Svc.Brightness.percent * 100) + "%"
            revealed: mouse.containsMouse || panel.shown || flash.running
        }
    }

    // Briefly show the percentage after brightness changes (keys / scroll).
    Timer { id: flash; interval: 1500 }
    Connections {
        target: Svc.Brightness
        function onPercentChanged() { flash.restart(); }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: panel.shown = !panel.shown
        onWheel: (w) => Svc.Brightness.step(w.angleDelta.y > 0 ? 5 : -5)
    }

    BrightnessPanel {
        id: panel
        barWindow: root.barWindow
        anchorItem: root
    }
}
