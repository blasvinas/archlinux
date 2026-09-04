import QtQuick
import "../../services" as Svc

// Bar indicator: bluetooth status icon (+ connected count). Click opens the panel.
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
            text: Svc.Bt.statusIcon()
            font.family: Svc.Theme.iconFont
            font.pixelSize: 16
            color: Svc.Bt.connectedCount > 0 ? Svc.Theme.accent : Svc.Theme.text
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: Svc.Bt.connectedCount > 0
            text: Svc.Bt.connectedCount
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
        onClicked: {
            panel.visible = !panel.visible;
            if (panel.visible && Svc.Bt.enabled)
                Svc.Bt.setDiscovering(true);
            else if (!panel.visible)
                Svc.Bt.setDiscovering(false);
        }
    }

    BluetoothPanel {
        id: panel
        barWindow: root.barWindow
        anchorItem: root
        onVisibleChanged: if (!visible) Svc.Bt.setDiscovering(false)
    }
}
