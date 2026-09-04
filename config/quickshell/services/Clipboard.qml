pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Clipboard history via `cliphist` (fed by `wl-paste --watch cliphist store`).
Singleton {
    id: root

    // List of { id, preview } (newest first, as cliphist returns).
    property var entries: []

    function refresh() {
        listProc.running = true;
    }

    // Copy an entry back to the clipboard by id.
    function copy(id) {
        Quickshell.execDetached(["sh", "-c", "cliphist decode " + id + " | wl-copy"]);
    }

    // Remove a single entry (cliphist deletes by the leading id on stdin).
    function remove(id) {
        rmProc.command = ["sh", "-c", "printf '%s\\t\\n' " + id + " | cliphist delete"];
        rmProc.running = true;
    }

    function clear() {
        wipeProc.running = true;
    }

    Process {
        id: listProc
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = this.text.split("\n");
                var out = [];
                for (var i = 0; i < lines.length; i++) {
                    if (lines[i].length === 0)
                        continue;
                    var tab = lines[i].indexOf("\t");
                    if (tab < 0)
                        continue;
                    out.push({
                        id: lines[i].slice(0, tab),
                        preview: lines[i].slice(tab + 1)
                    });
                }
                root.entries = out;
            }
        }
    }

    Process {
        id: rmProc
        onExited: (code, status) => root.refresh()
    }

    Process {
        id: wipeProc
        command: ["cliphist", "wipe"]
        onExited: (code, status) => root.refresh()
    }
}
