import Quickshell
import Quickshell.Wayland
import Quickshell.Services.SystemTray
import QtQuick
import QtQuick.Effects
import "components"
import "../services" as Svc

PanelWindow {
    id: root

    // The screen this bar instance belongs to (provided by Variants).
    required property var modelData
    screen: modelData

    // Layer-shell namespace so Hyprland can target this surface for blur.
    WlrLayershell.namespace: "quickshell-bar"

    // Anchor the panel to the top edge, spanning the full width. The actual
    // visible bar floats inside with margins (see pods below).
    anchors {
        top: true
        left: true
        right: true
    }

    // Window is taller than the bar itself to leave room for the drop shadow.
    implicitHeight: Svc.Theme.barMargin + Svc.Theme.barHeight + 8

    // Reserve only the bar + top margin so windows don't render underneath it.
    exclusiveZone: Svc.Theme.barMargin + Svc.Theme.barHeight

    // Transparent window: each pod paints its own rounded, blurred surface.
    color: "transparent"

    // ---- Left pod: launcher + quick buttons + workspaces --------------------
    Rectangle {
        id: leftPod
        height: Svc.Theme.barHeight
        anchors.left: parent.left
        anchors.leftMargin: Svc.Theme.barMargin
        anchors.top: parent.top
        anchors.topMargin: Svc.Theme.barMargin
        radius: Svc.Theme.radiusLarge
        color: Svc.Theme.barBg
        implicitWidth: leftRow.implicitWidth + Svc.Theme.podPadding * 2

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Svc.Theme.shadowColor
            shadowBlur: Svc.Theme.shadowBlur
            shadowVerticalOffset: Svc.Theme.shadowY
            autoPaddingEnabled: true
        }

        Row {
            id: leftRow
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: Svc.Theme.podPadding
            spacing: 6

            LauncherButton   { height: leftPod.height }
            DashboardButton  { height: leftPod.height }
            WallpaperButton  { height: leftPod.height }
            ClipboardButton  { height: leftPod.height }

            Workspaces {
                monitorName: root.modelData ? root.modelData.name : ""
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    // ---- Center pod: date and time (+ calendar popup) -----------------------
    Rectangle {
        id: centerPod
        height: Svc.Theme.barHeight
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: Svc.Theme.barMargin
        radius: Svc.Theme.radiusLarge
        color: Svc.Theme.barBg
        implicitWidth: clock.implicitWidth + Svc.Theme.podPadding * 2

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Svc.Theme.shadowColor
            shadowBlur: Svc.Theme.shadowBlur
            shadowVerticalOffset: Svc.Theme.shadowY
            autoPaddingEnabled: true
        }

        Clock {
            id: clock
            barWindow: root
            anchors.centerIn: parent
        }
    }

    // ---- Right pod: tray + system widgets -----------------------------------
    Rectangle {
        id: rightPod
        height: Svc.Theme.barHeight
        anchors.right: parent.right
        anchors.rightMargin: Svc.Theme.barMargin
        anchors.top: parent.top
        anchors.topMargin: Svc.Theme.barMargin
        radius: Svc.Theme.radiusLarge
        color: Svc.Theme.barBg
        implicitWidth: rightRow.implicitWidth + Svc.Theme.podPadding * 2

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Svc.Theme.shadowColor
            shadowBlur: Svc.Theme.shadowBlur
            shadowVerticalOffset: Svc.Theme.shadowY
            autoPaddingEnabled: true
        }

        Row {
            id: rightRow
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: Svc.Theme.podPadding
            spacing: 4

            Tray {
                barWindow: root
                height: rightPod.height
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

            WeatherWidget      { barWindow: root; height: rightPod.height }
            BrightnessWidget   { barWindow: root; height: rightPod.height }
            BatteryWidget      { barWindow: root; height: rightPod.height }
            AudioWidget        { barWindow: root; height: rightPod.height }
            BluetoothWidget    { barWindow: root; height: rightPod.height }
            NetworkWidget      { barWindow: root; height: rightPod.height }
            NotificationWidget { barWindow: root; height: rightPod.height }
            PowerWidget        { barWindow: root; height: rightPod.height }
        }
    }
}
