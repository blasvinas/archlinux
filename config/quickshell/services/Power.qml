pragma Singleton

import Quickshell
import "." as Svc

// Session / power actions.
Singleton {
    id: root

    function lock() {
        // Native quickshell session lock (see lock/Lock.qml).
        Svc.Lock.lock();
    }
    function logout() {
        // Hyprland 0.56+ parses dispatch args as Lua, so "hyprctl dispatch exit"
        // no longer works. Terminate the login session cleanly instead.
        Quickshell.execDetached(["loginctl", "terminate-session", "self"]);
    }
    function suspend() {
        Quickshell.execDetached(["systemctl", "suspend"]);
    }
    function hibernate() {
        Quickshell.execDetached(["systemctl", "hibernate"]);
    }
    function reboot() {
        Quickshell.execDetached(["systemctl", "reboot"]);
    }
    function shutdown() {
        Quickshell.execDetached(["systemctl", "poweroff"]);
    }
}
