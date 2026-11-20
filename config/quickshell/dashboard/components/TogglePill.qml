import QtQuick
import "../../services" as Svc

// Quick toggle: a label on the left and a sliding on/off switch on the right.
Rectangle {
    id: root

    property string label: ""
    property bool on: false
    property bool available: true
    signal toggled()

    implicitWidth: labelText.implicitWidth + 10 + 10 + toggle.width + 10
    implicitHeight: 40
    radius: Svc.Theme.radiusMedium

    color: ma.containsMouse ? Svc.Theme.surface1 : Svc.Theme.surface0
    Behavior on color { ColorAnimation { duration: 140; easing.type: Easing.OutQuad } }
    opacity: available ? 1 : 0.4

    Text {
        id: labelText
        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        text: root.label
        font.family: Svc.Theme.fontFamily
        font.pixelSize: Svc.Theme.fontSm
        font.bold: root.on
        color: root.on ? Svc.Theme.text : Svc.Theme.subtext
    }

    // On/off switch
    Rectangle {
        id: toggle
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        width: 34
        height: 20
        radius: height / 2
        color: root.on ? Svc.Theme.accent : Svc.Theme.surface2
        Behavior on color { ColorAnimation { duration: 160; easing.type: Easing.OutQuad } }

        Rectangle {
            id: knob
            width: 16
            height: 16
            radius: height / 2
            y: 2
            x: root.on ? toggle.width - width - 2 : 2
            color: root.on ? Svc.Theme.accentFg : Svc.Theme.text
            Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutQuad } }
            Behavior on color { ColorAnimation { duration: 160 } }
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.available
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }
}
