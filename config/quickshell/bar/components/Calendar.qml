import QtQuick
import "../../services" as Svc

// Self-contained month calendar with navigation, week numbers, day selection
// and a footer. No external deps.
Column {
    id: root

    // Currently displayed month.
    property int viewYear
    property int viewMonth   // 0-11

    // "Today" for highlighting, refreshed when shown.
    property var today: new Date()
    // Selected day (null = none). Shown in the footer.
    property var selected: null

    property bool showWeekNumbers: true

    readonly property var monthNames: [
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
    ]
    readonly property var fullDayNames: [
        "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"
    ]
    readonly property var dayNames: ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]

    readonly property real weekNumW: showWeekNumbers ? 22 : 0
    readonly property real dayColW: (width - weekNumW) / 7
    readonly property bool onCurrentMonth: viewYear === today.getFullYear()
                                           && viewMonth === today.getMonth()

    function resetToToday() {
        today = new Date();
        viewYear = today.getFullYear();
        viewMonth = today.getMonth();
        selected = null;
    }

    function prevMonth() {
        if (viewMonth === 0) { viewMonth = 11; viewYear--; }
        else viewMonth--;
    }
    function nextMonth() {
        if (viewMonth === 11) { viewMonth = 0; viewYear++; }
        else viewMonth++;
    }

    function sameDay(a, b) {
        return a && b && a.getFullYear() === b.getFullYear()
            && a.getMonth() === b.getMonth() && a.getDate() === b.getDate();
    }

    // ISO-8601 week number for a given date.
    function isoWeek(date) {
        var d = new Date(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()));
        var dayNum = (d.getUTCDay() + 6) % 7;      // Mon=0 … Sun=6
        d.setUTCDate(d.getUTCDate() - dayNum + 3);  // nearest Thursday
        var firstThursday = d.getTime();
        d.setUTCMonth(0, 1);
        if (d.getUTCDay() !== 4)
            d.setUTCMonth(0, 1 + ((4 - d.getUTCDay()) + 7) % 7);
        return 1 + Math.round((firstThursday - d.getTime()) / 604800000);
    }

    // 6 weeks, each with a week number and 7 real-date cells.
    readonly property var weeks: {
        var y = viewYear, m = viewMonth;
        var startDow = new Date(y, m, 1).getDay();      // 0 = Sunday
        var start = new Date(y, m, 1 - startDow);        // date of first cell
        var out = [];
        for (var w = 0; w < 6; w++) {
            var days = [];
            for (var i = 0; i < 7; i++) {
                var dt = new Date(start.getFullYear(), start.getMonth(),
                                  start.getDate() + w * 7 + i);
                days.push({ date: dt, day: dt.getDate(),
                            inMonth: dt.getMonth() === m,
                            weekend: (i === 0 || i === 6) });
            }
            out.push({ weekNo: isoWeek(days[4].date), days: days });
        }
        return out;
    }

    Component.onCompleted: resetToToday()

    spacing: 8

    // Change months by scrolling anywhere over the calendar.
    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => { if (event.angleDelta.y < 0) root.nextMonth(); else root.prevMonth(); }
    }

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
            id: title
            font.family: Svc.Theme.fontFamily
            anchors.centerIn: parent
            text: root.monthNames[root.viewMonth] + " " + root.viewYear
            color: titleHover.hovered ? Svc.Theme.accent : Svc.Theme.text
            font.pixelSize: 14
            font.bold: true
            HoverHandler { id: titleHover }
            MouseArea {
                anchors.fill: parent
                anchors.margins: -6
                cursorShape: Qt.PointingHandCursor
                onClicked: root.resetToToday()   // tap title to jump to today
            }
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

        // Spacer above the week-number column.
        Item { width: root.weekNumW; height: 20; visible: root.showWeekNumbers }

        Repeater {
            model: root.dayNames
            delegate: Item {
                required property var modelData
                required property int index
                width: root.dayColW
                height: 20
                Text {
                    font.family: Svc.Theme.fontFamily
                    anchors.centerIn: parent
                    text: modelData
                    color: (index === 0 || index === 6) ? Svc.Theme.accent : Svc.Theme.subtext
                    font.pixelSize: 11
                    font.bold: true
                }
            }
        }
    }

    // ---- Week rows -----------------------------------------------------------
    Repeater {
        model: root.weeks
        delegate: Row {
            required property var modelData
            width: root.width

            // Week number.
            Item {
                width: root.weekNumW
                height: root.dayColW
                visible: root.showWeekNumbers
                Text {
                    anchors.centerIn: parent
                    text: modelData.weekNo
                    font.family: Svc.Theme.fontFamily
                    font.pixelSize: 9
                    color: Svc.Theme.muted
                }
            }

            Repeater {
                model: modelData.days
                delegate: Item {
                    required property var modelData
                    width: root.dayColW
                    height: root.dayColW

                    readonly property bool isToday: modelData.inMonth && root.sameDay(modelData.date, root.today)
                    readonly property bool isSelected: root.sameDay(modelData.date, root.selected)

                    Rectangle {
                        anchors.centerIn: parent
                        width: Math.min(30, parent.width - 2)
                        height: width
                        radius: Svc.Theme.radiusPill
                        color: isToday ? Svc.Theme.accent
                             : dayHover.hovered ? Svc.Theme.hover
                             : "transparent"
                        border.width: (isSelected && !isToday) ? 1.5 : 0
                        border.color: Svc.Theme.accent

                        Text {
                            font.family: Svc.Theme.fontFamily
                            anchors.centerIn: parent
                            text: modelData.day
                            font.pixelSize: 12
                            font.bold: isToday || isSelected
                            color: isToday ? Svc.Theme.crust
                                 : !modelData.inMonth ? Svc.Theme.muted
                                 : modelData.weekend ? Svc.Theme.subtext
                                 : Svc.Theme.text
                        }

                        HoverHandler { id: dayHover }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.selected = root.sameDay(modelData.date, root.selected)
                                ? null : modelData.date
                        }
                    }
                }
            }
        }
    }

    // ---- Footer: selected / today --------------------------------------------
    Item {
        width: parent.width
        height: 1
        Rectangle { width: parent.width; height: 1; color: Svc.Theme.hi }
    }

    Item {
        width: parent.width
        height: 20

        Text {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.rightMargin: root.onCurrentMonth ? 0 : 60
            anchors.verticalCenter: parent.verticalCenter
            elide: Text.ElideRight
            property var d: root.selected ? root.selected : root.today
            text: (root.selected ? "" : "Today · ")
                + root.fullDayNames[d.getDay()] + ", "
                + d.getDate() + " " + root.monthNames[d.getMonth()] + " " + d.getFullYear()
            font.family: Svc.Theme.fontFamily
            font.pixelSize: 11
            color: Svc.Theme.subtext
        }

        // "Today" pill — jump back when viewing another month.
        Rectangle {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            visible: !root.onCurrentMonth
            width: todayLabel.implicitWidth + 16
            height: 18
            radius: height / 2
            color: todayPillHover.hovered ? Svc.Theme.accent : "transparent"
            border.width: 1
            border.color: Svc.Theme.accent
            Text {
                id: todayLabel
                anchors.centerIn: parent
                text: "Today"
                font.family: Svc.Theme.fontFamily
                font.pixelSize: 10
                font.bold: true
                color: todayPillHover.hovered ? Svc.Theme.crust : Svc.Theme.accent
            }
            HoverHandler { id: todayPillHover }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.resetToToday()
            }
        }
    }
}
