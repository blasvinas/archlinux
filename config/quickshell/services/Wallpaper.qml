pragma Singleton

import Quickshell
import Quickshell.Io
import Qt.labs.folderlistmodel
import QtQuick

// Wallpaper manager: lists images from a folder, tracks the current wallpaper
// (persisted), and exposes actions. Rendering is done by WallpaperView.
Singleton {
    id: root

    // Source folder (change here or via setFolder()).
    property string folder: Quickshell.env("HOME") + "/wallpapers"

    // Absolute path of the active wallpaper.
    property string current: ""

    // Directory listing model (usable directly as a view model).
    property alias model: fm
    readonly property int count: fm.count

    FolderListModel {
        id: fm
        folder: "file://" + root.folder
        // Add "*.webp" here after installing the qt6-imageformats package.
        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.bmp"]
        showDirs: false
        sortField: FolderListModel.Name
    }

    // ---- Actions -------------------------------------------------------------
    function setWallpaper(path) {
        if (!path || path === current)
            return;
        current = path;
        store.setText(path);
    }
    function setFolder(path) {
        folder = path;
    }
    function random() {
        if (fm.count === 0)
            return;
        var i = Math.floor(Math.random() * fm.count);
        if (fm.get(i, "filePath") === current && fm.count > 1)
            i = (i + 1) % fm.count;
        setWallpaper(fm.get(i, "filePath"));
    }
    function next() {
        if (fm.count === 0)
            return;
        var idx = 0;
        for (var i = 0; i < fm.count; i++)
            if (fm.get(i, "filePath") === current) { idx = i; break; }
        setWallpaper(fm.get((idx + 1) % fm.count, "filePath"));
    }

    // Seed a default once the folder has loaded, if nothing is set yet.
    onCountChanged: {
        if (current === "" && fm.count > 0)
            setWallpaper(fm.get(0, "filePath"));
    }

    // ---- Persistence ---------------------------------------------------------
    FileView {
        id: store
        path: Quickshell.statePath("wallpaper")
        onLoaded: {
            var t = text().trim();
            if (t.length > 0)
                root.current = t;
        }
    }
}
