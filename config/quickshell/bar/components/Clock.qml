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
        color: mouse.containsMouse || panel.shown ? Svc.Theme.hover : "transparent"
        Behavior on color { ColorAnimation { duration: 120; easing.type: Easing.OutQuad } }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 8

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: String.fromCodePoint(0xF00ED) // calendar
            font.family: Svc.Theme.iconFont
            font.pixelSize: Svc.Theme.iconSize
            color: mouse.containsMouse || panel.shown ? Svc.Theme.text : Svc.Theme.icon
            Behavior on color { ColorAnimation { duration: 120; easing.type: Easing.OutQuad } }
        }

        // Date (secondary)
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Qt.formatDateTime(clock.date, "ddd d MMM")
            color: Svc.Theme.subtext
            font.pixelSize: Svc.Theme.fontMd
            font.family: Svc.Theme.fontFamily
        }

        // Small dot separator
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 3; height: 3
            radius: Svc.Theme.radiusPill
            color: Svc.Theme.muted
        }

        // Time (focal point)
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Qt.formatDateTime(clock.date, "h:mm AP")
            color: Svc.Theme.text
            font.pixelSize: Svc.Theme.fontLg
            font.weight: Font.DemiBold
            font.family: Svc.Theme.fontFamily
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: panel.shown = !panel.shown
    }

    CalendarPanel {
        id: panel
        barWindow: root.barWindow
        anchorItem: root
    }
}
