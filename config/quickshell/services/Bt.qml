pragma Singleton

import Quickshell
import Quickshell.Bluetooth
import QtQml
import QtQuick

// Thin convenience wrapper around the native Quickshell.Bluetooth singleton.
// Adds icon helpers and a reactive count/list of connected devices.
Singleton {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool available: adapter !== null
    readonly property bool enabled: adapter ? adapter.enabled : false
    readonly property bool discovering: adapter ? adapter.discovering : false
    readonly property var devices: Bluetooth.devices

    // Kept in sync by the Instantiator below (reactive to per-device changes).
    property int connectedCount: 0
    property var connectedDevices: []
    property var sortedDevices: []

    function setEnabled(on) {
        if (adapter)
            adapter.enabled = on;
    }

    function setDiscovering(on) {
        if (adapter)
            adapter.discovering = on;
    }

    // Toggle connection on a device object.
    function toggleConnection(dev) {
        if (!dev)
            return;
        if (dev.connected)
            dev.disconnect();
        else
            dev.connect();
    }

    function recount() {
        var d = Bluetooth.devices ? Bluetooth.devices.values : [];
        var list = [];
        for (var i = 0; i < d.length; i++)
            if (d[i].connected)
                list.push(d[i]);
        root.connectedDevices = list;
        root.connectedCount = list.length;

        var all = d.slice();
        all.sort(function(a, b) {
            if (a.connected !== b.connected) return a.connected ? -1 : 1;
            if (a.paired !== b.paired) return a.paired ? -1 : 1;
            return (a.name || "").localeCompare(b.name || "");
        });
        root.sortedDevices = all;
    }

    // Bar / status icon.
    function statusIcon() {
        if (!available || !enabled)
            return String.fromCodePoint(0xF00B2); // bluetooth-off
        if (connectedCount > 0)
            return String.fromCodePoint(0xF00B1); // bluetooth-connect
        return String.fromCodePoint(0xF00AF);      // bluetooth
    }

    // Per-device glyph based on the BlueZ icon name.
    function deviceIcon(icon) {
        var s = icon || "";
        if (s.indexOf("headset") >= 0 || s.indexOf("headphone") >= 0 || s.indexOf("audio") >= 0)
            return String.fromCodePoint(0xF02CB); // headphones
        if (s.indexOf("mouse") >= 0)
            return String.fromCodePoint(0xF037D); // mouse
        if (s.indexOf("keyboard") >= 0)
            return String.fromCodePoint(0xF030C); // keyboard
        if (s.indexOf("phone") >= 0)
            return String.fromCodePoint(0xF011C); // cellphone
        if (s.indexOf("speaker") >= 0 || s.indexOf("card") >= 0)
            return String.fromCodePoint(0xF04C3); // speaker
        return String.fromCodePoint(0xF00AF);      // generic bluetooth
    }

    // Watches every device so connectedCount stays reactive.
    Instantiator {
        model: Bluetooth.devices
        delegate: QtObject {
            required property var modelData
            readonly property bool conn: modelData.connected
            onConnChanged: root.recount()
            Component.onCompleted: root.recount()
            Component.onDestruction: Qt.callLater(root.recount)
        }
    }
}
