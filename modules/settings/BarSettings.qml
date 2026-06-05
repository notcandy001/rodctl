pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string barPosition:    "top"
    property int    barHeight:      40
    property int    leftMargin:     14
    property int    rightMargin:    14
    property int    topSpacing:     4
    property int    workspacesShown: 9
    property real   notchOpacity:   0.88
    property real   pillOpacity:    0.27
    property int    pillRadius:     14

    readonly property string configPath:
        Quickshell.env("HOME") + "/.config/moonsshell/settings.json"

    Component.onCompleted: loadProc.running = true

    Process {
        id: loadProc
        running: false
        command: ["bash", "-c", "cat \"" + root.configPath + "\" 2>/dev/null || echo '{}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var obj = JSON.parse(this.text)
                    if (obj.barPosition    !== undefined) root.barPosition    = obj.barPosition
                    if (obj.barHeight      !== undefined) root.barHeight      = obj.barHeight
                    if (obj.leftMargin     !== undefined) root.leftMargin     = obj.leftMargin
                    if (obj.rightMargin    !== undefined) root.rightMargin    = obj.rightMargin
                    if (obj.topSpacing     !== undefined) root.topSpacing     = obj.topSpacing
                    if (obj.workspacesShown!== undefined) root.workspacesShown= obj.workspacesShown
                    if (obj.notchOpacity   !== undefined) root.notchOpacity   = obj.notchOpacity
                    if (obj.pillOpacity    !== undefined) root.pillOpacity    = obj.pillOpacity
                    if (obj.pillRadius     !== undefined) root.pillRadius     = obj.pillRadius
                } catch(e) {}
            }
        }
    }

    Timer {
        id: saveTimer; interval: 800; repeat: false
        onTriggered: {
            var obj = {
                barPosition:     root.barPosition,
                barHeight:       root.barHeight,
                leftMargin:      root.leftMargin,
                rightMargin:     root.rightMargin,
                topSpacing:      root.topSpacing,
                workspacesShown: root.workspacesShown,
                notchOpacity:    root.notchOpacity,
                pillOpacity:     root.pillOpacity,
                pillRadius:      root.pillRadius
            }
            var json = JSON.stringify(obj, null, 2)
            var p = Qt.createQmlObject('import Quickshell.Io; Process {}', root)
            p.command = ["bash", "-c",
                "mkdir -p ~/.config/moonsshell && printf '%s' '" +
                json.replace(/'/g,"'\\''") + "' > \"" + root.configPath + "\""]
            p.running = true
        }
    }

    onBarPositionChanged:    saveTimer.restart()
    onBarHeightChanged:      saveTimer.restart()
    onLeftMarginChanged:     saveTimer.restart()
    onRightMarginChanged:    saveTimer.restart()
    onTopSpacingChanged:     saveTimer.restart()
    onWorkspacesShownChanged:saveTimer.restart()
    onNotchOpacityChanged:   saveTimer.restart()
    onPillOpacityChanged:    saveTimer.restart()
    onPillRadiusChanged:     saveTimer.restart()
}
