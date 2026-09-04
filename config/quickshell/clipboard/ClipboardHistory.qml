import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import "../services" as Svc

// Full-screen overlay clipboard-history picker (single instance, focused monitor).
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

    property string query: ""
    property int selected: 0

    readonly property var results: {
        var q = query.trim().toLowerCase();
        var all = Svc.Clipboard.entries;
        if (q === "")
            return all;
        var out = [];
        for (var i = 0; i < all.length; i++)
            if (all[i].preview.toLowerCase().indexOf(q) >= 0)
                out.push(all[i]);
        return out;
    }
    onResultsChanged: selected = 0

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-clipboard"
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    anchors { top: true; bottom: true; left: true; right: true }
    exclusiveZone: -1
    color: "transparent"
    visible: false

    function open() {
        query = "";
        selected = 0;
        Svc.Clipboard.refresh();
        visible = true;
        input.forceActiveFocus();
    }
    function close() { visible = false; }
    function toggle() { if (visible) close(); else open(); }

    function pasteSelected() {
        if (results.length > 0) {
            Svc.Clipboard.copy(results[selected].id);
            close();
        }
    }
    function deleteSelected() {
        if (results.length > 0)
            Svc.Clipboard.remove(results[selected].id);
    }
    function move(delta) {
        if (results.length === 0) return;
        selected = (selected + delta + results.length) % results.length;
        list.positionViewAtIndex(selected, ListView.Contain);
    }

    Component.onCompleted: Svc.Overlays.clipboard = this

    MouseArea { anchors.fill: parent; onClicked: root.close() }
    Rectangle { anchors.fill: parent; color: Svc.Theme.dim }

    Rectangle {
        id: box
        width: 560
        height: 600
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: Math.round(parent.height * 0.12)
        radius: Svc.Theme.radiusXl
        color: Svc.Theme.toastBg
        border.color: Svc.Theme.border
        border.width: 1

        MouseArea { anchors.fill: parent }

        Column {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12

            // Search row
            Rectangle {
                width: parent.width
                height: 44
                radius: Svc.Theme.radiusCard
                color: Svc.Theme.inputBg
                border.color: input.activeFocus ? Svc.Theme.accent : Svc.Theme.hi

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 10

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: String.fromCodePoint(0xF0349) // magnify
                        font.family: Svc.Theme.iconFont
                        font.pixelSize: 18
                        color: Svc.Theme.subtext
                    }
                    TextInput {
                        id: input
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 34 - 26
                        color: Svc.Theme.text
                        font.pixelSize: 16
                        clip: true
                        focus: true
                        onTextChanged: root.query = text
                        Keys.onEscapePressed: root.close()
                        Keys.onDownPressed: root.move(1)
                        Keys.onUpPressed: root.move(-1)
                        Keys.onReturnPressed: root.pasteSelected()
                        Keys.onEnterPressed: root.pasteSelected()
                        // Shift+Delete removes the selected entry (plain Delete
                        // still edits the search text).
                        Keys.onDeletePressed: (event) => {
                            if (event.modifiers & Qt.ShiftModifier) {
                                root.deleteSelected();
                                event.accepted = true;
                            } else {
                                event.accepted = false;
                            }
                        }

                        Text {
                            anchors.fill: parent
                            verticalAlignment: Text.AlignVCenter
                            text: "Search clipboard…"
                            color: Svc.Theme.subtext
                            font.pixelSize: 16
                            visible: input.text.length === 0
                        }
                    }
                    // Clear all
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: String.fromCodePoint(0xF0A7A) // delete
                        font.family: Svc.Theme.iconFont
                        font.pixelSize: 18
                        color: clearHover.hovered ? Svc.Theme.danger : Svc.Theme.subtext
                        HoverHandler { id: clearHover }
                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -4
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Svc.Clipboard.clear()
                        }
                    }
                }
            }

            // Results
            ListView {
                id: list
                width: parent.width
                height: parent.height - 44 - 12
                clip: true
                model: root.results
                spacing: 2
                boundsBehavior: Flickable.StopAtBounds
                currentIndex: root.selected

                delegate: Rectangle {
                    required property var modelData
                    required property int index
                    width: list.width
                    height: 46
                    radius: Svc.Theme.radiusCard
                    color: index === root.selected ? Svc.Theme.hi : "transparent"

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.right: trash.left
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.preview
                        color: Svc.Theme.text
                        font.pixelSize: 13
                        font.family: Svc.Theme.fontFamily
                        elide: Text.ElideRight
                    }

                    Text {
                        id: trash
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: String.fromCodePoint(0xF0A7A)
                        font.family: Svc.Theme.iconFont
                        font.pixelSize: 15
                        color: trashHover.hovered ? Svc.Theme.danger : Svc.Theme.subtext
                        HoverHandler { id: trashHover }
                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -6
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Svc.Clipboard.remove(modelData.id)
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        anchors.rightMargin: 30
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: root.selected = index
                        onClicked: { Svc.Clipboard.copy(modelData.id); root.close(); }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: root.results.length === 0
                    text: Svc.Clipboard.entries.length === 0 ? "Clipboard is empty" : "No matches"
                    color: Svc.Theme.subtext
                    font.pixelSize: 14
                }
            }
        }
    }
}
