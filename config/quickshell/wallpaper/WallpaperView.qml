import Quickshell
import Quickshell.Wayland
import QtQuick
import "../services" as Svc

// Background wallpaper surface for one monitor, with GPU shader transitions.
PanelWindow {
    id: root

    required property var modelData
    screen: modelData

    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "quickshell-wallpaper"

    anchors { top: true; bottom: true; left: true; right: true }
    // -1 = span the whole output, ignoring other surfaces' exclusive zones
    // (so the wallpaper also covers the area behind the bar).
    exclusiveZone: -1
    color: Svc.Theme.base

    // ---- Transition config ---------------------------------------------------
    // Available modes (match the fragment shader):
    //   0 fade, 1 wipe, 2 circle reveal, 3 dissolve, 4 slide
    readonly property var transitionModes: [0, 1, 2, 3, 4]
    // Lock one effect by index, or -1 to pick a random one on each change.
    property int forcedMode: -1
    property int transitionDuration: 900

    // ---- Internal transition state ------------------------------------------
    // Two texture layers. `curSrc` is what's currently shown; `nextSrc` is the
    // incoming wallpaper. The shader blends cur -> next as progress 0 -> 1.
    property string curSrc: ""
    property string nextSrc: ""

    property int   activeMode: 0
    property real  revealX: 0.5
    property real  revealY: 0.5
    property real  dissolveSeed: 0.0
    property bool  animating: false

    function _pickMode() {
        if (forcedMode >= 0)
            return forcedMode;
        return transitionModes[Math.floor(Math.random() * transitionModes.length)];
    }

    // Load a new wallpaper into the "next" layer and prepare a transition.
    function apply(src) {
        if (!src || src === curSrc)
            return;

        // If a transition is mid-flight, snap it to done first so we don't lose
        // the intermediate state, then start the new one from the settled image.
        if (animating)
            _commit();

        activeMode = _pickMode();
        revealX = Math.random();
        revealY = Math.random();
        dissolveSeed = Math.random() * 100.0;

        nextSrc = src; // triggers imgNext to load; onReady starts the animation
    }

    // Start the blend once the incoming image is decoded.
    function _begin() {
        anim.stop();
        fx.progress = 0.0;
        anim.start();
    }

    // Settle: the "next" image becomes the current one, progress resets to 0.
    function _commit() {
        anim.stop();
        animating = false;
        if (nextSrc !== "")
            curSrc = nextSrc;
        fx.progress = 0.0;
    }

    Connections {
        target: Svc.Wallpaper
        function onCurrentChanged() { root.apply(Svc.Wallpaper.current); }
    }

    Component.onCompleted: {
        if (Svc.Wallpaper.current !== "")
            curSrc = Svc.Wallpaper.current;
    }

    // ---- Image layers (rendered off-screen, fed to the shader) --------------
    Image {
        id: imgCur
        anchors.fill: parent
        visible: false
        source: root.curSrc
        fillMode: Image.PreserveAspectCrop
        cache: false
        asynchronous: true
        sourceSize.width: root.screen ? root.screen.width : 1920
        sourceSize.height: root.screen ? root.screen.height : 1080
    }

    Image {
        id: imgNext
        anchors.fill: parent
        visible: false
        source: root.nextSrc
        fillMode: Image.PreserveAspectCrop
        cache: false
        asynchronous: true
        sourceSize.width: root.screen ? root.screen.width : 1920
        sourceSize.height: root.screen ? root.screen.height : 1080
        onStatusChanged: {
            if (status === Image.Ready && root.nextSrc !== ""
                    && root.nextSrc !== root.curSrc && !root.animating) {
                root.animating = true;
                root._begin();
            }
        }
    }

    ShaderEffectSource {
        id: srcCur
        sourceItem: imgCur
        live: true
        hideSource: true
        visible: false
    }
    ShaderEffectSource {
        id: srcNext
        sourceItem: imgNext
        live: true
        hideSource: true
        visible: false
    }

    // ---- Transition shader ---------------------------------------------------
    ShaderEffect {
        id: fx
        anchors.fill: parent

        // 0 -> shows the current image; 1 -> shows the next image.
        property real progress: 0.0

        property var oldTex: srcCur
        property var newTex: srcNext

        property real mode: root.activeMode
        property real aspect: width / Math.max(1, height)
        property vector2d center: Qt.vector2d(root.revealX, root.revealY)
        property real seed: root.dissolveSeed

        fragmentShader: Qt.resolvedUrl("shaders/transition.frag.qsb")
    }

    NumberAnimation {
        id: anim
        target: fx
        property: "progress"
        from: 0.0
        to: 1.0
        duration: root.transitionDuration
        easing.type: Easing.InOutCubic
        onFinished: root._commit()
    }
}
