import Quickshell
import Quickshell.Wayland
import QtQuick
import "../services" as Svc

// Background wallpaper surface for one monitor, with crossfade transitions.
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

    // Two layers we crossfade between.
    property bool showA: true

    function apply(src) {
        if (showA) { imgB.source = src; showA = false; }
        else       { imgA.source = src; showA = true; }
    }

    Connections {
        target: Svc.Wallpaper
        function onCurrentChanged() { root.apply(Svc.Wallpaper.current); }
    }

    Component.onCompleted: {
        if (Svc.Wallpaper.current !== "") {
            imgA.source = Svc.Wallpaper.current;
            showA = true;
        }
    }

    Image {
        id: imgA
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        cache: false
        asynchronous: true
        sourceSize.width: root.screen ? root.screen.width : 1920
        sourceSize.height: root.screen ? root.screen.height : 1080
        opacity: root.showA ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.InOutQuad } }
    }

    Image {
        id: imgB
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        cache: false
        asynchronous: true
        sourceSize.width: root.screen ? root.screen.width : 1920
        sourceSize.height: root.screen ? root.screen.height : 1080
        opacity: root.showA ? 0 : 1
        Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.InOutQuad } }
    }
}
