import QtQuick
import QtQuick.Effects
import "../../services" as Svc

// MPRIS "now playing" pane: album art, metadata, scrubber and transport
// controls. Falls back to a placeholder when nothing is playing.
Card {
    id: root
    title: "Now Playing"

    readonly property bool has: Svc.Media.hasPlayer

    // --- Ambient spectrum backdrop ----------------------------------------
    Visualizer {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 42
        opacity: 0.22
    }

    // --- Placeholder when there is no active player ------------------------
    Column {
        anchors.centerIn: parent
        visible: !root.has
        spacing: 8
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: String.fromCodePoint(0xF075A) // music-note-off
            font.family: Svc.Theme.iconFont
            font.pixelSize: 40
            color: Svc.Theme.muted
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Nothing playing"
            font.family: Svc.Theme.fontFamily
            font.pixelSize: 13
            color: Svc.Theme.subtext
        }
    }

    // --- Active player -----------------------------------------------------
    Row {
        anchors.fill: parent
        visible: root.has
        spacing: 14

        // Album art
        Rectangle {
            id: artFrame
            width: 96
            height: 96
            anchors.verticalCenter: parent.verticalCenter
            radius: Svc.Theme.radiusMedium
            color: Svc.Theme.surface0
            clip: true

            Text {
                anchors.centerIn: parent
                visible: img.status !== Image.Ready
                text: String.fromCodePoint(0xF075A)
                font.family: Svc.Theme.iconFont
                font.pixelSize: 36
                color: Svc.Theme.muted
            }

            Image {
                id: img
                anchors.fill: parent
                source: Svc.Media.artUrl
                fillMode: Image.PreserveAspectCrop
                cache: false
                asynchronous: true
                visible: false
            }
            MultiEffect {
                anchors.fill: img
                source: img
                visible: img.status === Image.Ready
                maskEnabled: true
                maskSource: artMask
            }
            Item {
                id: artMask
                width: artFrame.width
                height: artFrame.height
                layer.enabled: true
                visible: false
                Rectangle {
                    anchors.fill: parent
                    radius: Svc.Theme.radiusMedium
                }
            }
        }

        // Metadata + controls
        Column {
            width: parent.width - 96 - 14
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            Text {
                width: parent.width
                text: Svc.Media.title || "Unknown title"
                font.family: Svc.Theme.fontFamily
                font.pixelSize: 15
                font.bold: true
                color: Svc.Theme.text
                elide: Text.ElideRight
            }
            Text {
                width: parent.width
                text: Svc.Media.artist || "Unknown artist"
                font.family: Svc.Theme.fontFamily
                font.pixelSize: 12
                color: Svc.Theme.subtext
                elide: Text.ElideRight
            }

            // Scrubber
            Column {
                width: parent.width
                spacing: 3
                visible: Svc.Media.lengthSupported

                Rectangle {
                    id: track
                    width: parent.width
                    height: 6
                    radius: 3
                    color: Svc.Theme.surface0

                    Rectangle {
                        height: parent.height
                        radius: 3
                        width: parent.width * Svc.Media.progress
                        color: Svc.Theme.accent
                        Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutQuad } }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: (m) => Svc.Media.seek(m.x / width)
                    }
                }
                Row {
                    width: parent.width
                    Text {
                        text: Svc.Media.fmtTime(Svc.Media.position)
                        font.family: Svc.Theme.fontFamily
                        font.pixelSize: 10
                        color: Svc.Theme.subtext
                    }
                    Item { width: parent.width - 80; height: 1 }
                    Text {
                        text: Svc.Media.fmtTime(Svc.Media.length)
                        font.family: Svc.Theme.fontFamily
                        font.pixelSize: 10
                        color: Svc.Theme.subtext
                    }
                }
            }

            // Transport controls
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 18

                Repeater {
                    model: [
                        { glyph: 0xF04AE, action: "prev",   big: false, enabled: Svc.Media.canPrev },
                        { glyph: 0, action: "toggle", big: true,  enabled: true },
                        { glyph: 0xF04AD, action: "next",   big: false, enabled: Svc.Media.canNext }
                    ]
                    delegate: Item {
                        required property var modelData
                        width: modelData.big ? 40 : 30
                        height: modelData.big ? 40 : 30

                        Rectangle {
                            anchors.fill: parent
                            radius: Svc.Theme.radiusPill
                            color: modelData.big ? Svc.Theme.accent
                                : (ma.containsMouse ? Svc.Theme.hover : "transparent")
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }
                        Text {
                            anchors.centerIn: parent
                            text: modelData.big
                                ? String.fromCodePoint(Svc.Media.isPlaying ? 0xF03E4 : 0xF040A)
                                : String.fromCodePoint(modelData.glyph)
                            font.family: Svc.Theme.iconFont
                            font.pixelSize: modelData.big ? 20 : 18
                            color: modelData.big ? Svc.Theme.onAccent
                                : (modelData.enabled ? Svc.Theme.text : Svc.Theme.muted)
                        }
                        MouseArea {
                            id: ma
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: modelData.enabled
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (modelData.action === "prev") Svc.Media.previous();
                                else if (modelData.action === "next") Svc.Media.next();
                                else Svc.Media.toggle();
                            }
                        }
                    }
                }
            }
        }
    }
}
