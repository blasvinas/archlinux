import QtQuick
import "../../services" as Svc

// Self-contained month calendar with navigation. No external deps.
Column {
    id: root

    // Currently displayed month.
    property int viewYear
    property int viewMonth   // 0-11

    // "Today" for highlighting, refreshed when shown.
    property var today: new Date()

    readonly property var monthNames: [
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
    ]
    readonly property var dayNames: ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]

    function resetToToday() {
        today = new Date();
        viewYear = today.getFullYear();
        viewMonth = today.getMonth();
    }

    function prevMonth() {
        if (viewMonth === 0) { viewMonth = 11; viewYear--; }
        else viewMonth--;
    }
    function nextMonth() {
        if (viewMonth === 11) { viewMonth = 0; viewYear++; }
        else viewMonth++;
    }

    // 42 cells (6 weeks) including leading/trailing days from adjacent months.
    readonly property var cells: {
        var y = viewYear, m = viewMonth;
        var startDow = new Date(y, m, 1).getDay();
        var daysInMonth = new Date(y, m + 1, 0).getDate();
        var daysPrev = new Date(y, m, 0).getDate();
        var out = [];
        for (var i = 0; i < startDow; i++)
            out.push({ day: daysPrev - startDow + 1 + i, inMonth: false });
        for (var d = 1; d <= daysInMonth; d++)
            out.push({ day: d, inMonth: true });
        var next = 1;
        while (out.length < 42)
            out.push({ day: next++, inMonth: false });
        return out;
    }

    Component.onCompleted: resetToToday()

    spacing: 8

    // ---- Header: month navigation --------------------------------------------
    Item {
        width: parent.width
        height: 26

        Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: String.fromCodePoint(0xF0141) // chevron-left
            font.family: Svc.Theme.iconFont
            font.pixelSize: 18
            color: prevHover.hovered ? Svc.Theme.accent : Svc.Theme.subtext
            HoverHandler { id: prevHover }
            MouseArea {
                anchors.fill: parent
                anchors.margins: -6
                cursorShape: Qt.PointingHandCursor
                onClicked: root.prevMonth()
            }
        }

        Text {
            anchors.centerIn: parent
            text: root.monthNames[root.viewMonth] + " " + root.viewYear
            color: Svc.Theme.text
            font.pixelSize: 14
            font.bold: true
        }

        Text {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: String.fromCodePoint(0xF0142) // chevron-right
            font.family: Svc.Theme.iconFont
            font.pixelSize: 18
            color: nextHover.hovered ? Svc.Theme.accent : Svc.Theme.subtext
            HoverHandler { id: nextHover }
            MouseArea {
                anchors.fill: parent
                anchors.margins: -6
                cursorShape: Qt.PointingHandCursor
                onClicked: root.nextMonth()
            }
        }
    }

    // ---- Weekday header ------------------------------------------------------
    Row {
        width: parent.width
        Repeater {
            model: root.dayNames
            delegate: Item {
                required property var modelData
                width: root.width / 7
                height: 20
                Text {
                    anchors.centerIn: parent
                    text: modelData
                    color: Svc.Theme.subtext
                    font.pixelSize: 11
                    font.bold: true
                }
            }
        }
    }

    // ---- Day grid ------------------------------------------------------------
    Grid {
        width: parent.width
        columns: 7

        Repeater {
            model: root.cells
            delegate: Item {
                required property var modelData
                width: root.width / 7
                height: root.width / 7

                readonly property bool isToday: modelData.inMonth
                    && root.viewYear === root.today.getFullYear()
                    && root.viewMonth === root.today.getMonth()
                    && modelData.day === root.today.getDate()

                Rectangle {
                    anchors.centerIn: parent
                    width: 28
                    height: 28
                    radius: Svc.Theme.radiusPill
                    color: isToday ? Svc.Theme.accent : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: modelData.day
                        font.pixelSize: 12
                        font.bold: isToday
                        color: isToday ? Svc.Theme.crust
                             : modelData.inMonth ? Svc.Theme.text
                             : Svc.Theme.muted
                    }
                }
            }
        }
    }
}
