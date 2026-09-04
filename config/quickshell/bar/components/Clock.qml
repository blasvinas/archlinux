import Quickshell
import QtQuick
import "../../services" as Svc

// Center widget: calendar icon + date/time. Click to toggle the calendar popup.
Item {
    id: root

    property var barWindow

    implicitWidth: row.implicitWidth + 12
    implicitHeight: parent ? parent.height : 32

    // SystemClock ticks at the requested precision without a manual Timer.
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Rectangle {
        anchors.fill: parent
        radius: Svc.Theme.radiusMedium
        color: mouse.containsMouse || panel.visible ? Svc.Theme.hover : "transparent"
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 8

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: String.fromCodePoint(0xF00ED) // calendar
            font.family: Svc.Theme.iconFont
            font.pixelSize: 15
            color: mouse.containsMouse || panel.visible ? Svc.Theme.accent : Svc.Theme.text
        }

        // Date
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Qt.formatDateTime(clock.date, "ddd d MMM")
            color: Svc.Theme.text
            font.pixelSize: 14
            font.family: Svc.Theme.fontFamily
        }

        // Clock icon separating date and time
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: String.fromCodePoint(0xF0150) // clock-outline
            font.family: Svc.Theme.iconFont
            font.pixelSize: 14
            color: Svc.Theme.subtext
        }

        // Time
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Qt.formatDateTime(clock.date, "h:mm AP")
            color: Svc.Theme.text
            font.pixelSize: 14
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

    CalendarPanel {
        id: panel
        barWindow: root.barWindow
        anchorItem: root
    }
}
