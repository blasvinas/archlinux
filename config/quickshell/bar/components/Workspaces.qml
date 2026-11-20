import Quickshell.Hyprland
import QtQuick
import QtQuick.Effects
import "../../services" as Svc

// Per-monitor Hyprland workspace indicator. Click to switch, scroll to cycle.
Row {
    id: root

    // Only show workspaces belonging to this monitor (empty = all).
    property string monitorName: ""

    spacing: 4

    // Workspaces for this monitor, sorted by id (special workspaces excluded).
    readonly property var wsList: {
        var all = Hyprland.workspaces.values;
        var out = [];
        for (var i = 0; i < all.length; i++) {
            var w = all[i];
            if (w.id < 0)
                continue; // special / scratchpad
            if (monitorName === "" || (w.monitor && w.monitor.name === monitorName))
                out.push(w);
        }
        out.sort(function(a, b) { return a.id - b.id; });
        return out;
    }

    Repeater {
        model: root.wsList

        delegate: Rectangle {
            id: pill
            required property var modelData

            readonly property bool focused: modelData.focused
            readonly property bool active: modelData.active
            readonly property bool occupied:
                modelData.toplevels && modelData.toplevels.values.length > 0

            // Empty, unfocused workspaces collapse to a small dot.
            readonly property bool isDot: !focused && !active && !occupied

            anchors.verticalCenter: parent.verticalCenter
            height: isDot ? 8 : 20
            width: focused ? 32 : isDot ? 8 : 20
            radius: Svc.Theme.radiusPill

            // Focused workspace gets a two-stop accent gradient plus a soft
            // accent glow; other states use a flat fill via `color`.
            gradient: focused ? focusGrad : null
            color: focused ? "transparent"
                 : active ? Svc.Theme.muted
                 : occupied ? Svc.Theme.hi
                 : Svc.Theme.muted

            layer.enabled: focused
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Svc.Theme.accent
                shadowOpacity: 0.55
                shadowBlur: 0.6
                blurMax: 16
                shadowVerticalOffset: 0
                autoPaddingEnabled: true
            }

            Gradient {
                id: focusGrad
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: Svc.Theme.accent }
                GradientStop { position: 1.0; color: Svc.Theme.accentAlt }
            }

            Behavior on width { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
            Behavior on height { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: 130 } }

            Text {
                anchors.centerIn: parent
                text: modelData.name
                visible: !pill.isDot
                color: pill.focused ? Svc.Theme.accentFg : Svc.Theme.text
                font.pixelSize: Svc.Theme.fontSm
                font.family: Svc.Theme.fontFamily
                font.bold: pill.focused
            }

            MouseArea {
                anchors.fill: parent
                // Keep tiny dots comfortably clickable.
                anchors.margins: pill.isDot ? -6 : 0
                cursorShape: Qt.PointingHandCursor
                onClicked: modelData.activate()
            }
        }
    }

    // Scroll anywhere on the strip to cycle workspaces on this monitor.
    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: (w) => {
            Hyprland.dispatch(w.angleDelta.y > 0
                ? "workspace m-1" : "workspace m+1");
        }
    }
}
