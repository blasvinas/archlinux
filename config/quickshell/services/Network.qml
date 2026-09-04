pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// NetworkManager frontend built on top of `nmcli`.
// Exposes reactive state + imperative actions for the UI.
Singleton {
    id: root

    // ---- State ---------------------------------------------------------------
    property bool wifiEnabled: true
    property bool connected: false
    property string activeSsid: ""
    property int activeSignal: 0
    property bool activeSecure: false

    // List of { ssid, signal, security, secure, active } sorted by signal.
    property var networks: []

    property bool scanning: false
    property bool busy: false          // a connect/disconnect is in flight
    property string lastError: ""

    signal connectFinished(bool success, string message)

    // ---- Public API ----------------------------------------------------------
    function refresh(rescan) {
        radioProc.running = true;
        if (listProc.running)
            return;
        scanning = rescan === true;
        listProc.command = [
            "nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL,SECURITY",
            "dev", "wifi", "list", "--rescan", rescan === true ? "yes" : "no"
        ];
        listProc.running = true;
    }

    function setWifiEnabled(on) {
        toggleProc.command = ["nmcli", "radio", "wifi", on ? "on" : "off"];
        toggleProc.running = true;
    }

    function connectToSsid(ssid, password) {
        if (busy)
            return;
        busy = true;
        lastError = "";
        var cmd = ["nmcli", "dev", "wifi", "connect", ssid];
        if (password && password.length > 0)
            cmd = cmd.concat(["password", password]);
        actionProc.command = cmd;
        actionProc.running = true;
    }

    function disconnect() {
        if (busy || activeSsid === "")
            return;
        busy = true;
        actionProc.command = ["nmcli", "connection", "down", "id", activeSsid];
        actionProc.running = true;
    }

    function forget(ssid) {
        forgetProc.command = ["nmcli", "connection", "delete", "id", ssid];
        forgetProc.running = true;
    }

    // ---- Helpers -------------------------------------------------------------
    // Split an nmcli terse line, honouring backslash-escaped colons.
    function splitTerse(line) {
        var out = [];
        var cur = "";
        for (var i = 0; i < line.length; i++) {
            var c = line[i];
            if (c === "\\" && i + 1 < line.length) {
                cur += line[i + 1];
                i++;
            } else if (c === ":") {
                out.push(cur);
                cur = "";
            } else {
                cur += c;
            }
        }
        out.push(cur);
        return out;
    }

    function signalIcon(sig, secure) {
        if (!wifiEnabled)
            return String.fromCodePoint(0xF092E); // wifi off
        if (sig >= 75) return String.fromCodePoint(0xF0928);
        if (sig >= 50) return String.fromCodePoint(0xF0925);
        if (sig >= 25) return String.fromCodePoint(0xF0922);
        if (sig > 0)   return String.fromCodePoint(0xF091F);
        return String.fromCodePoint(0xF092D); // outline / no signal
    }

    // ---- Processes -----------------------------------------------------------
    Process {
        id: radioProc
        command: ["nmcli", "-t", "radio", "wifi"]
        stdout: StdioCollector {
            onStreamFinished: root.wifiEnabled = this.text.trim() === "enabled"
        }
    }

    Process {
        id: listProc
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = this.text.split("\n");
                var seen = ({});
                var list = [];
                var actSsid = "";
                var actSig = 0;
                var actSec = false;
                for (var i = 0; i < lines.length; i++) {
                    if (lines[i].length === 0)
                        continue;
                    var f = root.splitTerse(lines[i]);
                    var inUse = f[0] === "*";
                    var ssid = f[1] || "";
                    var sig = parseInt(f[2] || "0");
                    var sec = f[3] || "";
                    var secure = sec.trim() !== "" && sec !== "--";
                    if (ssid === "")
                        continue; // hidden network
                    if (inUse) {
                        actSsid = ssid; actSig = sig; actSec = secure;
                    }
                    // Deduplicate by SSID, keep strongest signal.
                    if (seen[ssid] !== undefined) {
                        if (sig > list[seen[ssid]].signal)
                            list[seen[ssid]].signal = sig;
                        if (inUse)
                            list[seen[ssid]].active = true;
                        continue;
                    }
                    seen[ssid] = list.length;
                    list.push({ ssid: ssid, signal: sig, security: sec,
                                secure: secure, active: inUse });
                }
                list.sort(function(a, b) {
                    if (a.active !== b.active) return a.active ? -1 : 1;
                    return b.signal - a.signal;
                });
                root.networks = list;
                root.activeSsid = actSsid;
                root.activeSignal = actSig;
                root.activeSecure = actSec;
                root.connected = actSsid !== "";
                root.scanning = false;
            }
        }
    }

    Process {
        id: toggleProc
        stdout: StdioCollector {}
        onExited: (code, status) => root.refresh(true)
    }

    Process {
        id: actionProc
        stdout: StdioCollector { id: actionOut }
        stderr: StdioCollector { id: actionErr }
        onExited: (code, status) => {
            root.busy = false;
            var ok = code === 0;
            var msg = ok ? actionOut.text.trim() : actionErr.text.trim();
            root.lastError = ok ? "" : msg;
            root.connectFinished(ok, msg);
            root.refresh(false);
        }
    }

    Process {
        id: forgetProc
        stdout: StdioCollector {}
        onExited: (code, status) => root.refresh(false)
    }

    // Periodic light refresh (no forced rescan).
    Timer {
        interval: 10000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh(false)
    }
}
