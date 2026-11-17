pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Blue-light / colour-temperature toggle. Detects an available backend at
// startup (hyprsunset, wlsunset or gammastep) and drives it on/off. When no
// backend is installed `available` stays false and the UI shows it disabled.
Singleton {
    id: root

    property bool available: false
    property string backend: ""          // "hyprsunset" | "wlsunset" | "gammastep"
    property bool enabled: false
    property int temperature: 4000       // Kelvin when enabled

    function toggle() { setEnabled(!enabled); }

    function setEnabled(on) {
        if (!available)
            return;
        enabled = on;
        store.setText(on ? "1" : "0");
        _apply();
    }

    function _apply() {
        if (backend === "hyprsunset" || backend === "wlsunset") {
            // Daemon style: running == night mode on.
            daemon.running = enabled;
        } else if (backend === "gammastep") {
            // One-shot: apply a fixed temperature, or reset.
            oneshot.command = enabled
                ? ["gammastep", "-P", "-O", String(temperature)]
                : ["gammastep", "-x"];
            oneshot.running = true;
        }
    }

    // ---- Backend detection ---------------------------------------------------
    Process {
        id: detector
        running: true
        command: ["sh", "-c",
            "for b in hyprsunset wlsunset gammastep; do command -v $b && break; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                var path = this.text.trim();
                if (path.length === 0)
                    return;
                var name = path.split("/").pop();
                root.backend = name;
                root.available = true;
                if (root.enabled)
                    root._apply();
            }
        }
    }

    // ---- Processes -----------------------------------------------------------
    Process {
        id: daemon
        command: root.backend === "hyprsunset"
            ? ["hyprsunset", "-t", String(root.temperature)]
            : ["wlsunset", "-T", String(root.temperature + 1), "-t", String(root.temperature)]
    }

    Process { id: oneshot }

    // ---- Persistence ---------------------------------------------------------
    FileView {
        id: store
        path: Quickshell.statePath("nightlight")
        onLoaded: root.enabled = text().trim() === "1"
    }
}
