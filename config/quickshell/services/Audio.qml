pragma Singleton

import Quickshell
import Quickshell.Services.Pipewire
import QtQuick

// PipeWire audio frontend: default output (sink) + input (source) control,
// plus device switching.
Singleton {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property bool ready: Pipewire.ready

    // ---- Output (sink) -------------------------------------------------------
    readonly property real sinkVolume: sink && sink.audio ? sink.audio.volume : 0
    readonly property bool sinkMuted: sink && sink.audio ? sink.audio.muted : true

    // ---- Input (source) ------------------------------------------------------
    readonly property real sourceVolume: source && source.audio ? source.audio.volume : 0
    readonly property bool sourceMuted: source && source.audio ? source.audio.muted : true

    // ---- Device lists (for switching) ---------------------------------------
    readonly property var sinks: filterNodes("Audio/Sink")
    readonly property var sources: filterNodes("Audio/Source")

    function filterNodes(mediaClass) {
        var out = [];
        var n = Pipewire.nodes ? Pipewire.nodes.values : [];
        for (var i = 0; i < n.length; i++) {
            if (n[i].isStream)
                continue;
            var mc = n[i].properties ? n[i].properties["media.class"] : "";
            if (mc === mediaClass)
                out.push(n[i]);
        }
        return out;
    }

    // ---- Actions -------------------------------------------------------------
    function setSinkVolume(v) {
        if (sink && sink.audio)
            sink.audio.volume = Math.max(0, Math.min(v, 1.0));
    }
    function setSourceVolume(v) {
        if (source && source.audio)
            source.audio.volume = Math.max(0, Math.min(v, 1.0));
    }
    function toggleSinkMute() {
        if (sink && sink.audio)
            sink.audio.muted = !sink.audio.muted;
    }
    function toggleSourceMute() {
        if (source && source.audio)
            source.audio.muted = !source.audio.muted;
    }
    function stepSink(delta) {
        setSinkVolume(sinkVolume + delta);
    }
    function setDefaultSink(node) {
        Pipewire.preferredDefaultAudioSink = node;
    }
    function setDefaultSource(node) {
        Pipewire.preferredDefaultAudioSource = node;
    }

    // ---- Icon helpers --------------------------------------------------------
    function sinkIcon() {
        if (sinkMuted || sinkVolume <= 0)
            return String.fromCodePoint(0xF0581); // volume-off
        if (sinkVolume < 0.34)
            return String.fromCodePoint(0xF057F); // volume-low
        if (sinkVolume < 0.67)
            return String.fromCodePoint(0xF0580); // volume-medium
        return String.fromCodePoint(0xF057E);      // volume-high
    }
    function sourceIcon() {
        return String.fromCodePoint(sourceMuted ? 0xF036D : 0xF036C); // mic / mic-off
    }

    // Keep default nodes tracked so their audio props stay live.
    PwObjectTracker {
        objects: {
            var o = [];
            if (root.sink) o.push(root.sink);
            if (root.source) o.push(root.source);
            return o;
        }
    }
}
