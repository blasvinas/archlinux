import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import "../services" as Svc

// Top-right stack of notification toasts, on the focused monitor.
PanelWindow {
    id: win

    screen: {
        var fm = Hyprland.focusedMonitor;
        if (fm) {
            var scr = Quickshell.screens;
            for (var i = 0; i < scr.length; i++)
                if (scr[i].name === fm.name)
                    return scr[i];
        }
        return null;
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-notifications"

    anchors { top: true; right: true }
    exclusiveZone: 0
    color: "transparent"

    implicitWidth: 400
    implicitHeight: Math.max(1, col.implicitHeight + 16)
    visible: Svc.Notifications.popups.length > 0

    Column {
        id: col
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 8
        anchors.rightMargin: 8
        spacing: 8

        Repeater {
            // Newest on top.
            model: Svc.Notifications.popups.slice().reverse()

            delegate: Toast {
                required property var modelData
                notif: modelData
            }
        }
    }
}
