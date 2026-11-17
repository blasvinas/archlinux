import QtQuick
import "../../services" as Svc

// System resource pane: four rings (CPU / RAM / disk / temp) plus an uptime
// and load-average footer.
Card {
    id: root
    title: "System"

    function tempColor(t) {
        if (t >= 85) return Svc.Theme.danger;
        if (t >= 70) return Svc.Theme.warning;
        return Svc.Theme.success;
    }
    function loadColor(p) {
        if (p >= 90) return Svc.Theme.danger;
        if (p >= 70) return Svc.Theme.warning;
        return Svc.Theme.accent;
    }

    Column {
        anchors.fill: parent
        spacing: 12

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 8

            StatRing {
                value: Svc.SysInfo.cpu / 100
                glyph: String.fromCodePoint(0xF0EE0) // cpu
                label: "CPU"
                valueText: Math.round(Svc.SysInfo.cpu) + "%"
                ringColor: root.loadColor(Svc.SysInfo.cpu)
            }
            StatRing {
                value: Svc.SysInfo.memPercent / 100
                glyph: String.fromCodePoint(0xF035B) // memory
                label: "RAM"
                valueText: Math.round(Svc.SysInfo.memPercent) + "%"
                ringColor: root.loadColor(Svc.SysInfo.memPercent)
            }
            StatRing {
                value: Svc.SysInfo.diskPercent / 100
                glyph: String.fromCodePoint(0xF02CA) // harddisk
                label: "Disk"
                valueText: Math.round(Svc.SysInfo.diskPercent) + "%"
                ringColor: root.loadColor(Svc.SysInfo.diskPercent)
            }
            StatRing {
                value: Math.min(1, Svc.SysInfo.temp / 100)
                glyph: String.fromCodePoint(0xF050F) // thermometer
                label: "Temp"
                valueText: Math.round(Svc.SysInfo.temp) + "°"
                ringColor: root.tempColor(Svc.SysInfo.temp)
            }
        }

        // Per-core utilisation strip.
        CoreBars {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: Svc.SysInfo.cpuCores.length > 0
        }

        // Footer: memory detail + uptime + load averages.
        Column {
            width: parent.width
            spacing: 4

            Row {
                width: parent.width
                Text {
                    text: String.fromCodePoint(0xF035B) + "  "
                        + Svc.SysInfo.fmtBytes(Svc.SysInfo.memUsed) + " / "
                        + Svc.SysInfo.fmtBytes(Svc.SysInfo.memTotal)
                    font.family: Svc.Theme.fontFamily
                    font.pixelSize: 11
                    color: Svc.Theme.subtext
                }
                Item { width: parent.width - 320; height: 1 }
                Text {
                    text: String.fromCodePoint(0xF0510) + "  up " + Svc.SysInfo.fmtUptime(Svc.SysInfo.uptime)
                    font.family: Svc.Theme.fontFamily
                    font.pixelSize: 11
                    color: Svc.Theme.subtext
                }
            }

            Text {
                text: "load  " + Svc.SysInfo.load[0] + "  " + Svc.SysInfo.load[1] + "  " + Svc.SysInfo.load[2]
                font.family: Svc.Theme.fontFamily
                font.pixelSize: 11
                color: Svc.Theme.subtext
            }
        }
    }
}
