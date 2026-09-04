import Quickshell
import Quickshell.Services.Notifications
import QtQuick
import "../services" as Svc

// A single on-screen notification card.
Rectangle {
    id: card

    required property var notif

    // Critical notifications stay until dismissed.
    readonly property int timeout:
        notif && notif.urgency === NotificationUrgency.Critical ? 0 : 6000

    width: 380
    implicitHeight: Math.max(64, layout.implicitHeight + 20)
    radius: Svc.Theme.radiusLarge
    color: Svc.Theme.toastBg
    border.color: Svc.Theme.border
    border.width: 1

    // Urgency stripe.
    Rectangle {
        width: 4
        height: parent.height - 16
        anchors.left: parent.left
        anchors.leftMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        radius: Svc.Theme.radiusPill
        color: Svc.Notifications.urgencyColor(card.notif.urgency)
    }

    // Auto-dismiss (non-critical).
    Timer {
        interval: card.timeout
        running: card.timeout > 0
        onTriggered: Svc.Notifications.removePopup(card.notif)
    }

    // If closed elsewhere, drop the toast too.
    Connections {
        target: card.notif
        function onClosed() { Svc.Notifications.removePopup(card.notif); }
    }

    Row {
        id: layout
        anchors.fill: parent
        anchors.leftMargin: 18
        anchors.rightMargin: 12
        anchors.topMargin: 10
        anchors.bottomMargin: 10
        spacing: 12

        // Icon / image
        Item {
            width: 40
            height: 40
            anchors.top: parent.top

            Image {
                id: img
                anchors.fill: parent
                source: card.notif.image && card.notif.image !== ""
                    ? card.notif.image
                    : (card.notif.appIcon ? "image://icon/" + card.notif.appIcon : "")
                sourceSize.width: 80
                sourceSize.height: 80
                fillMode: Image.PreserveAspectFit
                smooth: true
                asynchronous: true
                visible: status === Image.Ready
            }
            Rectangle {
                anchors.fill: parent
                radius: Svc.Theme.radiusMedium
                visible: img.status !== Image.Ready
                color: Svc.Theme.hi
                Text {
                    anchors.centerIn: parent
                    text: (card.notif.appName || "?").slice(0, 1).toUpperCase()
                    color: Svc.Theme.text
                    font.pixelSize: 18
                    font.bold: true
                }
            }
        }

        // Text + actions
        Column {
            width: parent.width - 40 - 12 - 22
            spacing: 3

            Text {
                width: parent.width
                text: card.notif.appName || ""
                color: Svc.Theme.accent
                font.pixelSize: 10
                font.bold: true
                elide: Text.ElideRight
                visible: text.length > 0
            }
            Text {
                width: parent.width
                text: card.notif.summary || ""
                color: Svc.Theme.text
                font.pixelSize: 13
                font.bold: true
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
            }
            Text {
                width: parent.width
                text: card.notif.body || ""
                color: Svc.Theme.subtext
                font.pixelSize: 12
                textFormat: Text.StyledText
                wrapMode: Text.Wrap
                maximumLineCount: 4
                elide: Text.ElideRight
                visible: text.length > 0
                onLinkActivated: (link) => Quickshell.execDetached(["xdg-open", link])
            }

            // Action buttons (excluding the implicit "default").
            Row {
                spacing: 6
                visible: card.notif.actions.length > 0
                Repeater {
                    model: card.notif.actions
                    delegate: Rectangle {
                        required property var modelData
                        visible: modelData.identifier !== "default"
                        width: Math.max(60, aTxt.implicitWidth + 18)
                        height: 26
                        radius: Svc.Theme.radiusSmall
                        color: aMouse.containsMouse ? Svc.Theme.border : Svc.Theme.hi
                        Text {
                            id: aTxt
                            anchors.centerIn: parent
                            text: modelData.text
                            color: Svc.Theme.text
                            font.pixelSize: 11
                        }
                        MouseArea {
                            id: aMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                modelData.invoke();
                                Svc.Notifications.removePopup(card.notif);
                            }
                        }
                    }
                }
            }
        }
    }

    // Close button.
    Text {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 8
        text: String.fromCodePoint(0xF0156)
        font.family: Svc.Theme.iconFont
        font.pixelSize: 14
        color: closeMouse.containsMouse ? Svc.Theme.text : Svc.Theme.subtext
        MouseArea {
            id: closeMouse
            anchors.fill: parent
            anchors.margins: -6
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: Svc.Notifications.removePopup(card.notif)
        }
    }

    // Click body → default action (if any) then dismiss.
    MouseArea {
        anchors.fill: parent
        z: -1
        acceptedButtons: Qt.LeftButton
        onClicked: {
            var acts = card.notif.actions;
            for (var i = 0; i < acts.length; i++) {
                if (acts[i].identifier === "default") {
                    acts[i].invoke();
                    break;
                }
            }
            Svc.Notifications.removePopup(card.notif);
        }
    }
}
