import QtQuick
import "../../services" as Svc

// Bar widget: weather icon + temperature. Click for details/forecast.
Item {
    id: root

    property var barWindow

    visible: Svc.Weather.ready
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
        spacing: 5

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Svc.Weather.currentIcon()
            font.family: Svc.Theme.iconFont
            font.pixelSize: 16
            color: Svc.Theme.text
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Svc.Weather.temp + Svc.Weather.unit
            color: Svc.Theme.text
            font.pixelSize: 13
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

    WeatherPanel {
        id: panel
        barWindow: root.barWindow
        anchorItem: root
    }
}
