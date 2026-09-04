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
        return Svc.Theme.text;
    }

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
            text: Svc.Battery.batteryIcon()
            font.family: Svc.Theme.iconFont
            font.pixelSize: 16
            color: root.levelColor()

            // Gentle blink when critically low and not charging.
            SequentialAnimation on opacity {
                running: Svc.Battery.low
                loops: Animation.Infinite
                NumberAnimation { to: 0.3; duration: 700 }
                NumberAnimation { to: 1.0; duration: 700 }
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Math.round(Svc.Battery.percent * 100) + "%"
            color: Svc.Theme.text
            font.pixelSize: 12
            font.family: Svc.Theme.fontFamily
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: panel.visible = !panel.visible
    }

    BatteryPanel {
        id: panel
        barWindow: root.barWindow
        anchorItem: root
    }
}
