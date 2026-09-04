import Quickshell.Services.SystemTray
import QtQuick
import "../../services" as Svc

// System tray: one icon per registered StatusNotifierItem.
Row {
    id: root

    property var barWindow

    spacing: 2

    Repeater {
        model: SystemTray.items

        delegate: TrayItem {
            required property var modelData
            item: modelData
            barWindow: root.barWindow
            height: root.height
        }
    }
}
