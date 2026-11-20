import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Effects
import "components"
import "../bar/components" as Bar
import "../services" as Svc

// Caelestia-style dashboard: a slide-down panel on the focused monitor that
// gathers greeting, media, system stats, calendar and weather into one place.
PanelWindow {
    id: root

    screen: {
        var fm = Hyprland.focusedMonitor;
        if (fm) {
            var scr = Quickshell.screens;
            for (var i = 0; i < scr.length; i++)
                if (scr[i].name === fm.name)
                    return scr[i];
        }
        return null;
    }

    readonly property int margin: 16
    readonly property int gap: 12
    readonly property int leftW: 456
    readonly property int rightW: 300
    readonly property int profileH: 76
    readonly property int tabH: 36
    readonly property int calendarH: 340
    readonly property int weatherH: 210
    readonly property int rightColH: calendarH + gap + weatherH
    readonly property int mediaH: 170
    readonly property int contentW: leftW + gap + rightW
    readonly property int panelW: margin * 2 + contentW
    readonly property int panelH: margin * 2 + profileH + gap + tabH + gap + rightColH

    // Active tab: 0 = overview, 1 = performance.
    property int tab: 0
    onTabChanged: Svc.SysInfo.fast = (tab === 1)

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-dashboard"
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    anchors { top: true; bottom: true; left: true; right: true }
    exclusiveZone: -1
    color: "transparent"
    visible: false

    function open() {
        Svc.SysInfo.active = true;
        Svc.SysInfo.fast = (tab === 1);
        Svc.SysInfo.refresh();
        Svc.Cava.active = true;
        visible = true;
        grab.forceActiveFocus();
    }
    function close() {
        Svc.SysInfo.active = false;
        Svc.SysInfo.fast = false;
        Svc.Cava.active = false;
        visible = false;
    }
    function toggle() { if (visible) close(); else open(); }

    Component.onCompleted: Svc.Overlays.dashboard = this

    // Dim + click-away to dismiss.
    Rectangle {
        anchors.fill: parent
        color: Svc.Theme.dim
        opacity: root.visible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutQuad } }
    }
    MouseArea { anchors.fill: parent; onClicked: root.close() }

    Item {
        id: grab
        anchors.fill: parent
        focus: root.visible
        Keys.onEscapePressed: root.close()
    }

    // The sliding panel.
    Rectangle {
        id: panel
        width: root.panelW
        height: root.panelH
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: Svc.Theme.barMargin + Svc.Theme.barHeight + 6
        radius: Svc.Theme.radiusXl
        color: Svc.Theme.glassBg
        border.color: Svc.Theme.border
        border.width: 1

        opacity: root.visible ? 1 : 0
        transform: Translate {
            y: root.visible ? 0 : -24
            Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        }
        Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutQuad } }

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Svc.Theme.shadowColor
            shadowBlur: Svc.Theme.shadowBlur
            shadowVerticalOffset: Svc.Theme.shadowY
            autoPaddingEnabled: true
        }

        // Swallow clicks so they don't fall through to the dismiss layer.
        MouseArea { anchors.fill: parent }

        // ---- Header -------------------------------------------------------
        ProfileCard {
            id: profile
            dashboard: root
            x: root.margin
            y: root.margin
            width: root.contentW
            height: root.profileH
        }

        // ---- Tab selector -------------------------------------------------
        TabBar {
            id: tabBar
            x: root.margin
            y: profile.y + profile.height + root.gap
            currentIndex: root.tab
            onCurrentIndexChanged: root.tab = currentIndex
            tabs: [
                { glyph: String.fromCodePoint(0xF0A70), label: "Overview" },    // view-dashboard
                { glyph: String.fromCodePoint(0xF0208), label: "Performance" }  // speedometer
            ]
        }

        // ---- Content region: swaps between the two tab views --------------
        Item {
            id: content
            x: root.margin
            y: tabBar.y + root.tabH + root.gap
            width: root.contentW
            height: root.rightColH

            // Overview tab ---------------------------------------------------
            Item {
                anchors.fill: parent
                visible: root.tab === 0

                MediaCard {
                    id: media
                    x: 0
                    y: 0
                    width: root.leftW
                    height: root.mediaH
                }
                StatsCard {
                    x: 0
                    y: media.y + media.height + root.gap
                    width: root.leftW
                    height: root.rightColH - root.mediaH - root.gap
                }

                Card {
                    id: calCard
                    title: "Calendar"
                    x: root.leftW + root.gap
                    y: 0
                    width: root.rightW
                    height: root.calendarH

                    Bar.Calendar {
                        anchors.fill: parent
                        Component.onCompleted: resetToToday()
                    }
                }
                WeatherCard {
                    x: calCard.x
                    y: calCard.y + calCard.height + root.gap
                    width: root.rightW
                    height: root.weatherH
                }
            }

            // Performance tab ------------------------------------------------
            PerformanceView {
                anchors.fill: parent
                visible: root.tab === 1
            }
        }
    }
}
