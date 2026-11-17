import QtQuick
import "../../services" as Svc

// Caelestia-style realtime performance page: history graphs for CPU, memory,
// GPU (or temperature) and network, plus a per-core strip and detail footer.
Item {
    id: root

    readonly property int gap: 12
    readonly property real cellW: (width - gap) / 2

    function loadColor(p) {
        if (p >= 90) return Svc.Theme.danger;
        if (p >= 70) return Svc.Theme.warning;
        return Svc.Theme.accent;
    }
    function tempColor(t) {
        if (t >= 85) return Svc.Theme.danger;
        if (t >= 70) return Svc.Theme.warning;
        return Svc.Theme.success;
    }

    readonly property int graphH: 160

    // ---- Top row: CPU + Memory ------------------------------------------------
    MetricGraph {
        id: cpuCard
        x: 0
        y: 0
        width: root.cellW
        height: root.graphH
        glyph: String.fromCodePoint(0xF0EE0)
        metricTitle: "CPU"
        caption: "load " + Svc.SysInfo.load[0] + " · " + Svc.SysInfo.load[1] + " · " + Svc.SysInfo.load[2]
        valueText: Math.round(Svc.SysInfo.cpu) + "%"
        values: Svc.SysInfo.cpuHistory
        maxValue: 100
        accent: root.loadColor(Svc.SysInfo.cpu)
    }
    MetricGraph {
        id: memCard
        x: root.cellW + root.gap
        y: 0
        width: root.cellW
        height: root.graphH
        glyph: String.fromCodePoint(0xF035B)
        metricTitle: "Memory"
        caption: Svc.SysInfo.fmtBytes(Svc.SysInfo.memUsed) + " / " + Svc.SysInfo.fmtBytes(Svc.SysInfo.memTotal)
        valueText: Math.round(Svc.SysInfo.memPercent) + "%"
        values: Svc.SysInfo.memHistory
        maxValue: 100
        accent: root.loadColor(Svc.SysInfo.memPercent)
    }

    // ---- Middle row: GPU (or temperature) + network --------------------------
    MetricGraph {
        id: gpuCard
        visible: Svc.SysInfo.hasGpu
        x: 0
        y: cpuCard.height + root.gap
        width: root.cellW
        height: root.graphH
        glyph: String.fromCodePoint(0xF1FD9) // expansion-card-variant
        metricTitle: "GPU"
        caption: Svc.SysInfo.gpuMemTotal > 0
            ? Svc.SysInfo.fmtBytes(Svc.SysInfo.gpuMem) + " / " + Svc.SysInfo.fmtBytes(Svc.SysInfo.gpuMemTotal)
            : (Svc.SysInfo.gpuTemp > 0 ? Math.round(Svc.SysInfo.gpuTemp) + "°C" : "")
        valueText: Math.round(Svc.SysInfo.gpu) + "%"
        values: Svc.SysInfo.gpuHistory
        maxValue: 100
        accent: root.loadColor(Svc.SysInfo.gpu)
    }
    MetricGraph {
        // Fallback when no GPU: show the CPU temperature graph here.
        visible: !Svc.SysInfo.hasGpu
        x: 0
        y: cpuCard.height + root.gap
        width: root.cellW
        height: root.graphH
        glyph: String.fromCodePoint(0xF050F) // thermometer
        metricTitle: "Temperature"
        valueText: Math.round(Svc.SysInfo.temp) + "°C"
        values: Svc.SysInfo.tempHistory
        maxValue: 100
        accent: root.tempColor(Svc.SysInfo.temp)
    }
    MetricGraph {
        id: netCard
        x: root.cellW + root.gap
        y: cpuCard.height + root.gap
        width: root.cellW
        height: root.graphH
        glyph: String.fromCodePoint(0xF059F) // download-network
        metricTitle: "Network"
        caption: "↑ " + Svc.SysInfo.fmtRate(Svc.SysInfo.netTx)
        valueText: "↓ " + Svc.SysInfo.fmtRate(Svc.SysInfo.netRx)
        values: Svc.SysInfo.netRxHistory
        maxValue: 0 // auto-scale
        accent: Svc.Theme.success
    }

    // ---- Footer: top processes -----------------------------------------------
    ProcessList {
        x: 0
        y: (root.graphH + root.gap) * 2
        width: root.width
        height: root.height - (root.graphH + root.gap) * 2
    }
}
