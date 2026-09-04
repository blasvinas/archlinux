import QtQuick
import "../../services" as Svc

// Bar button that opens the clipboard history.
Item {
    id: root

    implicitWidth: icon.implicitWidth + 12
    implicitHeight: parent ? parent.height : 32

    Rectangle {
        anchors.fill: parent
        radius: Svc.Theme.radiusMedium
        color: mouse.containsMouse ? Svc.Theme.hover : "transparent"
    }

    Text {
        id: icon
        anchors.centerIn: parent
        text: String.fromCodePoint(0xF0159) // clipboard-text
        font.family: Svc.Theme.iconFont
        font.pixelSize: 16
        color: mouse.containsMouse ? Svc.Theme.accent : Svc.Theme.text
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: if (Svc.Overlays.clipboard) Svc.Overlays.clipboard.toggle()
    }
}
