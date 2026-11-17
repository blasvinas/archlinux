pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Audio spectrum source for the dashboard visualizer.
//
// When the `cava` binary is available it is spawned in raw-ascii mode and its
// frames are parsed into `values` (each 0..1). When cava is missing a synthetic
// animation is produced instead so the visualizer still looks alive; install
// `cava` for a real spectrum.
Singleton {
    id: root

    property int bars: 22
    property bool active: false          // driven by the dashboard
    property bool available: false       // cava binary present
    property var values: []              // length == bars, each 0..1

    readonly property string configPath: Quickshell.statePath("cava.conf")

    function _zeros() {
        var z = [];
        for (var i = 0; i < bars; i++) z.push(0);
        return z;
    }

    Component.onCompleted: {
        values = _zeros();
        _writeConfig();
        detector.running = true;
    }

    function _writeConfig() {
        cfg.setText(
            "[general]\n" +
            "bars = " + bars + "\n" +
            "framerate = 60\n" +
            "[input]\n" +
            "method = pipewire\n" +
            "source = auto\n" +
            "[output]\n" +
            "method = raw\n" +
            "raw_target = /dev/stdout\n" +
            "data_format = ascii\n" +
            "ascii_max_range = 1000\n" +
            "channels = mono\n"
        );
    }

    FileView { id: cfg; path: root.configPath }

    Process {
        id: detector
        command: ["sh", "-c", "command -v cava"]
        stdout: StdioCollector {
            onStreamFinished: root.available = this.text.trim().length > 0
        }
    }

    // ---- Real spectrum (cava) -----------------------------------------------
    Process {
        id: proc
        running: root.active && root.available
        command: ["cava", "-p", root.configPath]
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                var parts = data.split(";");
                var out = [];
                for (var i = 0; i < parts.length; i++) {
                    if (parts[i].length === 0) continue;
                    out.push(Math.max(0, Math.min(1, parseInt(parts[i]) / 1000)));
                }
                if (out.length > 0)
                    root.values = out;
            }
        }
    }

    onActiveChanged: if (!active) values = _zeros();

    // ---- Synthetic fallback --------------------------------------------------
    // A gentle bass-weighted shimmer used when cava is unavailable.
    Timer {
        interval: 55
        running: root.active && !root.available
        repeat: true
        property real phase: 0
        onTriggered: {
            phase += 0.18;
            var out = [];
            for (var i = 0; i < root.bars; i++) {
                var t = i / root.bars;
                var bassWeight = 1 - t * 0.6;
                var wave = 0.5 + 0.5 * Math.sin(phase + i * 0.5);
                var jitter = 0.75 + 0.25 * Math.random();
                out.push(Math.max(0.04, bassWeight * wave * jitter * 0.9));
            }
            root.values = out;
        }
    }
}
