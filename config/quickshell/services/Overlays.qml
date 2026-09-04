pragma Singleton

import Quickshell

// Registry of shared singleton overlay windows (launcher, wallpaper picker),
// so bar widgets can reach them without depending on QML id scoping inside
// Variants delegates. Populated from shell.qml at startup.
Singleton {
    id: root

    property var launcher
    property var wallpaperPicker
    property var clipboard
    property var power
}
