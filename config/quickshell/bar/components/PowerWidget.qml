import QtQuick
import "../../services" as Svc

// Bar button that opens the session / power menu overlay.
Item {
    id: root

    property var barWindow

    readonly property bool active: Svc.Overlays.power && Svc.Overlays.power.visible

    implicitWidth: icon.implicitWidth + 12
    implicitHeight: parent ? parent.height : 32

    Rectangle {
        anchors.fill: parent
        radius: Svc.Theme.radiusMedium
        color: mouse.containsMouse || root.active ? Svc.Theme.hover : "transparent"
    }

    Text {
        id: icon
        anchors.centerIn: parent
        text: String.fromCodePoint(0xF0425) // power
        font.family: Svc.Theme.iconFont
        font.pixelSize: 16
        color: mouse.containsMouse || root.active ? Svc.Theme.danger : Svc.Theme.text
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: if (Svc.Overlays.power) Svc.Overlays.power.toggle()
    }
}
