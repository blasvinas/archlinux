pragma Singleton

import Quickshell

// Session / power actions.
Singleton {
    id: root

    function lock() {
        Quickshell.execDetached(["hyprlock"]);
    }
    function logout() {
        Quickshell.execDetached(["hyprctl", "dispatch", "exit"]);
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
