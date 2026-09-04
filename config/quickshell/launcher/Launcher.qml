import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import "../services" as Svc

// Full-screen overlay application launcher (single instance).
PanelWindow {
    id: root

    // Show on the currently focused monitor.
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

    // Search state.
    property string query: ""
    property int selected: 0

    // Right-click actions menu state.
    property var actionEntry: null
    property real menuX: 0
    property real menuY: 0
    readonly property var actionList: actionEntry ? actionEntry.actions : []

    // Filtered, sorted application list.
    readonly property var results: {
        var q = query.trim().toLowerCase();
        var apps = DesktopEntries.applications.values;
        var out = [];
        for (var i = 0; i < apps.length; i++) {
            var a = apps[i];
            if (a.noDisplay)
                continue;
            if (q === "") {
                out.push(a);
                continue;
            }
            var hay = (a.name + " " + (a.genericName || "") + " "
                       + (a.comment || "") + " " + (a.keywords || []).join(" ")).toLowerCase();
            if (hay.indexOf(q) >= 0)
                out.push(a);
        }
        out.sort(function(x, y) {
            if (q !== "") {
                // Prefer names that start with the query.
                var xs = x.name.toLowerCase().indexOf(q) === 0;
                var ys = y.name.toLowerCase().indexOf(q) === 0;
                if (xs !== ys) return xs ? -1 : 1;
            }
            return x.name.localeCompare(y.name);
        });
        return out;
    }

    onResultsChanged: { selected = 0; closeActions(); }

    // Overlay above everything, take keyboard focus while open.
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-launcher"
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    anchors { top: true; bottom: true; left: true; right: true }
    exclusiveZone: 0
    color: "transparent"
    visible: false

    // ---- Public control ------------------------------------------------------
    function open() {
        query = "";
        selected = 0;
        visible = true;
        input.forceActiveFocus();
    }
    function close() {
        visible = false;
    }
    function toggle() {
        if (visible) close(); else open();
    }

    Component.onCompleted: Svc.Overlays.launcher = this

    function launch(entry) {
        if (!entry)
            return;
        close();
        entry.execute();
    }
    function launchSelected() {
        if (results.length > 0)
            launch(results[selected]);
    }
    function move(delta) {
        if (results.length === 0)
            return;
        selected = (selected + delta + results.length) % results.length;
        list.positionViewAtIndex(selected, ListView.Contain);
    }

    function openActions(entry, x, y) {
        if (!entry || !entry.actions || entry.actions.length === 0)
            return;
        actionEntry = entry;
        var menuW = 210;
        var menuH = (entry.actions.length + 1) * 34 + 12;
        menuX = Math.max(6, Math.min(x, box.width - menuW - 6));
        menuY = Math.max(6, Math.min(y, box.height - menuH - 6));
    }
    function closeActions() {
        actionEntry = null;
    }
    function runAction(action) {
        closeActions();
        close();
        action.execute();
    }

    // Dim background; click to dismiss.
    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }
    Rectangle {
        anchors.fill: parent
        color: Svc.Theme.dim
    }

    // ---- Launcher box --------------------------------------------------------
    Rectangle {
        id: box
        width: 520
        height: 560
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: Math.round(parent.height * 0.12)
        radius: Svc.Theme.radiusXl
        color: Svc.Theme.toastBg
        border.color: Svc.Theme.border
        border.width: 1

        // Swallow clicks so they don't reach the dismiss area.
        MouseArea { anchors.fill: parent; acceptedButtons: Qt.LeftButton | Qt.RightButton }

        Column {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12

            // Search field
            Rectangle {
                width: parent.width
                height: 44
                radius: Svc.Theme.radiusCard
                color: Svc.Theme.crust
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
                        width: parent.width - 34
                        color: Svc.Theme.text
                        font.pixelSize: 16
                        clip: true
                        focus: true
                        onTextChanged: root.query = text

                        Keys.onEscapePressed: {
                            if (root.actionEntry) root.closeActions();
                            else root.close();
                        }
                        Keys.onDownPressed: root.move(1)
                        Keys.onUpPressed: root.move(-1)
                        Keys.onReturnPressed: root.launchSelected()
                        Keys.onEnterPressed: root.launchSelected()
                        Keys.onRightPressed: {
                            if (root.results.length > 0)
                                root.openActions(root.results[root.selected], 120, 120);
                        }

                        Text {
                            anchors.fill: parent
                            verticalAlignment: Text.AlignVCenter
                            text: "Search applications…"
                            color: Svc.Theme.subtext
                            font.pixelSize: 16
                            visible: input.text.length === 0
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
                    height: 52
                    radius: Svc.Theme.radiusCard
                    color: index === root.selected ? Svc.Theme.hi : "transparent"

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 12

                        Item {
                            width: 34; height: 34
                            anchors.verticalCenter: parent.verticalCenter

                            Image {
                                id: appIcon
                                anchors.fill: parent
                                source: modelData.icon ? "image://icon/" + modelData.icon : ""
                                sourceSize.width: 68
                                sourceSize.height: 68
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                                asynchronous: true
                                visible: status === Image.Ready
                            }
                            Rectangle {
                                anchors.fill: parent
                                radius: Svc.Theme.radiusMedium
                                visible: appIcon.status !== Image.Ready
                                color: Svc.Theme.hi
                                Text {
                                    anchors.centerIn: parent
                                    text: (modelData.name || "?").slice(0, 1).toUpperCase()
                                    color: Svc.Theme.text
                                    font.pixelSize: 16
                                    font.bold: true
                                }
                            }
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 46 - (hasActions ? 28 : 0)
                            Text {
                                text: modelData.name
                                color: Svc.Theme.text
                                font.pixelSize: 14
                                font.bold: true
                                elide: Text.ElideRight
                                width: parent.width
                            }
                            Text {
                                text: modelData.comment || modelData.genericName || ""
                                color: Svc.Theme.subtext
                                font.pixelSize: 11
                                elide: Text.ElideRight
                                width: parent.width
                                visible: text.length > 0
                            }
                        }
                    }

                    readonly property bool hasActions:
                        modelData.actions && modelData.actions.length > 0

                    // "More actions" affordance.
                    Text {
                        z: 2
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        visible: hasActions
                        text: String.fromCodePoint(0xF01D9) // dots-horizontal
                        font.family: Svc.Theme.iconFont
                        font.pixelSize: 18
                        color: Svc.Theme.subtext
                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -8
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                var p = parent.mapToItem(box, parent.width / 2, parent.height);
                                root.openActions(modelData, p.x - 180, p.y);
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        cursorShape: Qt.PointingHandCursor
                        onEntered: root.selected = index
                        onClicked: (m) => {
                            if (m.button === Qt.RightButton) {
                                var p = mapToItem(box, m.x, m.y);
                                root.openActions(modelData, p.x, p.y);
                            } else {
                                root.launch(modelData);
                            }
                        }
                    }
                }

                // Empty state
                Text {
                    anchors.centerIn: parent
                    visible: root.results.length === 0
                    text: "No results"
                    color: Svc.Theme.subtext
                    font.pixelSize: 14
                }
            }
        }

        // ---- Right-click actions menu ------------------------------------
        // Backdrop: click anywhere to dismiss the menu.
        MouseArea {
            anchors.fill: parent
            visible: root.actionEntry !== null
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: root.closeActions()
        }

        Rectangle {
            id: actionMenu
            visible: root.actionEntry !== null
            x: root.menuX
            y: root.menuY
            width: 210
            height: menuCol.implicitHeight
            radius: Svc.Theme.radiusCard
            color: Svc.Theme.menuBg
            border.color: Svc.Theme.muted
            border.width: 1

            Column {
                id: menuCol
                width: parent.width
                padding: 4

                // Primary launch entry.
                Rectangle {
                    width: parent.width - 8
                    height: 30
                    radius: Svc.Theme.radiusSmall
                    color: openHover.hovered ? Svc.Theme.hi : "transparent"
                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Open"
                        color: Svc.Theme.text
                        font.pixelSize: 13
                        font.bold: true
                    }
                    HoverHandler { id: openHover }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.launch(root.actionEntry)
                    }
                }

                Rectangle {
                    width: parent.width - 8
                    height: 1
                    color: Svc.Theme.muted
                }

                Repeater {
                    model: root.actionList
                    delegate: Rectangle {
                        required property var modelData
                        width: menuCol.width - 8
                        height: 30
                        radius: Svc.Theme.radiusSmall
                        color: actHover.hovered ? Svc.Theme.hi : "transparent"
                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 8
                            anchors.right: parent.right
                            anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.name
                            color: Svc.Theme.text
                            font.pixelSize: 13
                            elide: Text.ElideRight
                        }
                        HoverHandler { id: actHover }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.runAction(modelData)
                        }
                    }
                }
            }
        }
    }
}
