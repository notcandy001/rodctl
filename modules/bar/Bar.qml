import QtQuick
import Quickshell
import Quickshell.Wayland._WlrLayerShell
import qs.modules.settings
import qs.services
import qs.theme
import "workspaces"

WlrLayershell {
    id: bar

    layer: WlrLayer.Top
    anchors.top:    BarSettings.barPosition !== "bottom"
    anchors.bottom: BarSettings.barPosition === "bottom"
    implicitWidth:  screen.width

    implicitHeight: notch.mode === "idle"
        ? notch.collapsedHeight + BarSettings.topSpacing
        : notch.expandedHeight  + BarSettings.topSpacing

    margins.top:    BarSettings.barPosition !== "bottom" ? BarSettings.topSpacing : 0
    margins.bottom: BarSettings.barPosition === "bottom" ? BarSettings.topSpacing : 0

    exclusiveZone: notch.collapsedHeight + BarSettings.topSpacing
    color: "transparent"

    Item {
        anchors.fill: parent

        // Outside click closes notch
        MouseArea {
            anchors.fill: parent
            visible: notch.mode !== "idle"
            enabled: notch.mode !== "idle"
            z: 1
            onClicked: notch.mode = "idle"
        }

        // LEFT: launcher + pinned apps
        LeftContainer {
            id: leftPills
            anchors { left: parent.left; top: parent.top; leftMargin: BarSettings.leftMargin; topMargin: 10 }
            z: 2
            onLauncherRequested: notch.mode = "launcher"
        }

        // RIGHT: wifi + power
        RightContainer {
            id: rightPills
            anchors { right: parent.right; top: parent.top; rightMargin: BarSettings.rightMargin; topMargin: 10 }
            z: 2
        }

        // CENTER: notch
        Notch {
            id: notch
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 6
            z: 3
        }

        // Workspaces — sits just right of center notch
        Workspaces {
            id: wsWidget
            anchors {
                right: notch.left
                rightMargin: 12
                top: parent.top
                topMargin: (notch.collapsedHeight - height) / 2 + 6
            }
            maxShown: BarSettings.workspacesShown
            z: 2
        }
    }
}
