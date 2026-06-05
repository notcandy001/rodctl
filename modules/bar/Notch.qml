import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.services
import qs.modules.functions
import qs.modules.settings
import qs.theme

Rectangle {
    id: root

    property string mode: "idle"
    property int collapsedHeight: 40
    property int expandedHeight:  460

    signal closeRequested()

    property Toplevel activeToplevel: HyprlandData.isWorkspaceOccupied(HyprlandData.focusedWorkspaceId)
        ? HyprlandData.activeToplevel : null

    property string cleanTitle: {
        if (!activeToplevel) return "Desktop"
        var raw = activeToplevel?.title
        if (!raw || raw === "" || raw === "Workspace") return "Desktop"
        var parts = raw.split(" - ")
        if (parts.length > 1) return parts[0]
        return raw
    }

    width: {
        if (mode !== "idle") return 800
        var base = 160
        var textWidth = titleText.implicitWidth
        var calculated = base + textWidth
        return Math.min(Math.max(calculated, 240), screen.width * 0.7)
    }

    height: mode === "idle" ? collapsedHeight : expandedHeight
    radius: mode === "idle" ? 20 : 28

    color: Qt.rgba(Colors.background.r, Colors.background.g, Colors.background.b, BarSettings.notchOpacity)
    Behavior on color { ColorAnimation { duration: 200 } }

    Behavior on width  { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

    Keys.onEscapePressed: { if (mode !== "idle") mode = "idle" }
    focus: true

    // ── IDLE CONTENT ──────────────────────────────────────────────
    Item {
        anchors.fill: parent
        visible: mode === "idle"

        Row {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            Text {
                id: timeText
                text: Qt.formatTime(new Date(), "hh:mm")
                color: Colors.overBackground
                font.pixelSize: 14
                verticalAlignment: Text.AlignVCenter
                height: parent.height
                Behavior on color { ColorAnimation { duration: 200 } }
            }

            Item {
                width: parent.width - timeText.width - titleText.width - 32
                height: 1
            }

            Text {
                id: titleText
                text: root.cleanTitle
                color: Qt.rgba(Colors.overBackground.r, Colors.overBackground.g, Colors.overBackground.b, 0.7)
                font.pixelSize: 14
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
                height: parent.height
                Behavior on color { ColorAnimation { duration: 200 } }
            }
        }

        Timer {
            interval: 60000; running: true; repeat: true
            onTriggered: timeText.text = Qt.formatTime(new Date(), "hh:mm")
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.mode = "dashboard"
        }
    }

    // ── DASHBOARD ──────────────────────────────────────────────────
    Item {
        anchors.fill: parent
        anchors.margins: 24
        visible: mode === "dashboard"

        ColumnLayout {
            anchors.fill: parent
            spacing: 16

            // Tab row
            Row {
                spacing: 24
                Layout.fillWidth: true
                Repeater {
                    model: ["Widgets", "Pins", "Wallpapers", "Mixer"]
                    delegate: Text {
                        text: modelData
                        color: dashTabs.currentTab === modelData ? Colors.primary : Colors.outline
                        font.pixelSize: 15
                        Behavior on color { ColorAnimation { duration: 150 } }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: dashTabs.currentTab = modelData
                        }
                    }
                }
            }

            // Tab content
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 18
                color: Qt.rgba(Colors.surfaceContainer.r, Colors.surfaceContainer.g, Colors.surfaceContainer.b, 0.8)
                Behavior on color { ColorAnimation { duration: 200 } }

                Text {
                    anchors.centerIn: parent
                    text: dashTabs.currentTab
                    color: Colors.outline
                    font.pixelSize: 16
                }
            }
        }

        QtObject {
            id: dashTabs
            property string currentTab: "Widgets"
        }

        MouseArea {
            anchors.fill: parent
            z: -1
            onClicked: root.mode = "idle"
        }
    }

    // ── LAUNCHER ───────────────────────────────────────────────────
    Item {
        anchors.fill: parent
        anchors.margins: 24
        visible: mode === "launcher"

        LauncherView { anchors.fill: parent }
    }
}
