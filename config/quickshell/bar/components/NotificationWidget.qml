import QtQuick
import "../../services" as Svc

// Bar bell: shows unread count, DND state; click opens the notification center.
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
            text: String.fromCodePoint(
                Svc.Notifications.doNotDisturb ? 0xF009C   // bell-off
                : Svc.Notifications.count > 0 ? 0xF009A     // bell
                : 0xF009B)                                  // bell-outline
            font.family: Svc.Theme.iconFont
            font.pixelSize: 16
            color: Svc.Notifications.doNotDisturb ? Svc.Theme.danger
                 : Svc.Notifications.count > 0 ? Svc.Theme.accent : Svc.Theme.text
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: Svc.Notifications.count > 0
            text: Svc.Notifications.count
            color: Svc.Theme.text
            font.pixelSize: 12
            font.family: Svc.Theme.fontFamily
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: (m) => {
            if (m.button === Qt.RightButton)
                Svc.Notifications.toggleDnd();
            else
                panel.visible = !panel.visible;
        }
    }

    NotificationCenter {
        id: panel
        barWindow: root.barWindow
        anchorItem: root
    }
}
