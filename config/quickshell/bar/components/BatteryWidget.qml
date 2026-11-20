import QtQuick
import "../../services" as Svc

// Bar indicator: battery icon + percentage. Click for details. Hidden if no battery.
Item {
    id: root

    property var barWindow

    visible: Svc.Battery.available
    implicitWidth: visible ? row.implicitWidth + 12 : 0
    implicitHeight: parent ? parent.height : 32

    function levelColor() {
        if (Svc.Battery.charging) return Svc.Theme.success;
        if (Svc.Battery.percent <= 0.15) return Svc.Theme.danger;
        if (Svc.Battery.percent <= 0.30) return Svc.Theme.warning;
        return Svc.Theme.icon;
    }

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
            text: Svc.Battery.batteryIcon()
            font.family: Svc.Theme.iconFont
            font.pixelSize: Svc.Theme.iconSize
            color: root.levelColor()

            // Gentle blink when critically low and not charging.
            SequentialAnimation on opacity {
                running: Svc.Battery.low
                loops: Animation.Infinite
                NumberAnimation { to: 0.3; duration: 700 }
                NumberAnimation { to: 1.0; duration: 700 }
            }
        }

        RevealLabel {
            anchors.verticalCenter: parent.verticalCenter
            text: Math.round(Svc.Battery.percent * 100) + "%"
            revealed: Svc.Battery.onBattery || mouse.containsMouse || panel.shown
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: panel.shown = !panel.shown
    }

    BatteryPanel {
        id: panel
        barWindow: root.barWindow
        anchorItem: root
    }
}
