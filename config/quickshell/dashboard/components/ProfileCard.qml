import Quickshell
import QtQuick
import QtQuick.Layouts
import "../../services" as Svc

// Header strip: time-aware greeting, user@host, battery summary and quick
// action buttons (wallpaper / clipboard / power).
Card {
    id: root

    property var dashboard

    SystemClock { id: clock; precision: SystemClock.Minutes }

    function greeting() {
        var h = clock.date.getHours();
        if (h < 5) return "Good night";
        if (h < 12) return "Good morning";
        if (h < 18) return "Good afternoon";
        return "Good evening";
    }

    RowLayout {
        anchors.fill: parent
        spacing: 16

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 2
            Text {
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: root.greeting() + (Svc.SysInfo.user ? ", " + Svc.SysInfo.user : "")
                font.family: Svc.Theme.fontFamily
                font.pixelSize: 18
                font.bold: true
                color: Svc.Theme.text
            }
            Text {
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: Qt.formatDateTime(clock.date, "dddd, d MMMM")
                font.family: Svc.Theme.fontFamily
                font.pixelSize: 12
                color: Svc.Theme.subtext
            }
        }

        // Quick toggles (wifi / bluetooth / night light)
        Row {
            Layout.alignment: Qt.AlignVCenter
            spacing: 10

            TogglePill {
                label: Svc.Network.wifiEnabled
                    ? (Svc.Network.connected ? Svc.Network.activeSsid : "Wi-Fi")
                    : "Wi-Fi"
                on: Svc.Network.wifiEnabled
                onToggled: Svc.Network.setWifiEnabled(!Svc.Network.wifiEnabled)
            }
            TogglePill {
                label: "Bluetooth"
                on: Svc.Bt.enabled
                available: Svc.Bt.available
                onToggled: Svc.Bt.setEnabled(!Svc.Bt.enabled)
            }
            TogglePill {
                label: "Night Light"
                on: Svc.NightLight.enabled
                available: Svc.NightLight.available
                onToggled: Svc.NightLight.toggle()
            }
        }

        // Quick actions
        Row {
            Layout.alignment: Qt.AlignVCenter
            spacing: 8

            Repeater {
                model: [
                    { glyph: 0xF0A0D, action: "wallpaper" }, // image-multiple
                    { glyph: 0xF0192, action: "clipboard" },  // clipboard
                    { glyph: 0xF0425, action: "power" }       // power
                ]
                delegate: Rectangle {
                    required property var modelData
                    width: 40
                    height: 40
                    radius: Svc.Theme.radiusMedium
                    color: ma.containsMouse ? Svc.Theme.hover : Svc.Theme.surface0
                    Behavior on color { ColorAnimation { duration: 120 } }

                    Text {
                        anchors.centerIn: parent
                        text: String.fromCodePoint(modelData.glyph)
                        font.family: Svc.Theme.iconFont
                        font.pixelSize: 18
                        color: modelData.action === "power" && ma.containsMouse
                            ? Svc.Theme.danger : Svc.Theme.icon
                    }
                    MouseArea {
                        id: ma
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.dashboard) root.dashboard.close();
                            if (modelData.action === "wallpaper" && Svc.Overlays.wallpaperPicker)
                                Svc.Overlays.wallpaperPicker.open();
                            else if (modelData.action === "clipboard" && Svc.Overlays.clipboard)
                                Svc.Overlays.clipboard.open();
                            else if (modelData.action === "power" && Svc.Overlays.power)
                                Svc.Overlays.power.open();
                        }
                    }
                }
            }
        }
    }
}
