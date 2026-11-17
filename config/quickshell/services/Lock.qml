pragma Singleton

import Quickshell

// Native session-lock state. The actual lock surface lives in lock/Lock.qml and
// binds to `locked`; flipping it engages/releases the Wayland session lock.
Singleton {
    id: root

    property bool locked: false

    function lock() { root.locked = true; }
    function unlock() { root.locked = false; }
    function toggle() { root.locked = !root.locked; }
}
