import QtQuick
import "../../services" as Svc

// Rounded surface used as the common container for dashboard panes.
Rectangle {
    id: root
    property string title: ""
    default property alias content: inner.data

    radius: Svc.Theme.radiusCard
    color: Svc.Theme.base
    border.color: Svc.Theme.border
    border.width: 1

    Text {
        id: heading
        visible: root.title.length > 0
        text: root.title
        font.family: Svc.Theme.fontFamily
        font.pixelSize: 12
        font.bold: true
        color: Svc.Theme.subtext
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: 14
    }

    Item {
        id: inner
        anchors.fill: parent
        anchors.margins: 14
        anchors.topMargin: root.title.length > 0 ? 34 : 14
    }
}
