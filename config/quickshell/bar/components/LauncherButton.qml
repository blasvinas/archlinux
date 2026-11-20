import QtQuick
import "../../services" as Svc

// Bar button that opens the application launcher.
Item {
    id: root

    implicitWidth: icon.implicitWidth + 12
    implicitHeight: parent ? parent.height : 32

    Rectangle {
        anchors.fill: parent
        radius: Svc.Theme.radiusMedium
        color: mouse.containsMouse ? Svc.Theme.hover : "transparent"
        Behavior on color { ColorAnimation { duration: 120; easing.type: Easing.OutQuad } }
    }

    Text {
        id: icon
        anchors.centerIn: parent
        text: String.fromCodePoint(0xF003B) // apps grid
        font.family: Svc.Theme.iconFont
        font.pixelSize: Svc.Theme.iconSize
        color: mouse.containsMouse ? Svc.Theme.text : Svc.Theme.icon
        Behavior on color { ColorAnimation { duration: 120; easing.type: Easing.OutQuad } }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: if (Svc.Overlays.launcher) Svc.Overlays.launcher.toggle()
    }
}
