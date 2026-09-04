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
        color: mouse.containsMouse || panel.visible ? Svc.Theme.hover : "transparent"
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 4

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Svc.Brightness.brightnessIcon()
            font.family: Svc.Theme.iconFont
            font.pixelSize: 16
            color: Svc.Theme.text
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Math.round(Svc.Brightness.percent * 100) + "%"
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
        onWheel: (w) => Svc.Brightness.step(w.angleDelta.y > 0 ? 5 : -5)
    }

    BrightnessPanel {
        id: panel
        barWindow: root.barWindow
        anchorItem: root
    }
}
