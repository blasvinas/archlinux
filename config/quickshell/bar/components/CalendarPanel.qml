import Quickshell
import Quickshell.Hyprland
import QtQuick
import "../../services" as Svc

// Dropdown hosting the month calendar, anchored under the clock.
PopupWindow {
    id: pop

    property var barWindow
    property Item anchorItem

    anchor.window: barWindow
    anchor.rect.x: {
        if (!anchorItem || !barWindow)
            return 0;
        var p = anchorItem.mapToItem(barWindow.contentItem, 0, 0);
        // Centre the popup under the clock, clamped to the screen.
        var x = Math.round(p.x + anchorItem.width / 2 - width / 2);
        var maxX = barWindow.width - width - 6;
        return Math.max(6, Math.min(x, maxX));
    }
    anchor.rect.y: Svc.Theme.popupTop

    implicitWidth: 300
    implicitHeight: content.implicitHeight
    // `shown` drives the open state; the window stays mapped until the
    // fade-out finishes so closing animates too.
    property bool shown: false
    visible: shown || content.opacity > 0
    color: "transparent"

    // Jump back to the current month each time it opens.
    onVisibleChanged: if (visible) cal.resetToToday()

    HyprlandFocusGrab {
        windows: [pop]
        active: pop.shown
        onCleared: pop.shown = false
    }

    Rectangle {
        id: content
        anchors.fill: parent
        implicitHeight: cal.implicitHeight + 24
        radius: Svc.Theme.radiusLarge
        color: Svc.Theme.popupBg
        opacity: pop.shown ? 1 : 0
        transform: Translate { y: pop.shown ? 0 : -8; Behavior on y { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } } }
        Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutQuad } }
        border.color: Svc.Theme.border
        border.width: 1

        Calendar {
            id: cal
            anchors.fill: parent
            anchors.margins: 12
        }
    }
}
