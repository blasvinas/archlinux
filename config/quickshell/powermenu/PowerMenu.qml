import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import "../services" as Svc

// Full-screen overlay session / power menu (single instance, focused monitor).
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

    // Index of the destructive action awaiting a confirming second click.
    property int confirmIndex: -1

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-powermenu"
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    anchors { top: true; bottom: true; left: true; right: true }
    exclusiveZone: -1
    color: "transparent"
    visible: false

    function open() { confirmIndex = -1; visible = true; grab.forceActiveFocus(); }
    function close() { visible = false; }
    function toggle() { if (visible) close(); else open(); }

    Component.onCompleted: Svc.Overlays.power = this

    readonly property var actions: [
        { label: "Lock",      glyph: 0xF033E, danger: false, run: () => Svc.Power.lock() },
        { label: "Logout",    glyph: 0xF0343, danger: false, run: () => Svc.Power.logout() },
        { label: "Suspend",   glyph: 0xF04B2, danger: false, run: () => Svc.Power.suspend() },
        { label: "Hibernate", glyph: 0xF0904, danger: false, run: () => Svc.Power.hibernate() },
        { label: "Reboot",    glyph: 0xF0709, danger: true,  run: () => Svc.Power.reboot() },
        { label: "Shutdown",  glyph: 0xF0425, danger: true,  run: () => Svc.Power.shutdown() }
    ]

    MouseArea { anchors.fill: parent; onClicked: root.close() }
    Rectangle { anchors.fill: parent; color: Svc.Theme.dim }

    Item {
        id: grab
        anchors.fill: parent
        focus: root.visible
        Keys.onEscapePressed: root.close()
    }

    Rectangle {
        anchors.centerIn: parent
        width: grid.width + 48
        height: title.height + grid.height + 48
        radius: Svc.Theme.radiusXl
        color: Svc.Theme.toastBg
        border.color: Svc.Theme.border
        border.width: 1

        MouseArea { anchors.fill: parent }

        Column {
            anchors.centerIn: parent
            spacing: 16

            Text {
                id: title
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Session"
                color: Svc.Theme.subtext
                font.pixelSize: 13
                font.bold: true
            }

            Grid {
                id: grid
                anchors.horizontalCenter: parent.horizontalCenter
                columns: 3
                columnSpacing: 12
                rowSpacing: 12

                Repeater {
                    model: root.actions
                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        readonly property bool confirming: root.confirmIndex === index
                        readonly property bool danger: modelData.danger
                        readonly property bool invert: confirming || (tile.containsMouse && danger)

                        width: 96
                        height: 84
                        radius: Svc.Theme.radiusLarge
                        color: confirming ? Svc.Theme.danger
                            : tile.containsMouse
                                ? (danger ? Svc.Theme.danger : Svc.Theme.hi)
                                : Svc.Theme.base
                        border.color: (confirming || tile.containsMouse)
                            ? (danger ? Svc.Theme.danger : Svc.Theme.accent)
                            : Svc.Theme.hi
                        border.width: 1

                        Column {
                            anchors.centerIn: parent
                            spacing: 6
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: String.fromCodePoint(confirming ? 0xF012C : modelData.glyph)
                                font.family: Svc.Theme.iconFont
                                font.pixelSize: 30
                                color: invert ? Svc.Theme.onAccent : Svc.Theme.text
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: confirming ? "Confirm?" : modelData.label
                                font.pixelSize: 12
                                font.bold: confirming
                                color: invert ? Svc.Theme.onAccent : Svc.Theme.subtext
                            }
                        }

                        MouseArea {
                            id: tile
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (danger && !confirming) {
                                    root.confirmIndex = index;
                                    return;
                                }
                                root.close();
                                modelData.run();
                            }
                        }
                    }
                }
            }
        }
    }
}
