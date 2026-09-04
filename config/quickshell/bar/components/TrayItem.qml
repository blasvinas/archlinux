import Quickshell
import QtQuick
import "../../services" as Svc

// A single system-tray (StatusNotifierItem) entry with its context menu.
Item {
    id: root

    required property var item      // StatusNotifierItem
    property var barWindow

    implicitWidth: 24
    implicitHeight: parent ? parent.height : 32

    Rectangle {
        anchors.fill: parent
        radius: Svc.Theme.radiusSmall
        color: hover.hovered || menu.visible ? Svc.Theme.hover : "transparent"
    }

    Image {
        id: img
        anchors.centerIn: parent
        width: 18
        height: 18
        source: root.item.icon
        sourceSize.width: 36
        sourceSize.height: 36
        smooth: true
        asynchronous: true
        fillMode: Image.PreserveAspectFit
        visible: status === Image.Ready
    }

    // Fallback: first letter of the title if the icon fails to load.
    Text {
        anchors.centerIn: parent
        visible: img.status !== Image.Ready
        text: (root.item.title || "?").slice(0, 1).toUpperCase()
        color: Svc.Theme.text
        font.pixelSize: 13
        font.bold: true
    }

    HoverHandler { id: hover }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor
        onClicked: (m) => {
            if (m.button === Qt.RightButton) {
                if (root.item.hasMenu)
                    menu.visible = true;
            } else if (m.button === Qt.MiddleButton) {
                root.item.secondaryActivate();
            } else {
                // Left click: activate, or open menu for menu-only items.
                if (root.item.onlyMenu) {
                    if (root.item.hasMenu)
                        menu.visible = true;
                } else {
                    root.item.activate();
                }
            }
        }
        onWheel: (w) => root.item.scroll(w.angleDelta.y, false)
    }

    // Native-rendered DBus menu, anchored under this icon.
    QsMenuAnchor {
        id: menu
        menu: root.item.menu
        anchor.window: root.barWindow
        anchor.rect.x: {
            if (!root.barWindow)
                return 0;
            var p = root.mapToItem(root.barWindow.contentItem, 0, 0);
            return Math.round(p.x + root.width / 2);
        }
        anchor.rect.y: root.barWindow ? root.barWindow.height : 32
    }
}
