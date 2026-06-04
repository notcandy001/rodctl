import QtQuick
import Quickshell
import Quickshell.Wayland._WlrLayerShell
import qs.modules.settings
import qs.services

WlrLayershell {

    id: bar

    layer: WlrLayer.Top
    anchors.top:    BarSettings.barPosition !== "bottom"
    anchors.bottom: BarSettings.barPosition === "bottom"
    implicitWidth: screen.width

    // Bar height is driven by BarSettings (live)
    implicitHeight: notch.mode === "idle"
                    ? notch.collapsedHeight + BarSettings.topSpacing
                    : notch.expandedHeight  + BarSettings.topSpacing

    margins.top:    BarSettings.barPosition !== "bottom" ? BarSettings.topSpacing : 0
    margins.bottom: BarSettings.barPosition === "bottom" ? BarSettings.topSpacing : 0

    exclusiveZone: notch.collapsedHeight + BarSettings.topSpacing

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
                leftMargin: BarSettings.leftMargin
                topMargin:  10
            }
            z: 2
            onLauncherRequested: notch.mode = "launcher"
        }

        // ── RIGHT PILLS ────────────────────────────────────────────
        RightContainer {
            id: rightPills
            anchors {
                right:      parent.right
                top:        parent.top
                rightMargin: BarSettings.rightMargin
                topMargin:   10
            }
            z: 2
        }

        // ── CENTER NOTCH ───────────────────────────────────────────
        Notch {
            id: notch
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 6
            z: 3
        }
    }
}
