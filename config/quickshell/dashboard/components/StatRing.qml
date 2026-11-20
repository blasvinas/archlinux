import QtQuick
import "../../services" as Svc

// Circular progress gauge with a centred glyph + value, used for CPU / RAM /
// disk / temperature tiles on the dashboard.
Item {
    id: root

    property real value: 0          // 0..1 fill
    property string glyph: ""       // Nerd Font codepoint string
    property string label: ""       // caption under the ring
    property string valueText: ""   // big text inside the ring
    property color ringColor: Svc.Theme.accent

    implicitWidth: 92
    implicitHeight: 110

    Behavior on value { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 6

        Item {
            width: 76
            height: 76
            anchors.horizontalCenter: parent.horizontalCenter

            Canvas {
                id: canvas
                anchors.fill: parent
                property real v: root.value
                onVChanged: requestPaint()
                Component.onCompleted: requestPaint()

                onPaint: {
                    var ctx = getContext("2d");
                    ctx.reset();
                    var cx = width / 2, cy = height / 2;
                    var r = Math.min(cx, cy) - 5;
                    var start = -Math.PI / 2;
                    var lw = 7;

                    ctx.lineWidth = lw;
                    ctx.lineCap = "round";

                    // Track
                    ctx.beginPath();
                    ctx.arc(cx, cy, r, 0, 2 * Math.PI);
                    ctx.strokeStyle = Svc.Theme.surface0;
                    ctx.stroke();

                    // Value arc
                    if (v > 0) {
                        ctx.beginPath();
                        ctx.arc(cx, cy, r, start, start + 2 * Math.PI * Math.max(0.001, v));
                        ctx.strokeStyle = root.ringColor;
                        ctx.stroke();
                    }
                }

                Connections {
                    target: Svc.Theme
                    function onVariantChanged() { canvas.requestPaint(); }
                }
            }

            Column {
                anchors.centerIn: parent
                spacing: 0
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.glyph
                    font.family: Svc.Theme.iconFont
                    font.pixelSize: Svc.Theme.fontXl
                    color: root.ringColor
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.valueText
                    font.family: Svc.Theme.fontFamily
                    font.pixelSize: Svc.Theme.fontMd
                    font.bold: true
                    color: Svc.Theme.text
                }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.label
            font.family: Svc.Theme.fontFamily
            font.pixelSize: Svc.Theme.fontXs
            color: Svc.Theme.subtext
        }
    }
}
