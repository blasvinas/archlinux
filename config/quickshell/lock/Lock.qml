import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import QtQuick
import QtQuick.Effects
import "../services" as Svc

// Native Wayland session lock (ext-session-lock), styled to match the shell.
// Blurred wallpaper, large clock + weather, PAM-backed password field, caps-lock
// warning, media controls, battery and power actions. Engage via
// Svc.Lock.locked (see IPC "lock").
//
// NOTE: WlSessionLock's default property is `surface` (a single Component), so
// any non-surface child placed directly inside it (PamContext, Timer, …) is
// swallowed by that property and never instantiated. We therefore wrap
// everything in a Scope and nest the WlSessionLock inside it, keeping the
// PamContext and shared state as real sibling objects.
Scope {
    id: lock

    // ---- Shared state across all per-monitor surfaces ----------------------
    property string password: ""
    property bool authenticating: false
    property bool failed: false
    property int attempts: 0
    property string errorText: ""      // last PAM error / failure reason
    property string infoText: ""       // non-error PAM message (e.g. fingerprint)
    property bool capsLock: false
    property bool unlocking: false     // true while the unlock animation runs

    readonly property string userName: Quickshell.env("USER") || Svc.SysInfo.user || "user"
    readonly property string home: Quickshell.env("HOME")

    function reset() {
        lock.password = "";
        lock.failed = false;
        lock.authenticating = false;
        lock.attempts = 0;
        lock.errorText = "";
        lock.infoText = "";
        lock.unlocking = false;
    }

    function fail(reason) {
        lock.failed = true;
        lock.attempts += 1;
        lock.errorText = reason;
        lock.infoText = "";
        lock.password = "";
        lock.authenticating = false;
    }

    function authenticate() {
        if (lock.authenticating || lock.unlocking || lock.password.length === 0)
            return;
        lock.authenticating = true;
        lock.failed = false;
        lock.errorText = "";
        pam.start();
    }

    PamContext {
        id: pam
        config: "login"

        // When PAM asks for the password, hand over the buffered input.
        onResponseRequiredChanged: {
            if (responseRequired)
                respond(lock.password);
        }

        // Surface PAM's own messages (faillock lockouts, fingerprint prompts…).
        onMessageChanged: {
            if (!message)
                return;
            if (messageIsError)
                lock.errorText = message;
            else if (!responseRequired)
                lock.infoText = message;
        }

        onCompleted: result => {
            if (result === PamResult.Success) {
                lock.failed = false;
                lock.password = "";
                lock.authenticating = false;
                lock.infoText = "";
                lock.unlocking = true;   // play the reveal animation, then unlock
                unlockTimer.restart();
            } else {
                lock.fail(lock.errorText.length > 0 ? lock.errorText : "Incorrect password");
            }
        }
        onError: lock.fail("Authentication error")
    }

    // Give the surfaces time to animate out before releasing the lock.
    Timer {
        id: unlockTimer
        interval: 380
        onTriggered: {
            Svc.Lock.unlock();
            lock.unlocking = false;
        }
    }

    // Caps-lock state from the keyboard LED (Qt doesn't expose it directly).
    Process {
        id: capsProc
        command: ["sh", "-c", "cat /sys/class/leds/*::capslock/brightness 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: lock.capsLock = text.split("\n").some(l => l.trim().length > 0 && l.trim() !== "0")
        }
    }
    Timer {
        interval: 400
        repeat: true
        running: Svc.Lock.locked
        triggeredOnStart: true
        onTriggered: if (!capsProc.running) capsProc.running = true
    }

    WlSessionLock {
        id: session
        locked: Svc.Lock.locked

        // Reset transient state each time we (re)lock.
        onLockedChanged: if (locked) lock.reset()

    WlSessionLockSurface {
        id: surface
        color: "black"

        // 0 → 1 as the lock appears, back to 0 on successful unlock. Drives the
        // blur, dimming and UI fade so the wallpaper "un-blurs" into the desktop.
        property real reveal: 0
        NumberAnimation on reveal {
            id: revealIn
            from: 0; to: 1
            duration: 450
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            id: revealOut
            target: surface
            property: "reveal"
            to: 0
            duration: 350
            easing.type: Easing.InCubic
        }
        Connections {
            target: lock
            function onUnlockingChanged() {
                if (lock.unlocking) { revealIn.stop(); revealOut.restart(); }
            }
            function onAttemptsChanged() {
                if (lock.failed) shakeAnim.restart();
            }
            function onPasswordChanged() {
                if (lock.password !== input.text)
                    input.text = lock.password;
            }
        }

        // Per-surface clock (ids from the WlSessionLock root scope are not
        // visible inside this component, so declare it here).
        SystemClock { id: clock; precision: SystemClock.Seconds }

        // ---- Blurred wallpaper backdrop -------------------------------------
        Image {
            id: wall
            anchors.fill: parent
            source: Svc.Wallpaper.current ? "file://" + Svc.Wallpaper.current : ""
            fillMode: Image.PreserveAspectCrop
            cache: true
            asynchronous: true
            visible: false
            sourceSize.width: surface.screen ? surface.screen.width : 1920
            sourceSize.height: surface.screen ? surface.screen.height : 1080
        }
        MultiEffect {
            anchors.fill: parent
            source: wall
            visible: wall.status === Image.Ready
            blurEnabled: true
            blur: surface.reveal
            blurMax: 48
            brightness: -0.25 * surface.reveal
            saturation: -0.1 * surface.reveal
        }
        // Dim overlay (and fallback when no wallpaper is set).
        Rectangle {
            anchors.fill: parent
            color: wall.status === Image.Ready ? "#000000" : Svc.Theme.base
            opacity: wall.status === Image.Ready ? 0.33 * surface.reveal : 1
        }

        // Clicking anywhere returns focus to the password field.
        MouseArea {
            anchors.fill: parent
            onClicked: input.forceActiveFocus()
        }

        // ---- Foreground UI (fades/slides with `reveal`) ---------------------
        Item {
            id: ui
            anchors.fill: parent
            opacity: surface.reveal
            transform: Translate { y: (1 - surface.reveal) * 24 }

            // ---- Big clock + date + weather ---------------------------------
            Column {
                id: clockColumn
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: parent.height * 0.14
                spacing: 4

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 10
                    Text {
                        id: timeText
                        text: Qt.formatDateTime(clock.date, "h:mm")
                        font.family: Svc.Theme.fontFamily
                        font.pixelSize: Svc.Theme.fontJumbo
                        font.weight: Font.DemiBold
                        color: "#ffffff"
                        style: Text.Raised
                        styleColor: "#40000000"
                    }
                    Text {
                        anchors.baseline: timeText.baseline
                        text: Qt.formatDateTime(clock.date, "AP")
                        font.family: Svc.Theme.fontFamily
                        font.pixelSize: Svc.Theme.fontHero
                        font.weight: Font.Medium
                        color: "#c0ffffff"
                    }
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDateTime(clock.date, "dddd, d MMMM")
                    font.family: Svc.Theme.fontFamily
                    font.pixelSize: Svc.Theme.font3xl
                    color: "#e0ffffff"
                }
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 8
                    visible: Svc.Weather.ready
                    topPadding: 6
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Svc.Weather.currentIcon()
                        font.family: Svc.Theme.iconFont
                        font.pixelSize: Svc.Theme.font3xl
                        color: Svc.Theme.accent
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Svc.Weather.temp + Svc.Weather.unit + "  ·  " + Svc.Weather.description
                        font.family: Svc.Theme.fontFamily
                        font.pixelSize: Svc.Theme.fontXl
                        color: "#d0ffffff"
                    }
                }
            }

            // ---- Auth card --------------------------------------------------
            Column {
                id: card
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: parent.height * 0.14
                spacing: 16
                width: 360

                transform: Translate { id: shake }
                SequentialAnimation {
                    id: shakeAnim
                    NumberAnimation { target: shake; property: "x"; to: -14; duration: 50 }
                    NumberAnimation { target: shake; property: "x"; to: 12;  duration: 70 }
                    NumberAnimation { target: shake; property: "x"; to: -8;  duration: 60 }
                    NumberAnimation { target: shake; property: "x"; to: 5;   duration: 50 }
                    NumberAnimation { target: shake; property: "x"; to: 0;   duration: 40 }
                }

                // Avatar: user photo, circularly masked with an accent ring.
                Item {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 100
                    height: 100

                    // Try the custom portrait first, then ~/.face as a fallback.
                    property var candidates: [
                        "file://" + lock.home + "/archlinux/Blas_Cartoon-Round.png",
                        "file://" + lock.home + "/.face"
                    ]
                    property int candidate: 0

                    Image {
                        id: avatarImg
                        anchors.fill: parent
                        source: parent.candidates[parent.candidate] || ""
                        fillMode: Image.PreserveAspectCrop
                        cache: true
                        smooth: true
                        mipmap: true
                        sourceSize.width: 200
                        sourceSize.height: 200
                        visible: false
                        onStatusChanged: {
                            if (status === Image.Error && parent.candidate < parent.candidates.length - 1)
                                parent.candidate += 1;
                        }
                    }
                    MultiEffect {
                        anchors.fill: parent
                        source: avatarImg
                        maskEnabled: true
                        maskSource: avatarMask
                        visible: avatarImg.status === Image.Ready
                    }
                    Item {
                        id: avatarMask
                        anchors.fill: parent
                        layer.enabled: true
                        visible: false
                        Rectangle {
                            anchors.fill: parent
                            radius: width / 2
                            color: "black"
                        }
                    }

                    // Fallback (initial) if no image loads.
                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        visible: avatarImg.status !== Image.Ready
                        color: Svc.Theme.surface0
                        Text {
                            anchors.centerIn: parent
                            text: lock.userName.charAt(0).toUpperCase()
                            font.family: Svc.Theme.fontFamily
                            font.pixelSize: Svc.Theme.fontDisplay
                            font.bold: true
                            color: Svc.Theme.accent
                        }
                    }

                    // Accent ring (turns red on failure, pulses while authenticating).
                    Rectangle {
                        id: ring
                        anchors.fill: parent
                        anchors.margins: -3
                        radius: width / 2
                        color: "transparent"
                        border.width: 2
                        border.color: lock.failed ? Svc.Theme.danger : Svc.Theme.accent
                        Behavior on border.color { ColorAnimation { duration: 150 } }
                        SequentialAnimation on opacity {
                            running: lock.authenticating
                            loops: Animation.Infinite
                            onRunningChanged: if (!running) ring.opacity = 1
                            NumberAnimation { to: 0.3; duration: 450; easing.type: Easing.InOutSine }
                            NumberAnimation { to: 1.0; duration: 450; easing.type: Easing.InOutSine }
                        }
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: lock.userName
                    font.family: Svc.Theme.fontFamily
                    font.pixelSize: Svc.Theme.font2xl
                    font.weight: Font.Medium
                    color: "#ffffff"
                }

                // Password field (pill).
                Rectangle {
                    id: field
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width
                    height: 50
                    radius: height / 2
                    color: Qt.rgba(Svc.Theme.inputBg.r, Svc.Theme.inputBg.g, Svc.Theme.inputBg.b, 0.85)
                    border.width: 2
                    border.color: lock.failed ? Svc.Theme.danger
                                : input.activeFocus ? Svc.Theme.accent
                                : Svc.Theme.border
                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 20
                        anchors.verticalCenter: parent.verticalCenter
                        text: String.fromCodePoint(0xF033E) // lock glyph
                        font.family: Svc.Theme.iconFont
                        font.pixelSize: Svc.Theme.font2xl
                        color: lock.failed ? Svc.Theme.danger : Svc.Theme.subtext
                    }

                    TextInput {
                        id: input
                        anchors.fill: parent
                        anchors.leftMargin: 52
                        anchors.rightMargin: 52
                        verticalAlignment: TextInput.AlignVCenter
                        echoMode: TextInput.Password
                        passwordCharacter: "●"
                        passwordMaskDelay: 0
                        font.family: Svc.Theme.fontFamily
                        font.pixelSize: Svc.Theme.fontXl
                        font.letterSpacing: 2
                        color: Svc.Theme.text
                        selectionColor: Svc.Theme.accent
                        clip: true
                        enabled: !lock.authenticating && !lock.unlocking
                        focus: true

                        onTextChanged: {
                            lock.password = text;
                            if (lock.failed && text.length > 0) {
                                lock.failed = false;
                                lock.errorText = "";
                            }
                        }
                        onAccepted: lock.authenticate()
                        Keys.onEscapePressed: lock.password = ""

                        Text {
                            anchors.fill: parent
                            verticalAlignment: Text.AlignVCenter
                            visible: input.text.length === 0 && !lock.authenticating
                            text: lock.failed ? "Try again" : "Enter password"
                            font.family: Svc.Theme.fontFamily
                            font.pixelSize: Svc.Theme.fontXl
                            color: Svc.Theme.subtext
                        }
                    }

                    // Right side: spinner while authenticating, else submit arrow.
                    Item {
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        width: 36
                        height: 36

                        Rectangle {
                            anchors.fill: parent
                            radius: width / 2
                            visible: !lock.authenticating
                            color: submitMouse.containsMouse ? Svc.Theme.accent : "transparent"
                            opacity: input.text.length > 0 ? 1 : 0.4
                            Behavior on color { ColorAnimation { duration: 120 } }
                            Text {
                                anchors.centerIn: parent
                                text: String.fromCodePoint(0xF0054) // arrow-right
                                font.family: Svc.Theme.iconFont
                                font.pixelSize: Svc.Theme.font2xl
                                color: submitMouse.containsMouse ? Svc.Theme.accentFg : Svc.Theme.accent
                            }
                            MouseArea {
                                id: submitMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: { lock.authenticate(); input.forceActiveFocus(); }
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: lock.authenticating
                            text: String.fromCodePoint(0xF0772) // loading glyph
                            font.family: Svc.Theme.iconFont
                            font.pixelSize: Svc.Theme.font2xl
                            color: Svc.Theme.accent
                            RotationAnimation on rotation {
                                running: lock.authenticating
                                loops: Animation.Infinite
                                from: 0; to: 360; duration: 900
                            }
                        }
                    }
                }

                // Status line: error / PAM info / caps lock.
                Column {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 6

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        height: 18
                        text: lock.failed
                            ? (lock.errorText + (lock.attempts > 1 ? "  (" + lock.attempts + ")" : ""))
                            : lock.authenticating
                                ? (lock.infoText.length > 0 ? lock.infoText : "Authenticating…")
                                : ""
                        font.family: Svc.Theme.fontFamily
                        font.pixelSize: Svc.Theme.fontMd
                        color: lock.failed ? Svc.Theme.danger : Svc.Theme.subtext
                    }

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: capsRow.implicitWidth + 20
                        height: 26
                        radius: height / 2
                        color: Qt.rgba(Svc.Theme.warning.r, Svc.Theme.warning.g, Svc.Theme.warning.b, 0.18)
                        border.width: 1
                        border.color: Svc.Theme.warning
                        opacity: lock.capsLock ? 1 : 0
                        visible: opacity > 0
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                        Row {
                            id: capsRow
                            anchors.centerIn: parent
                            spacing: 6
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: String.fromCodePoint(0xF0632) // caps-lock
                                font.family: Svc.Theme.iconFont
                                font.pixelSize: Svc.Theme.fontLg
                                color: Svc.Theme.warning
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Caps Lock is on"
                                font.family: Svc.Theme.fontFamily
                                font.pixelSize: Svc.Theme.fontSm
                                color: Svc.Theme.warning
                            }
                        }
                    }
                }
            }

            // ---- Bottom-left: battery ---------------------------------------
            Row {
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                anchors.margins: 28
                spacing: 8
                visible: Svc.Battery.available
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Svc.Battery.batteryIcon()
                    font.family: Svc.Theme.iconFont
                    font.pixelSize: Svc.Theme.font3xl
                    color: Svc.Battery.low ? Svc.Theme.danger
                         : Svc.Battery.charging ? Svc.Theme.success : "#e0ffffff"
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Math.round(Svc.Battery.percent * 100) + "%"
                    font.family: Svc.Theme.fontFamily
                    font.pixelSize: Svc.Theme.fontLg
                    color: "#e0ffffff"
                }
            }

            // ---- Bottom-centre: media controls ------------------------------
            Rectangle {
                id: media
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 28
                visible: Svc.Media.hasPlayer && Svc.Media.title.length > 0
                width: Math.min(460, mediaRow.implicitWidth + 24)
                height: 64
                radius: Svc.Theme.radiusMedium
                color: "#59000000"
                border.width: 1
                border.color: "#22ffffff"

                Row {
                    id: mediaRow
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    spacing: 12

                    Rectangle {
                        width: 44; height: 44
                        radius: 8
                        color: Svc.Theme.surface0
                        clip: true
                        Image {
                            anchors.fill: parent
                            source: Svc.Media.artUrl
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            sourceSize.width: 88
                            sourceSize.height: 88
                        }
                    }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.min(260, Math.max(titleT.implicitWidth, artistT.implicitWidth))
                        Text {
                            id: titleT
                            width: parent.width
                            text: Svc.Media.title
                            elide: Text.ElideRight
                            font.family: Svc.Theme.fontFamily
                            font.pixelSize: Svc.Theme.fontLg
                            font.weight: Font.Medium
                            color: "#ffffff"
                        }
                        Text {
                            id: artistT
                            width: parent.width
                            text: Svc.Media.artist
                            elide: Text.ElideRight
                            visible: text.length > 0
                            font.family: Svc.Theme.fontFamily
                            font.pixelSize: Svc.Theme.fontSm
                            color: "#b0ffffff"
                        }
                    }
                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2
                        Repeater {
                            model: [
                                { glyph: 0xF04AE, action: "prev",   enabled: Svc.Media.canPrev },
                                { glyph: 0,       action: "toggle", enabled: true },
                                { glyph: 0xF04AD, action: "next",   enabled: Svc.Media.canNext }
                            ]
                            delegate: Rectangle {
                                required property var modelData
                                width: 34; height: 34
                                radius: width / 2
                                color: mm.containsMouse && modelData.enabled ? "#33ffffff" : "transparent"
                                opacity: modelData.enabled ? 1 : 0.35
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.action === "toggle"
                                        ? String.fromCodePoint(Svc.Media.isPlaying ? 0xF03E4 : 0xF040A)
                                        : String.fromCodePoint(modelData.glyph)
                                    font.family: Svc.Theme.iconFont
                                    font.pixelSize: modelData.action === "toggle" ? 22 : 18
                                    color: "#ffffff"
                                }
                                MouseArea {
                                    id: mm
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    enabled: parent.modelData.enabled
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        const a = parent.modelData.action;
                                        if (a === "prev") Svc.Media.previous();
                                        else if (a === "next") Svc.Media.next();
                                        else Svc.Media.toggle();
                                        input.forceActiveFocus();
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ---- Bottom-right: power actions (click twice to confirm) -------
            Row {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 24
                spacing: 8

                Repeater {
                    model: [
                        { label: "Suspend",  glyph: 0xF04B2, danger: false, run: () => Svc.Power.suspend() },
                        { label: "Reboot",   glyph: 0xF0709, danger: true,  run: () => Svc.Power.reboot() },
                        { label: "Shutdown", glyph: 0xF0425, danger: true,  run: () => Svc.Power.shutdown() }
                    ]
                    delegate: Rectangle {
                        id: pbtn
                        required property var modelData
                        property bool armed: false
                        width: 44; height: 44
                        radius: width / 2
                        color: armed ? Svc.Theme.danger
                             : pm.containsMouse ? "#33ffffff" : "#26000000"
                        border.width: 1
                        border.color: "#22ffffff"
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Text {
                            anchors.centerIn: parent
                            text: String.fromCodePoint(pbtn.armed ? 0xF012C : pbtn.modelData.glyph)
                            font.family: Svc.Theme.iconFont
                            font.pixelSize: Svc.Theme.font2xl
                            color: pbtn.armed ? Svc.Theme.accentFg : "#e0ffffff"
                        }

                        // Hover tooltip.
                        Rectangle {
                            anchors.bottom: parent.top
                            anchors.bottomMargin: 8
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: tip.implicitWidth + 14
                            height: 24
                            radius: 6
                            color: "#cc000000"
                            visible: pm.containsMouse
                            Text {
                                id: tip
                                anchors.centerIn: parent
                                text: pbtn.armed ? "Click to " + pbtn.modelData.label.toLowerCase() : pbtn.modelData.label
                                font.family: Svc.Theme.fontFamily
                                font.pixelSize: Svc.Theme.fontSm
                                color: "#ffffff"
                            }
                        }

                        Timer {
                            id: disarm
                            interval: 3000
                            onTriggered: pbtn.armed = false
                        }

                        MouseArea {
                            id: pm
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (!pbtn.modelData.danger || pbtn.armed) {
                                    pbtn.armed = false;
                                    pbtn.modelData.run();
                                } else {
                                    pbtn.armed = true;
                                    disarm.restart();
                                }
                                input.forceActiveFocus();
                            }
                        }
                    }
                }
            }
        }

        // Make sure the field grabs the keyboard when the lock appears.
        Component.onCompleted: { input.forceActiveFocus(); revealIn.restart(); }
        onVisibleChanged: if (visible) input.forceActiveFocus()
    }
    }
}
