import Quickshell
import Quickshell.Wayland
import Quickshell.Services.SystemTray
import QtQuick
import "components"
import "../services" as Svc

PanelWindow {
    id: root

    // The screen this bar instance belongs to (provided by Variants).
    required property var modelData
    screen: modelData

    // Layer-shell namespace so Hyprland can target this surface for blur.
    WlrLayershell.namespace: "quickshell-bar"

    // Anchor the panel to the top edge, spanning the full width.
    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: Svc.Theme.barHeight

    // Reserve space so windows don't render underneath the bar.
    exclusiveZone: implicitHeight

    // Semi-transparent so the compositor blur has something to tint.
    color: Svc.Theme.barBg

    // Left: launcher button + Hyprland workspaces for this monitor.
    Row {
        anchors.left: parent.left
        anchors.leftMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        LauncherButton {
            height: root.height
        }

        WallpaperButton {
            height: root.height
        }

        ClipboardButton {
            height: root.height
        }

        Workspaces {
            monitorName: root.modelData ? root.modelData.name : ""
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    // Center: date and time (+ calendar popup).
    Clock {
        barWindow: root
        anchors.centerIn: parent
    }

    // Right: system widgets.
    Row {
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        Tray {
            barWindow: root
            height: root.height
            anchors.verticalCenter: parent.verticalCenter
        }

        // Separator between tray and system widgets.
        Rectangle {
            width: 1
            height: 16
            color: Svc.Theme.border
            anchors.verticalCenter: parent.verticalCenter
            visible: SystemTray.items.values.length > 0
        }

        WeatherWidget {
            barWindow: root
            height: root.height
        }

        BrightnessWidget {
            barWindow: root
            height: root.height
        }

        BatteryWidget {
            barWindow: root
            height: root.height
        }

        AudioWidget {
            barWindow: root
            height: root.height
        }

        BluetoothWidget {
            barWindow: root
            height: root.height
        }

        NetworkWidget {
            barWindow: root
            height: root.height
        }

        NotificationWidget {
            barWindow: root
            height: root.height
        }

        PowerWidget {
            barWindow: root
            height: root.height
        }
    }
}
