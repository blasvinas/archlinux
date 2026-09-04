import Quickshell.Hyprland
import QtQuick
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

            anchors.verticalCenter: parent.verticalCenter
            height: 20
            width: focused ? 30 : 20
            radius: Svc.Theme.radiusPill

            color: focused ? Svc.Theme.accent
                 : active ? Svc.Theme.muted
                 : occupied ? Svc.Theme.hi
                 : "transparent"
            border.color: (focused || active || occupied) ? "transparent" : Svc.Theme.border
            border.width: 1

            Behavior on width { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: 130 } }

            Text {
                anchors.centerIn: parent
                text: modelData.name
                color: pill.focused ? Svc.Theme.crust : Svc.Theme.text
                font.pixelSize: 12
                font.family: Svc.Theme.fontFamily
                font.bold: pill.focused
            }

            MouseArea {
                anchors.fill: parent
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
