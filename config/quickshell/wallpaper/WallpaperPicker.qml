import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import "../services" as Svc

// Full-screen overlay wallpaper picker (single instance, focused monitor).
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

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-wallpaper-picker"
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    anchors { top: true; bottom: true; left: true; right: true }
    exclusiveZone: 0
    color: "transparent"
    visible: false

    function open() { visible = true; grab.forceActiveFocus(); }
    function close() { visible = false; }
    function toggle() { visible = !visible; }

    Component.onCompleted: Svc.Overlays.wallpaperPicker = this

    // Dim backdrop; click to dismiss.
    MouseArea { anchors.fill: parent; onClicked: root.close() }
    Rectangle { anchors.fill: parent; color: Svc.Theme.dim }

    // Escape closes.
    Item {
        id: grab
        anchors.fill: parent
        focus: root.visible
        Keys.onEscapePressed: root.close()
    }

    Rectangle {
        id: box
        width: Math.min(root.width - 80, 1000)
        height: Math.min(root.height - 120, 680)
        anchors.centerIn: parent
        radius: Svc.Theme.radiusXl
        color: Svc.Theme.toastBg
        border.color: Svc.Theme.border
        border.width: 1

        MouseArea { anchors.fill: parent }  // swallow clicks

        Column {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            // Header
            Item {
                width: parent.width
                height: 28

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Wallpaper"
                    color: Svc.Theme.text
                    font.pixelSize: 18
                    font.bold: true
                }

                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 14

                    Text {
                        text: String.fromCodePoint(0xF049D) // shuffle
                        font.family: Svc.Theme.iconFont
                        font.pixelSize: 20
                        color: shufHover.hovered ? Svc.Theme.accent : Svc.Theme.subtext
                        HoverHandler { id: shufHover }
                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -6
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Svc.Wallpaper.random()
                        }
                    }
                    Text {
                        text: String.fromCodePoint(0xF0156) // close
                        font.family: Svc.Theme.iconFont
                        font.pixelSize: 20
                        color: closeHover.hovered ? Svc.Theme.danger : Svc.Theme.subtext
                        HoverHandler { id: closeHover }
                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -6
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.close()
                        }
                    }
                }
            }

            // Thumbnail grid
            GridView {
                id: grid
                width: parent.width
                height: parent.height - 40
                clip: true
                cellWidth: Math.floor(width / Math.max(1, Math.floor(width / 220)))
                cellHeight: Math.round(cellWidth * 0.62)
                model: Svc.Wallpaper.model
                boundsBehavior: Flickable.StopAtBounds

                delegate: Item {
                    required property var model
                    width: grid.cellWidth
                    height: grid.cellHeight

                    readonly property bool active: model.filePath === Svc.Wallpaper.current

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 6
                        radius: Svc.Theme.radiusCard
                        color: Svc.Theme.base
                        clip: true
                        border.color: active ? Svc.Theme.accent
                            : (thumbHover.hovered ? Svc.Theme.subtext : "transparent")
                        border.width: active ? 3 : 2

                        Image {
                            anchors.fill: parent
                            anchors.margins: active ? 3 : 2
                            source: "file://" + model.filePath
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: true
                            sourceSize.width: 320
                            sourceSize.height: 200
                        }

                        // Active check badge.
                        Rectangle {
                            visible: active
                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.margins: 6
                            width: 22; height: 22; radius: Svc.Theme.radiusPill
                            color: Svc.Theme.accent
                            Text {
                                anchors.centerIn: parent
                                text: String.fromCodePoint(0xF012C) // check
                                font.family: Svc.Theme.iconFont
                                font.pixelSize: 13
                                color: Svc.Theme.onAccent
                            }
                        }

                        HoverHandler { id: thumbHover }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Svc.Wallpaper.setWallpaper(model.filePath)
                        }
                    }
                }
            }
        }
    }
}
