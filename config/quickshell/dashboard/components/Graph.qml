import QtQuick
import "../../services" as Svc

// Area + line chart of a rolling history buffer. Values are plotted from oldest
// (left) to newest (right). `maxValue` scales the vertical axis; when 0 the
// graph auto-scales to the largest sample (with a little headroom).
Item {
    id: root

    property var values: []             // array of numbers, newest at the end
    property real maxValue: 100         // 0 => auto-scale
    property color lineColor: Svc.Theme.accent
    property real lineWidth: 2
    property int capacity: Svc.SysInfo.historyLen

    Canvas {
        id: canvas
        anchors.fill: parent

        property var vals: root.values
        onValsChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        Component.onCompleted: requestPaint()

        Connections {
            target: Svc.Theme
            function onVariantChanged() { canvas.requestPaint(); }
        }

        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            var w = width, h = height;

            // Baseline grid.
            ctx.strokeStyle = Svc.Theme.surface0;
            ctx.lineWidth = 1;
            for (var gy = 1; gy < 4; gy++) {
                var y = h * gy / 4;
                ctx.beginPath();
                ctx.moveTo(0, y);
                ctx.lineTo(w, y);
                ctx.stroke();
            }

            var data = root.values || [];
            if (data.length < 2)
                return;

            // Determine vertical scale.
            var max = root.maxValue;
            if (max <= 0) {
                max = 1;
                for (var i = 0; i < data.length; i++)
                    if (data[i] > max) max = data[i];
                max *= 1.15;
            }

            // Map sample index to x using the full capacity so the line scrolls
            // in from the right rather than stretching as it fills.
            var cap = Math.max(root.capacity, data.length);
            var step = w / (cap - 1);
            var offset = w - (data.length - 1) * step;

            function px(i) { return offset + i * step; }
            function py(v) { return h - Math.max(0, Math.min(1, v / max)) * h; }

            // Filled area.
            ctx.beginPath();
            ctx.moveTo(px(0), h);
            for (var a = 0; a < data.length; a++)
                ctx.lineTo(px(a), py(data[a]));
            ctx.lineTo(px(data.length - 1), h);
            ctx.closePath();
            var grad = ctx.createLinearGradient(0, 0, 0, h);
            grad.addColorStop(0, Qt.rgba(root.lineColor.r, root.lineColor.g, root.lineColor.b, 0.35));
            grad.addColorStop(1, Qt.rgba(root.lineColor.r, root.lineColor.g, root.lineColor.b, 0.02));
            ctx.fillStyle = grad;
            ctx.fill();

            // Line.
            ctx.beginPath();
            ctx.moveTo(px(0), py(data[0]));
            for (var b = 1; b < data.length; b++)
                ctx.lineTo(px(b), py(data[b]));
            ctx.strokeStyle = root.lineColor;
            ctx.lineWidth = root.lineWidth;
            ctx.lineJoin = "round";
            ctx.lineCap = "round";
            ctx.stroke();
        }
    }
}
