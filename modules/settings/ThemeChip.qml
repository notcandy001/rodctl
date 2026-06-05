pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io
import qs.theme

Rectangle {
    id: chip
    property string themeName: ""
    property string variant:   "dark"
    property bool   active:    false
    signal activated()

    height: 36
    width:  row.implicitWidth + 20
    radius: 10
    color: active
        ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.22)
        : (h.containsMouse
            ? Qt.rgba(Colors.overBackground.r, Colors.overBackground.g, Colors.overBackground.b, 0.10)
            : Qt.rgba(Colors.surfaceContainer.r, Colors.surfaceContainer.g, Colors.surfaceContainer.b, 0.5))
    Behavior on color { ColorAnimation { duration: 120 } }
    border.width: active ? 1 : 0
    border.color: Colors.primary

    // Load preview colors from JSON
    property color previewPrimary: "#888"
    property color previewBg:      "#222"
    property color previewGreen:   "#88c"
    property color previewRed:     "#c88"

    Component.onCompleted: loadPreview()
    onVariantChanged: loadPreview()

    function loadPreview() {
        var p = Qt.createQmlObject('import Quickshell.Io; Process {}', chip)
        var cfgDir = Quickshell.env("HOME") + "/.config/moonsshell/assets/colors"
        p.command = ["bash", "-c",
            "cat \"" + cfgDir + "/" + themeName + "/" + variant + ".json\" 2>/dev/null || echo '{}'"]
        var col = Qt.createQmlObject('import Quickshell.Io; StdioCollector {}', p)
        p.stdout = col
        col.onStreamFinished.connect(function() {
            try {
                var obj = JSON.parse(col.text)
                if (obj.primary)    chip.previewPrimary = obj.primary
                if (obj.background) chip.previewBg      = obj.background
                if (obj.green)      chip.previewGreen   = obj.green
                if (obj.red)        chip.previewRed     = obj.red
            } catch(e) {}
        })
        p.running = true
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 8

        // Color dots preview
        Row {
            spacing: 3
            anchors.verticalCenter: parent.verticalCenter
            Repeater {
                model: [chip.previewBg, chip.previewPrimary, chip.previewGreen, chip.previewRed]
                delegate: Rectangle {
                    width: 8; height: 8; radius: 4
                    color: modelData
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
            }
        }

        Text {
            text: chip.themeName
            color: chip.active ? Colors.primary : Colors.overBackground
            font.pixelSize: 12
            anchors.verticalCenter: parent.verticalCenter
            Behavior on color { ColorAnimation { duration: 120 } }
        }
    }

    MouseArea { id: h; anchors.fill: parent; hoverEnabled: true; onClicked: chip.activated() }
}
