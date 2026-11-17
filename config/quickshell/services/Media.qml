pragma Singleton

import Quickshell
import Quickshell.Services.Mpris
import QtQuick

// Thin wrapper over the MPRIS service that exposes a single "active" player
// (preferring one that is currently playing) plus formatting helpers, so the
// dashboard / bar don't have to reason about the player list.
Singleton {
    id: root

    readonly property var players: Mpris.players ? Mpris.players.values : []
    readonly property bool hasPlayer: active !== null

    // Pick the first playing player, otherwise the first available one.
    readonly property var active: {
        var list = players;
        if (!list || list.length === 0)
            return null;
        for (var i = 0; i < list.length; i++)
            if (list[i].isPlaying)
                return list[i];
        return list[0];
    }

    readonly property bool isPlaying: active ? active.isPlaying : false
    readonly property string title: active && active.trackTitle ? active.trackTitle : ""
    readonly property string artist: active && active.trackArtist ? active.trackArtist : ""
    readonly property string album: active && active.trackAlbum ? active.trackAlbum : ""
    readonly property string artUrl: active && active.trackArtUrl ? active.trackArtUrl : ""

    readonly property bool canPlay: active ? active.canPlay : false
    readonly property bool canPause: active ? active.canPause : false
    readonly property bool canNext: active ? active.canGoNext : false
    readonly property bool canPrev: active ? active.canGoPrevious : false

    readonly property bool lengthSupported: active ? active.lengthSupported : false
    readonly property bool positionSupported: active ? active.positionSupported : false
    readonly property real length: active && active.lengthSupported ? active.length : 0
    readonly property real position: active && active.positionSupported ? active.position : 0
    readonly property real progress: length > 0 ? Math.min(1, position / length) : 0

    function toggle() { if (active) active.togglePlaying(); }
    function next() { if (active && active.canGoNext) active.next(); }
    function previous() { if (active && active.canGoPrevious) active.previous(); }
    function seek(fraction) {
        if (active && active.lengthSupported && active.positionSupported)
            active.position = Math.max(0, Math.min(1, fraction)) * active.length;
    }

    function fmtTime(seconds) {
        if (!seconds || seconds < 0)
            seconds = 0;
        var s = Math.floor(seconds);
        var h = Math.floor(s / 3600);
        var m = Math.floor((s % 3600) / 60);
        var sec = s % 60;
        function pad(n) { return (n < 10 ? "0" : "") + n; }
        if (h > 0)
            return h + ":" + pad(m) + ":" + pad(sec);
        return m + ":" + pad(sec);
    }

    // Drives live position updates for the scrubber while playing.
    Timer {
        interval: 1000
        running: root.isPlaying && root.positionSupported
        repeat: true
        onTriggered: {
            if (root.active)
                root.active.positionChanged();
        }
    }
}
