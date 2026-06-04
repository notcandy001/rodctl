import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.services
import qs.modules.functions
import qs.modules.settings

Rectangle {
    id: root

    property string mode: "idle"
    property int collapsedHeight: 38
    property int expandedHeight: 460

    signal closeRequested()

    property Toplevel activeToplevel: HyprlandData.isWorkspaceOccupied(HyprlandData.focusedWorkspaceId)
        ? HyprlandData.activeToplevel
        : null

    property string cleanTitle: {
        if (!activeToplevel)
            return "Desktop"

        var raw = activeToplevel?.title

        if (!raw || raw === "" || raw === "Workspace")
            return "Desktop"

        var parts = raw.split(" - ")
        if (parts.length > 1)
            return parts[0]

        return raw
    }

    width: {
        if (mode !== "idle")
            return 800

        var base = 200
        var textWidth = titleText.implicitWidth
        var calculated = base + textWidth

        return Math.min(Math.max(calculated, 300), screen.width * 0.7)
    }

    height: mode === "idle" ? collapsedHeight : expandedHeight
    radius: mode === "idle" ? 19 : 28
    color: Qt.rgba(0.063, 0.063, 0.082, BarSettings.notchOpacity !== undefined ? BarSettings.notchOpacity : 0.9)
    border.width: 1
    border.color: "#2aFFFFFF"

    Behavior on width {
        NumberAnimation { duration: 300; easing.type: Easing.OutQuint }
    }

    Behavior on height {
        NumberAnimation { duration: 300; easing.type: Easing.OutQuint }
    }

    Keys.onEscapePressed: {
        if (mode !== "idle")
            mode = "idle"
    }

    focus: true


    // IDLE CONTENT (Fixed)

    Item {
        anchors.fill: parent
        visible: mode === "idle"

        Row {
            anchors.fill: parent
            anchors.margins: 16
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            spacing: 12

            // TIME (HARD LEFT)
            Text {
                id: timeText
                text: Qt.formatTime(new Date(), "hh:mm a")
                color: "#ffffff"
                font.pixelSize: 14
                font.weight: Font.Bold
                verticalAlignment: Text.AlignVCenter
                height: parent.height
            }

            // FLEX SPACE
            Item {
                width: parent.width - timeText.width - titleText.width - 32
                height: 1
            }

            // TITLE (HARD RIGHT)
            Text {
                id: titleText
                text: root.cleanTitle
                color: "#ffffff"
                font.pixelSize: 14
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
                height: parent.height
            }
        }

        Timer {
            interval: 60000
            running: true
            repeat: true
            onTriggered: timeText.text =
                Qt.formatTime(new Date(), "hh:mm a")
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.mode = "dashboard"
        }
    }

    // ======================================================
    // DASHBOARD (OPEN / CLOSE FIXED)
    // ======================================================

    Item {
        anchors.fill: parent
        anchors.margins: 32
        visible: mode === "dashboard"

        Rectangle {
            anchors.fill: parent
            radius: 22
            color: "#151515"

            Text {
                anchors.centerIn: parent
                text: "Dashboard"
                color: "white"
                font.pixelSize: 22
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.mode = "idle"
        }
    }
}
