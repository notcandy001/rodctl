pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

// ─────────────────────────────────────────────────────────────────────────────
//  ThemeService  –  loads, switches, and persists color themes
//
//  Reads  ~/.config/moonsshell/theme.json  for current selection.
//  Writes ~/.cache/moonsshell/colors.json  after merging theme JSON
//  so Colors.qml can react to it via FileView watchChanges.
//
//  API:
//    ThemeService.setTheme("Catppuccin", "dark")
//    ThemeService.currentTheme  → "Catppuccin"
//    ThemeService.currentVariant → "dark"
// ─────────────────────────────────────────────────────────────────────────────

Singleton {
    id: root

    property string currentTheme:   "Catppuccin"
    property string currentVariant: "dark"

    // Assets dir relative to shell root (resolved at startup)
    readonly property string assetsDir:
        Quickshell.env("HOME") + "/.config/moonsshell"
    readonly property string cacheDir:
        Quickshell.env("HOME") + "/.cache/moonsshell"
    readonly property string colorAssetsDir:
        Quickshell.env("HOME") + "/.config/moonsshell/assets/colors"

    // ── Bootstrap ─────────────────────────────────────────────────
    Component.onCompleted: {
        mkdirs.running = true
    }

    Process {
        id: mkdirs
        running: false
        command: ["bash", "-c",
            "mkdir -p \"" + root.cacheDir + "\" \"" + root.assetsDir + "\""]
        onRunningChanged: {
            if (!running) loadConfig.running = true
        }
    }

    // Load saved config
    Process {
        id: loadConfig
        running: false
        command: ["bash", "-c",
            "cat \"" + root.assetsDir + "/theme.json\" 2>/dev/null || echo '{}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var obj = JSON.parse(this.text)
                    if (obj.theme)   root.currentTheme   = obj.theme
                    if (obj.variant) root.currentVariant = obj.variant
                } catch(e) {}
                root._applyTheme(root.currentTheme, root.currentVariant)
            }
        }
    }

    // ── Public API ────────────────────────────────────────────────
    function setTheme(name, variant) {
        currentTheme   = name
        currentVariant = variant || "dark"
        _applyTheme(currentTheme, currentVariant)
        _saveConfig()
    }

    function toggleVariant() {
        setTheme(currentTheme, currentVariant === "dark" ? "light" : "dark")
    }

    // ── Internal ──────────────────────────────────────────────────
    function _colorFilePath(name, variant) {
        // Try user config dir first, then fall back to shell assets dir
        // The assets were copied to ~/.config/moonsshell/assets/colors/
        return colorAssetsDir + "/" + name + "/" + variant + ".json"
    }

    function _applyTheme(name, variant) {
        var path = _colorFilePath(name, variant)
        var p = Qt.createQmlObject('import Quickshell.Io; Process {}', root)
        p.command = ["bash", "-c", "cat \"" + path + "\" 2>/dev/null || echo '{}'"]
        var col = Qt.createQmlObject('import Quickshell.Io; StdioCollector {}', p)
        p.stdout = col
        col.onStreamFinished.connect(function() {
            try {
                var obj = JSON.parse(col.text)
                obj._themeName    = name
                obj._themeVariant = variant
                var json = JSON.stringify(obj, null, 2)
                // Write to cache so Colors.qml reacts
                var w = Qt.createQmlObject('import Quickshell.Io; Process {}', root)
                w.command = ["bash", "-c",
                    "printf '%s' '" + json.replace(/'/g, "'\\''") +
                    "' > \"" + root.cacheDir + "/colors.json\""]
                w.running = true
            } catch(e) { console.warn("ThemeService: failed to apply theme:", e) }
        })
        p.running = true
    }

    function _saveConfig() {
        var obj = { theme: currentTheme, variant: currentVariant }
        var json = JSON.stringify(obj, null, 2)
        var p = Qt.createQmlObject('import Quickshell.Io; Process {}', root)
        p.command = ["bash", "-c",
            "printf '%s' '" + json + "' > \"" + root.assetsDir + "/theme.json\""]
        p.running = true
    }
}
