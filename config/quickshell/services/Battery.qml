pragma Singleton

import Quickshell
import Quickshell.Services.UPower
import QtQuick

// UPower frontend for the primary battery + auxiliary battery devices
// (wireless mouse/keyboard, etc).
Singleton {
    id: root

    readonly property var device: UPower.displayDevice
    readonly property bool onBattery: UPower.onBattery

    readonly property bool available: device && device.isLaptopBattery && device.isPresent
    readonly property real percent: device ? device.percentage : 0          // 0..1
    readonly property int state: device ? device.state : UPowerDeviceState.Unknown
    readonly property bool charging: state === UPowerDeviceState.Charging
                                     || state === UPowerDeviceState.PendingCharge
    readonly property bool full: state === UPowerDeviceState.FullyCharged
    readonly property real healthPercent: device && device.healthSupported ? device.healthPercentage : 0
    readonly property bool healthSupported: device ? device.healthSupported : false

    // Seconds until empty (discharging) or full (charging); 0 when unknown/full.
    readonly property int secondsRemaining: {
        if (!device || full)
            return 0;
        if (charging)
            return device.timeToFull;
        if (state === UPowerDeviceState.Discharging)
            return device.timeToEmpty;
        return 0;
    }

    readonly property bool low: available && !charging && percent <= 0.15

    // Auxiliary battery-powered peripherals (mouse, keyboard...).
    readonly property var peripherals: {
        var out = [];
        var d = UPower.devices ? UPower.devices.values : [];
        for (var i = 0; i < d.length; i++) {
            var dev = d[i];
            if (dev === device)
                continue;
            if (dev.type === UPowerDeviceType.Battery && dev.isLaptopBattery)
                continue;
            if (dev.isPresent && dev.percentage > 0
                && dev.type !== UPowerDeviceType.LinePower)
                out.push(dev);
        }
        return out;
    }

    // ---- Formatting helpers --------------------------------------------------
    function formatTime(seconds) {
        if (!seconds || seconds <= 0)
            return "";
        var h = Math.floor(seconds / 3600);
        var m = Math.floor((seconds % 3600) / 60);
        if (h > 0)
            return h + "h " + m + "m";
        return m + "m";
    }

    function stateText() {
        switch (state) {
        case UPowerDeviceState.Charging: return "Charging";
        case UPowerDeviceState.Discharging: return "Discharging";
        case UPowerDeviceState.FullyCharged: return "Fully charged";
        case UPowerDeviceState.PendingCharge: return "Pending charge";
        case UPowerDeviceState.PendingDischarge: return "Pending discharge";
        case UPowerDeviceState.Empty: return "Empty";
        default: return "Unknown";
        }
    }

    // ---- Icons ---------------------------------------------------------------
    readonly property var _discharge: [
        0xF008E, 0xF007A, 0xF007B, 0xF007C, 0xF007D, 0xF007E,
        0xF007F, 0xF0080, 0xF0081, 0xF0082, 0xF0079
    ]
    readonly property var _charge: [
        0xF089B, 0xF089C, 0xF089D, 0xF089E, 0xF089F, 0xF08A0,
        0xF08A1, 0xF08A2, 0xF08A3, 0xF08A4, 0xF0085
    ]

    // Icon for an arbitrary percentage (0..1) and charging flag.
    function iconFor(pct, isCharging) {
        var step = Math.round(Math.max(0, Math.min(pct, 1)) * 10);
        return String.fromCodePoint((isCharging ? _charge : _discharge)[step]);
    }

    function batteryIcon() {
        if (full)
            return String.fromCodePoint(0xF0085); // charged
        return iconFor(percent, charging);
    }
}
