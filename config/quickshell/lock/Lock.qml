import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam
import QtQuick
import QtQuick.Effects
import "../services" as Svc

// Native Wayland session lock (ext-session-lock), styled to match the shell.
// Replaces the external hyprlock: blurred wallpaper, large clock, greeting and
// a PAM-backed password field. Engage via Svc.Lock.locked (see IPC "lock").
// NOTE: WlSessionLock's default property is `surface` (a single Component), so
// any non-surface child placed directly inside it (PamContext, SystemClock, …)
// is swallowed by that property and never instantiated. We therefore wrap
// everything in a Scope and nest the WlSessionLock inside it, keeping the
// PamContext and shared state as real sibling objects.
Scope {
    id: lock

    // Shared auth state across all per-monitor surfaces.
    property string password: ""
    property bool authenticating: false
    property bool failed: false
    property int attempts: 0

    PamContext {
        id: pam
        config: "login"

        // When PAM asks for the password, hand over the buffered input.
        onResponseRequiredChanged: {
            if (responseRequired)
                respond(lock.password);
        }

        onCompleted: result => {
            if (result === PamResult.Success) {
                lock.failed = false;
                lock.attempts = 0;
                lock.password = "";
                lock.authenticating = false;
                Svc.Lock.unlock();
            } else {
                lock.failed = true;
                lock.attempts += 1;
                lock.password = "";
                lock.authenticating = false;
            }
        }
        onError: {
            lock.failed = true;
            lock.authenticating = false;
            lock.password = "";
        }
    }

    function authenticate() {
        if (lock.authenticating || lock.password.length === 0)
            return;
        lock.authenticating = true;
        lock.failed = false;
        pam.start();
    }

    WlSessionLock {
        id: session
        locked: Svc.Lock.locked

        // Reset transient state each time we (re)lock.
        onLockedChanged: {
            if (locked) {
                lock.password = "";
                lock.failed = false;
                lock.authenticating = false;
                lock.attempts = 0;
            }
        }

    WlSessionLockSurface {
        id: surface
        color: Svc.Theme.base

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
            blur: 1.0
            blurMax: 48
            brightness: -0.25
            saturation: -0.1
        }
        // Dim overlay (and fallback when no wallpaper is set).
        Rectangle {
            anchors.fill: parent
            color: wall.status === Image.Ready ? "#55000000" : Svc.Theme.base
        }

        // ---- Big clock ------------------------------------------------------
        Column {
            id: clockColumn
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: parent.height * 0.18
            spacing: 2

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDateTime(clock.date, "h:mm")
                font.family: Svc.Theme.fontFamily
                font.pixelSize: 112
                font.weight: Font.DemiBold
                color: "#ffffff"
                style: Text.Raised
                styleColor: "#40000000"
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDateTime(clock.date, "dddd, d MMMM")
                font.family: Svc.Theme.fontFamily
                font.pixelSize: 22
                color: "#e0ffffff"
            }
        }

        // ---- Auth card ------------------------------------------------------
        Column {
            id: card
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: parent.height * 0.14
            spacing: 18
            width: 360

            // Avatar: user photo, circularly masked with an accent ring.
            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 96
                height: 96

                Image {
                    id: avatarImg
                    anchors.fill: parent
                    source: "file:///home/blas/archlinux/Blas_Cartoon-Round.png"
                    fillMode: Image.PreserveAspectCrop
                    cache: true
                    smooth: true
                    mipmap: true
                    sourceSize.width: 192
                    sourceSize.height: 192
                    visible: false
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

                // Fallback (initial) if the image fails to load.
                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    visible: avatarImg.status !== Image.Ready
                    color: Svc.Theme.surface0
                    Text {
                        anchors.centerIn: parent
                        text: (Svc.SysInfo.user || "?").charAt(0).toUpperCase()
                        font.family: Svc.Theme.fontFamily
                        font.pixelSize: 44
                        font.bold: true
                        color: Svc.Theme.accent
                    }
                }

                // Accent ring.
                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: "transparent"
                    border.color: Svc.Theme.accent
                    border.width: 2
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Svc.SysInfo.user || "user"
                font.family: Svc.Theme.fontFamily
                font.pixelSize: 18
                color: "#ffffff"
            }

            // Password field (pill).
            Rectangle {
                id: field
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width
                height: 50
                radius: height / 2
                color: Svc.Theme.inputBg
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
                    font.pixelSize: 18
                    color: Svc.Theme.subtext
                }

                TextInput {
                    id: input
                    anchors.fill: parent
                    anchors.leftMargin: 52
                    anchors.rightMargin: 20
                    verticalAlignment: TextInput.AlignVCenter
                    echoMode: TextInput.Password
                    passwordCharacter: "•"
                    font.family: Svc.Theme.fontFamily
                    font.pixelSize: 18
                    color: Svc.Theme.text
                    clip: true
                    enabled: !lock.authenticating
                    focus: true

                    onTextChanged: {
                        lock.password = text;
                        if (lock.failed) lock.failed = false;
                    }
                    onAccepted: lock.authenticate()

                    // Keep the binding in sync when the buffer is cleared.
                    Connections {
                        target: lock
                        function onPasswordChanged() {
                            if (lock.password !== input.text)
                                input.text = lock.password;
                        }
                    }

                    Text {
                        anchors.fill: parent
                        verticalAlignment: Text.AlignVCenter
                        visible: input.text.length === 0 && !lock.authenticating
                        text: "Enter password"
                        font: input.font
                        color: Svc.Theme.subtext
                    }
                }

                // Busy spinner while authenticating.
                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: 18
                    anchors.verticalCenter: parent.verticalCenter
                    visible: lock.authenticating
                    text: String.fromCodePoint(0xF0772) // loading glyph
                    font.family: Svc.Theme.iconFont
                    font.pixelSize: 18
                    color: Svc.Theme.accent
                    RotationAnimation on rotation {
                        running: lock.authenticating
                        loops: Animation.Infinite
                        from: 0; to: 360; duration: 900
                    }
                }
            }

            // Status line.
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                height: 18
                text: lock.failed
                    ? ("Incorrect password" + (lock.attempts > 1 ? "  (" + lock.attempts + ")" : ""))
                    : (lock.authenticating ? "Authenticating…" : "")
                font.family: Svc.Theme.fontFamily
                font.pixelSize: 13
                color: lock.failed ? Svc.Theme.danger : Svc.Theme.subtext
            }
        }

        // Make sure the field grabs the keyboard when the lock appears.
        Component.onCompleted: input.forceActiveFocus()
        onVisibleChanged: if (visible) input.forceActiveFocus()
    }
    }
}
