import Quickshell
import Quickshell.Hyprland
import QtQuick
import "../../services" as Svc

// Small dropdown with a brightness slider.
PopupWindow {
    id: pop

    property var barWindow
    property Item anchorItem

    anchor.window: barWindow
    anchor.rect.x: {
        if (!anchorItem || !barWindow)
            return 0;
        var p = anchorItem.mapToItem(barWindow.contentItem, 0, 0);
        return Math.round(p.x + anchorItem.width - width);
    }
    anchor.rect.y: barWindow ? barWindow.height : 32

    implicitWidth: 280
    implicitHeight: content.implicitHeight
    visible: false
    color: "transparent"

    HyprlandFocusGrab {
        windows: [pop]
        active: pop.visible
        onCleared: pop.visible = false
    }

    Rectangle {
        id: content
        anchors.fill: parent
        implicitHeight: layout.implicitHeight
        radius: Svc.Theme.radiusLarge
        color: Svc.Theme.popupBg
        border.color: Svc.Theme.border
        border.width: 1

        Column {
            id: layout
            width: parent.width
            padding: 12
            spacing: 10

            Text {
                text: "Brightness"
                color: Svc.Theme.subtext
                font.pixelSize: 11
                font.bold: true
            }

            Row {
                width: parent.width - 24
                spacing: 10

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 24
                    text: Svc.Brightness.brightnessIcon()
                    font.family: Svc.Theme.iconFont
                    font.pixelSize: 20
                    color: Svc.Theme.text
                }

                Slider {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 24 - 44 - 20
                    value: Svc.Brightness.percent
                    fillColor: Svc.Theme.warning
                    onMoved: (v) => Svc.Brightness.setPercent(v * 100)
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 40
                    horizontalAlignment: Text.AlignRight
                    text: Math.round(Svc.Brightness.percent * 100) + "%"
                    color: Svc.Theme.text
                    font.pixelSize: 12
                    font.family: Svc.Theme.fontFamily
                }
            }
        }
    }
}
