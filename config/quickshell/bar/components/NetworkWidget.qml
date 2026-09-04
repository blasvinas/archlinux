import QtQuick
import "../../services" as Svc

// Bar indicator: signal icon + SSID. Click to open the management panel.
Item {
    id: root

    // The PanelWindow this widget sits in (needed to anchor the popup).
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
        spacing: 6

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Svc.Network.signalIcon(Svc.Network.activeSignal, Svc.Network.activeSecure)
            font.family: Svc.Theme.iconFont
            font.pixelSize: 16
            color: Svc.Theme.text
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Svc.Network.connected ? Svc.Network.activeSsid : "Off"
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
        onClicked: {
            panel.visible = !panel.visible;
            if (panel.visible)
                Svc.Network.refresh(true);
        }
    }

    NetworkPanel {
        id: panel
        barWindow: root.barWindow
        anchorItem: root
    }
}
