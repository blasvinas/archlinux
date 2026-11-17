pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// System stats (CPU / memory / swap / disk / temperature / uptime), refreshed
// on a timer while the dashboard is open. Data is produced by a small Python
// helper that samples /proc; see scripts/sysinfo.py.
Singleton {
    id: root

    // Polling is enabled only while something is observing (the dashboard).
    property bool active: false
    // When the performance tab is open we sample faster for smoother graphs.
    property bool fast: false
    property int intervalMs: fast ? 1500 : 3000

    property bool ready: false
    property real cpu: 0            // 0..100
    property var cpuCores: []
    property real memUsed: 0        // bytes
    property real memTotal: 0
    property real memPercent: 0
    property real swapUsed: 0
    property real swapTotal: 0
    property real swapPercent: 0
    property real diskUsed: 0
    property real diskTotal: 0
    property real diskPercent: 0
    property real temp: 0           // °C
    property int uptime: 0          // seconds
    property var load: [0, 0, 0]
    property string host: ""
    property string user: ""

    // GPU (best-effort; zeros when no GPU is detected).
    property real gpu: 0            // 0..100
    property real gpuTemp: 0        // °C
    property real gpuMem: 0         // bytes
    property real gpuMemTotal: 0    // bytes
    property string gpuName: ""
    readonly property bool hasGpu: gpuMemTotal > 0 || gpu > 0 || gpuName.length > 0

    // Network throughput, computed by diffing cumulative counters.
    property real netRx: 0          // bytes/s down
    property real netTx: 0          // bytes/s up
    property real _lastRx: -1
    property real _lastTx: -1
    property real _lastT: -1

    // Top processes by CPU and by memory (each an array of {pid,name,cpu,mem}).
    property var procsByCpu: []
    property var procsByMem: []

    // Rolling history buffers for the performance graphs (newest at the end).
    property int historyLen: 60
    property var cpuHistory: []
    property var memHistory: []
    property var gpuHistory: []
    property var tempHistory: []
    property var netRxHistory: []
    property var netTxHistory: []

    function _push(arr, v) {
        var a = arr.slice();
        a.push(v);
        while (a.length > historyLen)
            a.shift();
        return a;
    }

    readonly property string scriptPath:
        Quickshell.env("HOME") + "/.config/quickshell/scripts/sysinfo.py"

    function refresh() { if (!proc.running) proc.running = true; }

    // Human-readable byte sizes (GiB with one decimal, or MiB below 1 GiB).
    function fmtBytes(b) {
        var gib = b / (1024 * 1024 * 1024);
        if (gib >= 1)
            return gib.toFixed(1) + " GiB";
        return Math.round(b / (1024 * 1024)) + " MiB";
    }

    // Human-readable transfer rate (per second).
    function fmtRate(b) {
        if (b >= 1024 * 1024)
            return (b / (1024 * 1024)).toFixed(1) + " MB/s";
        if (b >= 1024)
            return (b / 1024).toFixed(0) + " KB/s";
        return Math.round(b) + " B/s";
    }

    function fmtUptime(s) {
        var d = Math.floor(s / 86400);
        var h = Math.floor((s % 86400) / 3600);
        var m = Math.floor((s % 3600) / 60);
        var out = [];
        if (d > 0) out.push(d + "d");
        if (h > 0) out.push(h + "h");
        out.push(m + "m");
        return out.join(" ");
    }

    Process {
        id: proc
        command: ["python3", root.scriptPath]
        stdout: StdioCollector {
            onStreamFinished: {
                var out = this.text.trim();
                if (out.length === 0)
                    return;
                try {
                    var d = JSON.parse(out);
                    root.cpu = d.cpu;
                    root.cpuCores = d.cpuCores || [];
                    root.memUsed = d.mem.used; root.memTotal = d.mem.total; root.memPercent = d.mem.percent;
                    root.swapUsed = d.swap.used; root.swapTotal = d.swap.total; root.swapPercent = d.swap.percent;
                    root.diskUsed = d.disk.used; root.diskTotal = d.disk.total; root.diskPercent = d.disk.percent;
                    root.temp = d.temp;
                    root.uptime = d.uptime;
                    root.load = d.load || [0, 0, 0];
                    root.host = d.host || "";
                    root.user = d.user || "";

                    if (d.gpu) {
                        root.gpu = d.gpu.usage || 0;
                        root.gpuTemp = d.gpu.temp || 0;
                        root.gpuMem = d.gpu.mem || 0;
                        root.gpuMemTotal = d.gpu.memTotal || 0;
                        root.gpuName = d.gpu.name || "";
                    }

                    // Compute network rates from cumulative counters.
                    if (d.net) {
                        if (root._lastT > 0 && d.net.t > root._lastT) {
                            var dt = d.net.t - root._lastT;
                            root.netRx = Math.max(0, (d.net.rx - root._lastRx) / dt);
                            root.netTx = Math.max(0, (d.net.tx - root._lastTx) / dt);
                        }
                        root._lastRx = d.net.rx;
                        root._lastTx = d.net.tx;
                        root._lastT = d.net.t;
                    }

                    if (d.procs) {
                        root.procsByCpu = d.procs.byCpu || [];
                        root.procsByMem = d.procs.byMem || [];
                    }

                    // Append to history buffers.
                    root.cpuHistory = root._push(root.cpuHistory, root.cpu);
                    root.memHistory = root._push(root.memHistory, root.memPercent);
                    root.gpuHistory = root._push(root.gpuHistory, root.gpu);
                    root.tempHistory = root._push(root.tempHistory, root.temp);
                    root.netRxHistory = root._push(root.netRxHistory, root.netRx);
                    root.netTxHistory = root._push(root.netTxHistory, root.netTx);

                    root.ready = true;
                } catch (e) {
                    console.warn("SysInfo: parse error:", e);
                }
            }
        }
    }

    Timer {
        interval: root.intervalMs
        running: root.active
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
