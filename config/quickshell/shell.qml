//@ pragma UseQApplication
import Quickshell
import Quickshell.Io
import "bar"
import "launcher"
import "notifications"
import "wallpaper"
import "clipboard"
import "powermenu"
import "services" as Svc

ShellRoot {
    // Wallpaper surface per monitor (behind everything).
    Variants {
        model: Quickshell.screens
        delegate: WallpaperView {}
    }

    // Create one Bar per connected monitor.
    Variants {
        model: Quickshell.screens

        delegate: Bar {}
    }

    // Single wallpaper picker instance.
    WallpaperPicker {
        id: wallpaperPicker
    }

    // Single application launcher instance (shown on the focused monitor).
    Launcher {
        id: appLauncher
    }

    // Notification toasts (focused monitor).
    NotificationToasts {}

    // Clipboard history overlay.
    ClipboardHistory {}

    // Session / power menu overlay.
    PowerMenu {}

    // Allow toggling from a keybind:
    //   quickshell ipc call launcher toggle
    IpcHandler {
        target: "launcher"

        function toggle(): void { appLauncher.toggle(); }
        function open(): void { appLauncher.open(); }
        function close(): void { appLauncher.close(); }
    }

    // Theme control:
    //   quickshell ipc call theme set nord
    //   quickshell ipc call theme cycle
    IpcHandler {
        target: "theme"

        function set(name: string): void { Svc.Theme.setVariant(name); }
        function cycle(): void { Svc.Theme.cycle(); }
        function current(): string { return Svc.Theme.variant; }
        function list(): string { return Svc.Theme.names.join(", "); }
    }

    // Wallpaper control:
    //   quickshell ipc call wallpaper toggle | random | next
    IpcHandler {
        target: "wallpaper"

        function toggle(): void { wallpaperPicker.toggle(); }
        function open(): void { wallpaperPicker.open(); }
        function random(): void { Svc.Wallpaper.random(); }
        function next(): void { Svc.Wallpaper.next(); }
        function set(path: string): void { Svc.Wallpaper.setWallpaper(path); }
    }

    // Clipboard history:
    //   quickshell ipc call clipboard toggle
    IpcHandler {
        target: "clipboard"

        function toggle(): void { Svc.Overlays.clipboard.toggle(); }
        function open(): void { Svc.Overlays.clipboard.open(); }
    }

    // Session / power menu:
    //   quickshell ipc call power toggle
    IpcHandler {
        target: "power"

        function toggle(): void { Svc.Overlays.power.toggle(); }
        function open(): void { Svc.Overlays.power.open(); }
    }
}
