import QtQuick
import "../../services" as Svc

// Top processes table with a CPU / RAM sort toggle. Each row shows the process
// name, a proportional usage bar and the measured value.
Card {
    id: root
    title: ""

    // 0 = sort by CPU, 1 = sort by memory.
    property int mode: 0
    readonly property var rows: mode === 0 ? Svc.SysInfo.procsByCpu : Svc.SysInfo.procsByMem

    // Largest value in the current list, used to scale the bars.
    function maxVal() {
        var m = 0;
        for (var i = 0; i < rows.length; i++) {
            var v = mode === 0 ? rows[i].cpu : rows[i].mem;
            if (v > m) m = v;
        }
        return m > 0 ? m : 1;
    }

    Column {
        anchors.fill: parent
        spacing: 8

        // Header: title + sort toggle.
        Item {
            width: parent.width
            height: 22

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: "Top processes"
                font.family: Svc.Theme.fontFamily
                font.pixelSize: 12
                font.bold: true
                color: Svc.Theme.subtext
            }

            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4

                Repeater {
                    model: [{ label: "CPU", m: 0 }, { label: "RAM", m: 1 }]
                    delegate: Rectangle {
                        required property var modelData
                        readonly property bool active: root.mode === modelData.m
                        width: lbl.width + 18
                        height: 22
                        radius: Svc.Theme.radiusPill
                        color: active ? Svc.Theme.accent
                                      : (pma.containsMouse ? Svc.Theme.hover : Svc.Theme.surface0)
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Text {
                            id: lbl
                            anchors.centerIn: parent
                            text: modelData.label
                            font.family: Svc.Theme.fontFamily
                            font.pixelSize: 10
                            font.bold: active
                            color: active ? Svc.Theme.onAccent : Svc.Theme.text
                        }
                        MouseArea {
                            id: pma
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.mode = modelData.m
                        }
                    }
                }
            }
        }

        // Rows.
        Column {
            width: parent.width
            spacing: 5

            Repeater {
                model: root.rows
                delegate: Item {
                    required property var modelData
                    width: parent.width
                    height: 22

                    // Usage bar (behind the text).
                    Rectangle {
                        anchors.fill: parent
                        radius: Svc.Theme.radiusSmall
                        color: Svc.Theme.surface0
                    }
                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        radius: Svc.Theme.radiusSmall
                        width: Math.max(2, parent.width
                            * ((root.mode === 0 ? modelData.cpu : modelData.mem) / root.maxVal()))
                        color: root.mode === 0
                            ? Qt.rgba(Svc.Theme.accent.r, Svc.Theme.accent.g, Svc.Theme.accent.b, 0.25)
                            : Qt.rgba(Svc.Theme.success.r, Svc.Theme.success.g, Svc.Theme.success.b, 0.25)
                        Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 120
                        elide: Text.ElideRight
                        text: modelData.name
                        font.family: Svc.Theme.fontFamily
                        font.pixelSize: 11
                        color: Svc.Theme.text
                    }
                    Text {
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.mode === 0
                            ? modelData.cpu.toFixed(1) + "%"
                            : Svc.SysInfo.fmtBytes(modelData.mem)
                        font.family: Svc.Theme.fontFamily
                        font.pixelSize: 11
                        font.bold: true
                        color: root.mode === 0 ? Svc.Theme.accent : Svc.Theme.success
                    }
                }
            }
        }
    }
}
