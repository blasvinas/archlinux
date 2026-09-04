pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Backlight control via `brightnessctl`. Reads the current value straight from
// sysfs (polled + refreshed after writes) so hardware keys stay in sync.
Singleton {
    id: root

    property string device: ""
    property int max: 1
    property int current: 0
    readonly property bool available: device !== "" && max > 0
    readonly property real percent: max > 0 ? current / max : 0   // 0..1

    // ---- Actions -------------------------------------------------------------
    function setPercent(p) {
        var pct = Math.round(Math.max(1, Math.min(p, 100)));
        setProc.command = ["brightnessctl", "-q", "set", pct + "%"];
        setProc.running = true;
    }

    function step(deltaPercent) {
        setPercent(percent * 100 + deltaPercent);
    }

    function refresh() {
        if (curFile.path !== "")
            curFile.reload();
        current = parseInt(curFile.text());
    }

    function brightnessIcon() {
        var lv = Math.round(Math.max(0, Math.min(percent, 1)) * 6); // 0..6
        return String.fromCodePoint(0xF00DA + lv); // brightness-1 .. brightness-7
    }

    // ---- Discovery -----------------------------------------------------------
    Process {
        id: initProc
        command: ["brightnessctl", "-m"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var f = this.text.trim().split(",");
                if (f.length >= 5) {
                    root.device = f[0];
                    root.current = parseInt(f[2]);
                    root.max = parseInt(f[4]);
                    curFile.path = "/sys/class/backlight/" + root.device + "/brightness";
                }
            }
        }
    }

    Process {
        id: setProc
        stdout: StdioCollector {}
        onExited: (code, status) => root.refresh()
    }

    FileView {
        id: curFile
        blockLoading: true
    }

    // Catch changes made via hardware brightness keys.
    Timer {
        interval: 1000
        running: root.available
        repeat: true
        onTriggered: root.refresh()
    }
}
