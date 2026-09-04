pragma Singleton

import Quickshell
import Quickshell.Services.Notifications
import QtQuick

// Notification server + history. Makes Quickshell the org.freedesktop.Notifications
// daemon and keeps a tracked history plus a transient "popups" list for toasts.
Singleton {
    id: root

    property bool doNotDisturb: false

    // Transient toast list (references to Notification objects still on screen).
    property var popups: []

    // History, newest first.
    readonly property var list: {
        var v = server.trackedNotifications.values;
        var out = v.slice();
        out.reverse();
        return out;
    }
    readonly property int count: server.trackedNotifications.values.length

    // ---- Actions -------------------------------------------------------------
    function dismiss(n) {
        if (n) n.dismiss();
    }
    function dismissAll() {
        var v = server.trackedNotifications.values.slice();
        for (var i = 0; i < v.length; i++)
            v[i].dismiss();
    }
    function removePopup(n) {
        var p = root.popups.slice();
        var idx = p.indexOf(n);
        if (idx >= 0) {
            p.splice(idx, 1);
            root.popups = p;
        }
    }
    function toggleDnd() {
        doNotDisturb = !doNotDisturb;
        if (doNotDisturb)
            root.popups = [];
    }

    function urgencyColor(u) {
        if (u === NotificationUrgency.Critical) return "#f38ba8";
        if (u === NotificationUrgency.Low) return "#585b70";
        return "#89b4fa";
    }

    NotificationServer {
        id: server

        keepOnReload: false
        actionsSupported: true
        actionIconsSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        imageSupported: true
        inlineReplySupported: false

        onNotification: (n) => {
            n.tracked = true;                 // keep in history
            if (!root.doNotDisturb) {
                var p = root.popups.slice();
                p.push(n);
                root.popups = p;
            }
        }
    }
}
