pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

// ─────────────────────────────────────────────────────────────────────────────
//  BarSettings  –  live-editable bar configuration
//  All properties are reactive; bind them in Bar.qml / Notch.qml etc.
// ─────────────────────────────────────────────────────────────────────────────

Singleton {
    id: root

    // Layout
    property string barPosition:  "top"   // "top" | "bottom"
    property int    barHeight:    40
    property int    leftMargin:   14
    property int    rightMargin:  14
    property int    topSpacing:   4

    // Appearance
    property real   notchOpacity: 0.80
    property real   pillOpacity:  0.27
    property int    pillRadius:   14

    // Persist to a tiny JSON file so settings survive reload
    readonly property string configPath: StandardPaths.writableLocation(
        StandardPaths.HomeLocation) + "/.config/moonsshell/settings.json"

    // ── Load on start ─────────────────────────────────────────────
    Component.onCompleted: loadProc.running = true

    Process {
        id: loadProc
        running: false
        command: ["bash", "-c", "cat \"" + root.configPath + "\" 2>/dev/null || echo '{}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var obj = JSON.parse(this.text)
                    if (obj.barPosition  !== undefined) root.barPosition  = obj.barPosition
                    if (obj.barHeight    !== undefined) root.barHeight    = obj.barHeight
                    if (obj.leftMargin   !== undefined) root.leftMargin   = obj.leftMargin
                    if (obj.rightMargin  !== undefined) root.rightMargin  = obj.rightMargin
                    if (obj.topSpacing   !== undefined) root.topSpacing   = obj.topSpacing
                    if (obj.notchOpacity !== undefined) root.notchOpacity = obj.notchOpacity
                    if (obj.pillOpacity  !== undefined) root.pillOpacity  = obj.pillOpacity
                    if (obj.pillRadius   !== undefined) root.pillRadius   = obj.pillRadius
                } catch(e) { /* first run, no file yet */ }
            }
        }
    }

    // ── Save on every change (debounced 800ms) ────────────────────
    Timer {
        id: saveTimer
        interval: 800
        repeat: false
        onTriggered: {
            var obj = {
                barPosition:  root.barPosition,
                barHeight:    root.barHeight,
                leftMargin:   root.leftMargin,
                rightMargin:  root.rightMargin,
                topSpacing:   root.topSpacing,
                notchOpacity: root.notchOpacity,
                pillOpacity:  root.pillOpacity,
                pillRadius:   root.pillRadius
            }
            var json = JSON.stringify(obj, null, 2)
            var p = Qt.createQmlObject('import Quickshell.Io; Process {}', root)
            p.command = ["bash", "-c",
                "mkdir -p ~/.config/moonsshell && printf '%s' '" + json + "' > " + root.configPath]
            p.running = true
        }
    }

    // Watch every setting and restart save timer
    onBarPositionChanged:  saveTimer.restart()
    onBarHeightChanged:    saveTimer.restart()
    onLeftMarginChanged:   saveTimer.restart()
    onRightMarginChanged:  saveTimer.restart()
    onTopSpacingChanged:   saveTimer.restart()
    onNotchOpacityChanged: saveTimer.restart()
    onPillOpacityChanged:  saveTimer.restart()
    onPillRadiusChanged:   saveTimer.restart()
}
