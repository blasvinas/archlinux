import Quickshell
import Quickshell.Hyprland
import QtQuick
import "../../services" as Svc

// Dropdown panel: output & input volume sliders + device selection.
PopupWindow {
    id: pop

    property var barWindow
    property Item anchorItem
    property bool showSinks: false
    property bool showSources: false

    anchor.window: barWindow
    anchor.rect.x: {
        if (!anchorItem || !barWindow)
            return 0;
        var p = anchorItem.mapToItem(barWindow.contentItem, 0, 0);
        return Math.round(p.x + anchorItem.width - width);
    }
    anchor.rect.y: barWindow ? barWindow.height : 32

    implicitWidth: 340
    implicitHeight: content.implicitHeight
    visible: false
    color: "transparent"

    HyprlandFocusGrab {
        windows: [pop]
        active: pop.visible
        onCleared: pop.visible = false
    }

    onVisibleChanged: if (!visible) { showSinks = false; showSources = false; }

    Rectangle {
        id: content
        anchors.fill: parent
        implicitHeight: layout.implicitHeight
        radius: Svc.Theme.radiusLarge
        color: Svc.Theme.popupBg
        border.color: Svc.Theme.border
        border.width: 1

        Column {
            id: layout
            width: parent.width
            padding: 12
            spacing: 10

            // ================= OUTPUT =================
            Text {
                text: "Output"
                color: Svc.Theme.subtext
                font.pixelSize: 11
                font.bold: true
            }

            Row {
                width: parent.width - 24
                spacing: 10

                // Mute toggle
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 24
                    text: Svc.Audio.sinkIcon()
                    font.family: Svc.Theme.iconFont
                    font.pixelSize: 20
                    color: Svc.Audio.sinkMuted ? Svc.Theme.subtext : Svc.Theme.text
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Svc.Audio.toggleSinkMute()
                    }
                }

                Slider {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 24 - 44 - 24 - 20
                    value: Svc.Audio.sinkMuted ? 0 : Svc.Audio.sinkVolume
                    fillColor: Svc.Audio.sinkMuted ? Svc.Theme.subtext : Svc.Theme.accent
                    onMoved: (v) => Svc.Audio.setSinkVolume(v)
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 40
                    horizontalAlignment: Text.AlignRight
                    text: Math.round(Svc.Audio.sinkVolume * 100) + "%"
                    color: Svc.Theme.text
                    font.pixelSize: 12
                    font.family: Svc.Theme.fontFamily
                }

                // Device chooser toggle
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 16
                    text: String.fromCodePoint(pop.showSinks ? 0xF0143 : 0xF0140) // chevron
                    font.family: Svc.Theme.iconFont
                    font.pixelSize: 16
                    color: Svc.Theme.subtext
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: pop.showSinks = !pop.showSinks
                    }
                }
            }

            // Sink device list
            Column {
                width: parent.width - 24
                spacing: 2
                visible: pop.showSinks
                Repeater {
                    model: Svc.Audio.sinks
                    delegate: Rectangle {
                        required property var modelData
                        readonly property bool active: Svc.Audio.sink && modelData.id === Svc.Audio.sink.id
                        width: parent.width
                        height: 28
                        radius: Svc.Theme.radiusSmall
                        color: dmouse.containsMouse ? Svc.Theme.hi : "transparent"
                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 16
                            elide: Text.ElideRight
                            text: (active ? "● " : "○ ") + (modelData.description || modelData.name)
                            color: active ? Svc.Theme.accent : Svc.Theme.text
                            font.pixelSize: 12
                        }
                        MouseArea {
                            id: dmouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Svc.Audio.setDefaultSink(modelData)
                        }
                    }
                }
            }

            Rectangle { width: parent.width - 24; height: 1; color: Svc.Theme.hi }

            // ================= INPUT =================
            Text {
                text: "Input"
                color: Svc.Theme.subtext
                font.pixelSize: 11
                font.bold: true
            }

            Row {
                width: parent.width - 24
                spacing: 10

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 24
                    text: Svc.Audio.sourceIcon()
                    font.family: Svc.Theme.iconFont
                    font.pixelSize: 20
                    color: Svc.Audio.sourceMuted ? Svc.Theme.subtext : Svc.Theme.text
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Svc.Audio.toggleSourceMute()
                    }
                }

                Slider {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 24 - 44 - 24 - 20
                    value: Svc.Audio.sourceMuted ? 0 : Svc.Audio.sourceVolume
                    fillColor: Svc.Audio.sourceMuted ? Svc.Theme.subtext : Svc.Theme.accent
                    onMoved: (v) => Svc.Audio.setSourceVolume(v)
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 40
                    horizontalAlignment: Text.AlignRight
                    text: Math.round(Svc.Audio.sourceVolume * 100) + "%"
                    color: Svc.Theme.text
                    font.pixelSize: 12
                    font.family: Svc.Theme.fontFamily
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 16
                    text: String.fromCodePoint(pop.showSources ? 0xF0143 : 0xF0140)
                    font.family: Svc.Theme.iconFont
                    font.pixelSize: 16
                    color: Svc.Theme.subtext
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: pop.showSources = !pop.showSources
                    }
                }
            }

            Column {
                width: parent.width - 24
                spacing: 2
                visible: pop.showSources
                Repeater {
                    model: Svc.Audio.sources
                    delegate: Rectangle {
                        required property var modelData
                        readonly property bool active: Svc.Audio.source && modelData.id === Svc.Audio.source.id
                        width: parent.width
                        height: 28
                        radius: Svc.Theme.radiusSmall
                        color: smouse.containsMouse ? Svc.Theme.hi : "transparent"
                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 16
                            elide: Text.ElideRight
                            text: (active ? "● " : "○ ") + (modelData.description || modelData.name)
                            color: active ? Svc.Theme.accent : Svc.Theme.text
                            font.pixelSize: 12
                        }
                        MouseArea {
                            id: smouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Svc.Audio.setDefaultSource(modelData)
                        }
                    }
                }
            }
        }
    }
}
