import QtQuick
import Quickshell
import Quickshell.Wayland._WlrLayerShell
import qs.modules.settings
import qs.services

WlrLayershell {

    id: bar

    layer: WlrLayer.Overlay
    anchors.top:    BarSettings.barPosition !== "bottom"
    anchors.bottom: BarSettings.barPosition === "bottom"
    anchors.left:   true
    anchors.right:  true
    implicitWidth: screen.width
    implicitHeight: 200 // give plenty of space

    margins.top:    BarSettings.barPosition !== "bottom" ? BarSettings.topSpacing : 0
    margins.bottom: BarSettings.barPosition === "bottom" ? BarSettings.topSpacing : 0
    margins.left:   10
    margins.right:  10

    exclusiveZone: 40 + BarSettings.topSpacing

    color: "transparent"

    Item {
        anchors.fill: parent

        // ── OUTSIDE CLICK OVERLAY ──────────────────────────────────
        MouseArea {
            anchors.fill: parent
            visible: notch.mode !== "idle"
            enabled: notch.mode !== "idle"
            z: 1
            onClicked: notch.mode = "idle"
        }

        // ── LEFT PILLS ─────────────────────────────────────────────
        LeftContainer {
            id: leftPills
            anchors {
                left:      parent.left
                top:       parent.top
                topMargin: 0
            }
            z: 2
            onLauncherRequested: notch.mode = "launcher"
        }

        // ── CENTER NOTCH ───────────────────────────────────────────
        Notch {
            id: notch
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            z: 3
        }

        // ── RIGHT PILLS ────────────────────────────────────────────
        RightContainer {
            id: rightPills
            anchors {
                right:      parent.right
                top:        parent.top
                topMargin:   0
            }
            z: 2
        }
    }
}
