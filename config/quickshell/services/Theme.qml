pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Central theme. Colors come from a named palette; switch with setVariant()/cycle().
// The choice is persisted to the state dir and restored on startup.
Singleton {
    id: root

    // ---- Active variant ------------------------------------------------------
    property string variant: "mocha"
    readonly property var names: ["mocha", "macchiato", "latte", "nord", "gruvbox", "tokyonight"]

    function setVariant(name) {
        if (palettes[name]) {
            variant = name;
            store.setText(name);
        }
    }
    function cycle() {
        var i = names.indexOf(variant);
        setVariant(names[(i + 1 + names.length) % names.length]);
    }

    // ---- Fonts ---------------------------------------------------------------
    readonly property string fontFamily: "monospace"
    readonly property string iconFont: "AtkynsonMono Nerd Font"

    // ---- Palettes ------------------------------------------------------------
    // Each palette provides the raw ramp; roles/surfaces below are derived.
    readonly property var palettes: ({
        "mocha": {
            dark: true, base: "#1e1e2e", mantle: "#181825", crust: "#11111b",
            surface0: "#313244", surface1: "#45475a", surface2: "#585b70",
            text: "#cdd6f4", subtext: "#a6adc8", blue: "#89b4fa",
            red: "#f38ba8", green: "#a6e3a1", yellow: "#f9e2af", onAccent: "#11111b"
        },
        "macchiato": {
            dark: true, base: "#24273a", mantle: "#1e2030", crust: "#181926",
            surface0: "#363a4f", surface1: "#494d64", surface2: "#5b6078",
            text: "#cad3f5", subtext: "#a5adcb", blue: "#8aadf4",
            red: "#ed8796", green: "#a6da95", yellow: "#eed49f", onAccent: "#181926"
        },
        "latte": {
            dark: false, base: "#eff1f5", mantle: "#e6e9ef", crust: "#dce0e8",
            surface0: "#ccd0da", surface1: "#bcc0cc", surface2: "#acb0be",
            text: "#4c4f69", subtext: "#6c6f85", blue: "#1e66f5",
            red: "#d20f39", green: "#40a02b", yellow: "#df8e1d", onAccent: "#ffffff"
        },
        "nord": {
            dark: true, base: "#2e3440", mantle: "#2b303b", crust: "#242933",
            surface0: "#3b4252", surface1: "#434c5e", surface2: "#4c566a",
            text: "#eceff4", subtext: "#d8dee9", blue: "#88c0d0",
            red: "#bf616a", green: "#a3be8c", yellow: "#ebcb8b", onAccent: "#2e3440"
        },
        "gruvbox": {
            dark: true, base: "#282828", mantle: "#1d2021", crust: "#1b1b1b",
            surface0: "#3c3836", surface1: "#504945", surface2: "#665c54",
            text: "#ebdbb2", subtext: "#bdae93", blue: "#83a598",
            red: "#fb4934", green: "#b8bb26", yellow: "#fabd2f", onAccent: "#282828"
        },
        "tokyonight": {
            dark: true, base: "#1a1b26", mantle: "#16161e", crust: "#13131a",
            surface0: "#292e42", surface1: "#3b4261", surface2: "#545c7e",
            text: "#c0caf5", subtext: "#9aa5ce", blue: "#7aa2f7",
            red: "#f7768e", green: "#9ece6a", yellow: "#e0af68", onAccent: "#1a1b26"
        }
    })

    readonly property var p: palettes[variant] || palettes["mocha"]

    // Prepend an ARGB alpha (e.g. "80") to a "#rrggbb" string -> "#aarrggbb".
    function _a(hex, alpha) { return "#" + alpha + hex.slice(1); }

    // ---- Semantic roles ------------------------------------------------------
    readonly property color base:     p.base
    readonly property color crust:    p.crust
    readonly property color surface0: p.surface0
    readonly property color surface1: p.surface1
    readonly property color surface2: p.surface2
    readonly property color white:    "#ffffff"

    readonly property color text:     p.text
    readonly property color subtext:  p.subtext
    readonly property color accent:   p.blue
    readonly property color hi:       p.surface0
    readonly property color muted:    p.surface2
    readonly property color border:   p.surface1
    readonly property color danger:   p.red
    readonly property color success:  p.green
    readonly property color warning:  p.yellow
    readonly property color onAccent: p.onAccent

    // ---- Surfaces & overlays (derived) --------------------------------------
    readonly property color barBg:   _a(p.base, "80")
    readonly property color popupBg: _a(p.mantle, "ee")
    readonly property color toastBg: _a(p.mantle, "f2")
    readonly property color menuBg:  _a(p.surface0, "f2")
    readonly property color inputBg: p.crust
    readonly property color hover:   p.dark ? "#33ffffff" : "#1a000000"
    readonly property color dim:     "#66000000"

    // ---- Geometry ------------------------------------------------------------
    readonly property int radiusSmall:  6   // small chips
    readonly property int radiusMedium: 8   // widgets / hover highlights
    readonly property int radiusCard:   10  // list rows / tiles / cards
    readonly property int radiusLarge:  12  // dropdown panels
    readonly property int radiusXl:     16  // large modals (launcher)
    readonly property int radiusPill:   999 // fully-rounded pills / circles

    readonly property int spacingSmall:  4
    readonly property int spacingMedium: 8
    readonly property int spacingLarge:  12

    readonly property int barHeight:    32
    readonly property int panelPadding: 12

    // ---- Persistence ---------------------------------------------------------
    FileView {
        id: store
        path: Quickshell.statePath("theme")
        onLoaded: {
            var t = text().trim();
            if (root.palettes[t])
                root.variant = t;
        }
    }
}
