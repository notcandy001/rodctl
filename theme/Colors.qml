pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

// ─────────────────────────────────────────────────────────────────────────────
//  Colors  –  reactive color system for Moonsshell
//
//  Loads from: ~/.cache/moonsshell/colors.json  (written by ThemeService)
//  Falls back to built-in Catppuccin dark defaults if no file exists.
//
//  Usage anywhere:  Colors.primary   Colors.background   Colors.surface  etc.
// ─────────────────────────────────────────────────────────────────────────────

Singleton {
    id: root

    // ── Active theme metadata ──────────────────────────────────────
    property string themeName:  "Catppuccin"
    property string themeVariant: "dark"        // "dark" | "light"

    // ── Cache file path (ThemeService writes here on switch) ───────
    readonly property string cachePath:
        Quickshell.env("HOME") + "/.cache/moonsshell/colors.json"

    // ── Live-watch the cache file ──────────────────────────────────
    property FileView fileView: FileView {
        path: root.cachePath
        preload: true
        watchChanges: true
        onFileChanged: root.reloadFromFile()
    }

    Component.onCompleted: reloadFromFile()

    function reloadFromFile() {
        var proc = Qt.createQmlObject('import Quickshell.Io; Process {}', root)
        proc.command = ["bash", "-c", "cat \"" + cachePath + "\" 2>/dev/null || echo '{}'"]
        proc.running = true

        proc.stdout = Qt.createQmlObject('import Quickshell.Io; StdioCollector {}', proc)
        proc.stdout.onStreamFinished.connect(function() {
            try {
                var obj = JSON.parse(proc.stdout.text)
                root._applyJson(obj)
            } catch(e) { /* use defaults */ }
        })
    }

    function _applyJson(obj) {
        function g(key, fallback) {
            return obj[key] !== undefined ? obj[key] : fallback
        }
        background           = g("background",           background)
        surface              = g("surface",              surface)
        surfaceBright        = g("surfaceBright",        surfaceBright)
        surfaceContainer     = g("surfaceContainer",     surfaceContainer)
        surfaceContainerHigh = g("surfaceContainerHigh", surfaceContainerHigh)
        surfaceContainerHighest = g("surfaceContainerHighest", surfaceContainerHighest)
        surfaceContainerLow  = g("surfaceContainerLow",  surfaceContainerLow)
        surfaceContainerLowest = g("surfaceContainerLowest", surfaceContainerLowest)
        surfaceDim           = g("surfaceDim",           surfaceDim)
        surfaceTint          = g("surfaceTint",          surfaceTint)
        surfaceVariant       = g("surfaceVariant",       surfaceVariant)
        primary              = g("primary",              primary)
        primaryContainer     = g("primaryContainer",     primaryContainer)
        secondary            = g("secondary",            secondary)
        secondaryContainer   = g("secondaryContainer",   secondaryContainer)
        tertiary             = g("tertiary",             tertiary)
        tertiaryContainer    = g("tertiaryContainer",    tertiaryContainer)
        error                = g("error",                error)
        errorContainer       = g("errorContainer",       errorContainer)
        outline              = g("outline",              outline)
        outlineVariant       = g("outlineVariant",       outlineVariant)
        overBackground       = g("overBackground",       overBackground)
        overSurface          = g("overSurface",          overSurface)
        overPrimary          = g("overPrimary",          overPrimary)
        overPrimaryContainer = g("overPrimaryContainer", overPrimaryContainer)
        overSecondary        = g("overSecondary",        overSecondary)
        overTertiary         = g("overTertiary",         overTertiary)
        overError            = g("overError",            overError)
        red                  = g("red",                  red)
        green                = g("green",                green)
        blue                 = g("blue",                 blue)
        yellow               = g("yellow",               yellow)
        cyan                 = g("cyan",                 cyan)
        magenta              = g("magenta",              magenta)
        white                = g("white",                white)
        redContainer         = g("redContainer",         redContainer)
        greenContainer       = g("greenContainer",       greenContainer)
        blueContainer        = g("blueContainer",        blueContainer)
        yellowContainer      = g("yellowContainer",      yellowContainer)
        cyanContainer        = g("cyanContainer",        cyanContainer)
        magentaContainer     = g("magentaContainer",     magentaContainer)
        lightRed             = g("lightRed",             lightRed)
        lightGreen           = g("lightGreen",           lightGreen)
        lightBlue            = g("lightBlue",            lightBlue)
        lightYellow          = g("lightYellow",          lightYellow)
        lightCyan            = g("lightCyan",            lightCyan)
        lightMagenta         = g("lightMagenta",         lightMagenta)
        overRed              = g("overRed",              overRed)
        overGreen            = g("overGreen",            overGreen)
        overBlue             = g("overBlue",             overBlue)
        overYellow           = g("overYellow",           overYellow)
        overCyan             = g("overCyan",             overCyan)
        overMagenta          = g("overMagenta",          overMagenta)
        sourceColor          = g("sourceColor",          sourceColor)
        scrim                = g("scrim",                scrim)
        shadow               = g("shadow",               shadow)
        if (obj._themeName)    themeName    = obj._themeName
        if (obj._themeVariant) themeVariant = obj._themeVariant
    }

    // ── Defaults: Catppuccin dark ──────────────────────────────────
    property color background:              "#1d1d2d"
    property color surface:                 "#252534"
    property color surfaceBright:           "#393947"
    property color surfaceContainer:        "#292938"
    property color surfaceContainerHigh:    "#2e2e3d"
    property color surfaceContainerHighest: "#323241"
    property color surfaceContainerLow:     "#272736"
    property color surfaceContainerLowest:  "#232332"
    property color surfaceDim:              "#252534"
    property color surfaceTint:             "#95bcfb"
    property color surfaceVariant:          "#40404d"
    property color primary:                 "#95bcfb"
    property color primaryContainer:        "#455a7d"
    property color secondary:               "#f7cbeb"
    property color secondaryContainer:      "#7b6174"
    property color tertiary:                "#a1e5da"
    property color tertiaryContainer:       "#436660"
    property color error:                   "#f497b1"
    property color errorContainer:          "#613843"
    property color outline:                 "#5b5e73"
    property color outlineVariant:          "#383a4c"
    property color overBackground:          "#CDD6F4"
    property color overSurface:             "#CDD6F4"
    property color overPrimary:             "#29364b"
    property color overPrimaryContainer:    "#b2cefc"
    property color overSecondary:           "#4a3a45"
    property color overTertiary:            "#253935"
    property color overError:              "#44272f"
    property color red:                     "#f497b1"
    property color green:                   "#ade5a9"
    property color blue:                    "#97bdfb"
    property color yellow:                  "#f9e4b4"
    property color cyan:                    "#9de4d8"
    property color magenta:                 "#f6c8e9"
    property color white:                   "#d0d8f5"
    property color redContainer:            "#7a4654"
    property color greenContainer:          "#425b40"
    property color blueContainer:           "#3e5170"
    property color yellowContainer:         "#574f3d"
    property color cyanContainer:           "#344f4b"
    property color magentaContainer:        "#765d6f"
    property color lightRed:                "#f59cb5"
    property color lightGreen:              "#b2e7ad"
    property color lightBlue:               "#9dc1fb"
    property color lightYellow:             "#fae5b8"
    property color lightCyan:               "#a2e6da"
    property color lightMagenta:            "#f7cbeb"
    property color overRed:                 "#492a32"
    property color overGreen:               "#2a3928"
    property color overBlue:                "#263246"
    property color overYellow:              "#3e392c"
    property color overCyan:                "#21322f"
    property color overMagenta:             "#42343e"
    property color sourceColor:             "#89B4FA"
    property color scrim:                   "#000000"
    property color shadow:                  "#000000"

    // ── Semantic helpers ───────────────────────────────────────────
    property color warning: yellow
    property color success: green
    property color criticalRed: "#FF0028"

    // ── Pill / notch color helpers used by bar components ─────────
    property color pillBg:       Qt.rgba(overBackground.r, overBackground.g, overBackground.b, 0.12)
    property color pillHover:    Qt.rgba(overBackground.r, overBackground.g, overBackground.b, 0.22)
    property color notchBg:      Qt.rgba(background.r, background.g, background.b, 0.88)

    // ── Full list for theme picker UI ──────────────────────────────
    readonly property var themeList: [
        "Ayu", "Catppuccin", "Everforest", "GitHub", "Gruvbox",
        "Kanagawa", "Nord", "Paradise", "Posterpole", "Rose Pine",
        "Tokyonight", "Yoru"
    ]
}
