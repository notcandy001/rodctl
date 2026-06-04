pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland._WlrLayerShell
import Quickshell.Io
import qs.services

Singleton {
    id: root

    property bool visible: false
    property string activePage: "general"   // general | appearance | network | power | compositor

    function open(page) {
        activePage = page !== undefined ? page : "general"
        visible = true
    }

    function close() {
        visible = false
    }

    WlrLayershell {
        id: win
        visible: root.visible
        layer: WlrLayer.Overlay
        anchors.top:    true
        anchors.right:  true
        anchors.bottom: false
        anchors.left:   false
        margins.top:   12
        margins.right: 12
        implicitWidth:  520
        implicitHeight: 640
        color: "transparent"
        exclusiveZone: 0
        keyboardFocus: WlrKeyboardFocus.OnDemand

        Keys.onEscapePressed: root.close()

        Rectangle {
            anchors.fill: parent
            radius: 28
            color: "#1a1a1aee"
            border.color: "#33ffffff"
            border.width: 1

            RowLayout {
                anchors.fill: parent
                spacing: 0

                // ── Sidebar ───────────────────────────────────────
                Rectangle {
                    Layout.preferredWidth: 160
                    Layout.fillHeight: true
                    color: "#121212"
                    radius: 28

                    // Right border
                    Rectangle {
                        anchors { top: parent.top; bottom: parent.bottom; right: parent.right }
                        width: 1
                        color: "#22ffffff"
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 8

                        Text {
                            text: "Settings"
                            color: "white"
                            font.pixelSize: 18
                            font.bold: true
                            Layout.topMargin: 12
                            Layout.bottomMargin: 20
                            Layout.alignment: Qt.AlignLeft
                        }

                        Repeater {
                            model: [
                                { id: "general",    icon: "󰒓", label: "General"    },
                                { id: "appearance", icon: "󰉼", label: "Appearance" },
                                { id: "network",    icon: "󰤨", label: "Network"    },
                                { id: "power",      icon: "⏻",  label: "Power"      },
                                { id: "compositor", icon: "⚙",  label: "Compositor" }
                            ]

                            delegate: Rectangle {
                                Layout.fillWidth: true
                                height: 40
                                radius: 10
                                color: root.activePage === modelData.id ? "#22ffffff" : "transparent"

                                Behavior on color { ColorAnimation { duration: 150 } }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 12
                                    spacing: 12

                                    Text {
                                        text: modelData.icon
                                        color: root.activePage === modelData.id ? "white" : "#888"
                                        font.pixelSize: 16
                                    }
                                    Text {
                                        text: modelData.label
                                        color: root.activePage === modelData.id ? "white" : "#888"
                                        font.pixelSize: 14
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: root.activePage = modelData.id
                                }
                            }
                        }

                        Item { Layout.fillHeight: true }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 40
                            radius: 10
                            color: closeHover.containsMouse ? "#33ff6b6b" : "#18ff6b6b"

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 8
                                Text { text: "✕"; color: "#ff8888"; font.pixelSize: 14 }
                                Text { text: "Close"; color: "#ff8888"; font.pixelSize: 14 }
                            }

                            MouseArea {
                                id: closeHover
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: root.close()
                            }
                        }
                    }
                }

                // ── Content area ──────────────────────────────────
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Loader {
                        anchors.fill: parent
                        anchors.margins: 24
                        sourceComponent: {
                            switch (root.activePage) {
                                case "general":    return generalPage
                                case "appearance": return appearancePage
                                case "network":    return networkPage
                                case "power":      return powerPage
                                case "compositor": return compositorPage
                                default:           return generalPage
                            }
                        }
                    }
                }
            }
        }
    }

    // ════════════════════════════════════════════════════════════════
    // PAGE: General
    // ════════════════════════════════════════════════════════════════
    Component {
        id: generalPage
        ColumnLayout {
            spacing: 20

            Text {
                text: "General"
                color: "white"
                font.pixelSize: 24
                font.bold: true
            }

            SettingsSection {
                title: "Bar Layout"
                Layout.fillWidth: true

                // The inner Column of SettingsSection now takes these as children
                SettingRow {
                    label: "Position"
                    control: SettingDropdown {
                        currentText: BarSettings.barPosition === "top" ? "Top" : "Bottom"
                        options: ["Top", "Bottom"]
                        onActivated: (val) => {
                            BarSettings.barPosition = val.toLowerCase()
                        }
                    }
                }
                SettingRow {
                    label: "Height"
                    control: Slider {
                        from: 32; to: 64; stepSize: 2
                        value: BarSettings.barHeight
                        onMoved: BarSettings.barHeight = value
                        width: 120
                    }
                }
                SettingRow {
                    label: "Left Margin"
                    control: Slider {
                        from: 0; to: 40; stepSize: 1
                        value: BarSettings.leftMargin
                        onMoved: BarSettings.leftMargin = value
                        width: 120
                    }
                }
                SettingRow {
                    label: "Right Margin"
                    control: Slider {
                        from: 0; to: 40; stepSize: 1
                        value: BarSettings.rightMargin
                        onMoved: BarSettings.rightMargin = value
                        width: 120
                    }
                }
            }
        }
    }

    // ════════════════════════════════════════════════════════════════
    // PAGE: Appearance
    // ════════════════════════════════════════════════════════════════
    Component {
        id: appearancePage
        ColumnLayout {
            spacing: 20

            Text {
                text: "Appearance"
                color: "white"
                font.pixelSize: 24
                font.bold: true
            }

            SettingsSection {
                title: "Visuals"
                Layout.fillWidth: true

                SettingRow {
                    label: "Notch Opacity"
                    control: Slider {
                        from: 0.3; to: 1.0; stepSize: 0.05
                        value: BarSettings.notchOpacity
                        onMoved: BarSettings.notchOpacity = value
                        width: 120
                    }
                }
                SettingRow {
                    label: "Pill Opacity"
                    control: Slider {
                        from: 0.1; to: 1.0; stepSize: 0.05
                        value: BarSettings.pillOpacity
                        onMoved: BarSettings.pillOpacity = value
                        width: 120
                    }
                }
                SettingRow {
                    label: "Corner Radius"
                    control: Slider {
                        from: 0; to: 24; stepSize: 1
                        value: BarSettings.pillRadius
                        onMoved: BarSettings.pillRadius = value
                        width: 120
                    }
                }
            }
        }
    }

    // ════════════════════════════════════════════════════════════════
    // PAGE: Network
    // ════════════════════════════════════════════════════════════════
    Component {
        id: networkPage
        ColumnLayout {
            spacing: 20

            Text {
                text: "Network"
                color: "white"
                font.pixelSize: 24
                font.bold: true
            }

            SettingsSection {
                title: "Connectivity"
                Layout.fillWidth: true

                SettingAction {
                    label: "WiFi Connection"
                    onActivated: {
                        var p = Qt.createQmlObject('import Quickshell.Io; Process {}', parent)
                        p.command = ["bash", "-c", "nm-applet &"]
                        p.running = true
                    }
                }
                SettingAction {
                    label: "Restart NetworkManager"
                    onActivated: {
                        var p = Qt.createQmlObject('import Quickshell.Io; Process {}', parent)
                        p.command = ["bash", "-c", "systemctl restart NetworkManager"]
                        p.running = true
                    }
                }
            }
        }
    }

    // ════════════════════════════════════════════════════════════════
    // PAGE: Power
    // ════════════════════════════════════════════}
    Component {
        id: powerPage
        ColumnLayout {
            spacing: 20

            Text {
                text: "Power"
                color: "white"
                font.pixelSize: 24
                font.bold: true
            }

            SettingsSection {
                title: "System"
                Layout.fillWidth: true

                SettingAction {
                    label: "Lock Screen"
                    onActivated: {
                        var p = Qt.createQmlObject('import Quickshell.Io; Process {}', parent)
                        p.command = ["bash", "-c", "hyprlock"]
                        p.running = true
                    }
                }
                SettingAction {
                    label: "Logout"
                    onActivated: {
                        var p = Qt.createQmlObject('import Quickshell.Io; Process {}', parent)
                        }
                }
                SettingAction {
                    label: "Reboot"
                    onActivated: {
                        var p = Qt.createQmlObject('import Quickshell.Io; Process {}', parent)
                        p.command = ["bash", "-c", "systemctl reboot"]
                        p.running = true
                    }
                }
                SettingAction {
                    label: "Shutdown"
                    onActivated: {
                        var p = Qt.createQmlObject('다고', parent)
                        p.command = ["bash", "-c", "systemctl poweroff"]
                        p.running = true
                    }
                }
            }
        }
    }

    // ════════════════════════════════════════════════════════════════
    // PAGE: Compositor
    // ════════════════════════════════════════════════════════════════
    Component {
        id: compositorPage
        ColumnLayout {
            spacing: 20

            Text {
                text: "Compositor"
                color: "white"
                font.pixelSize: 24
                font.bold: true
            }

            SettingsSection {
                title: "Environment"
                Layout.fillWidth: true

                SettingRow {
                    label: "Compositor"
                    control: SettingDropdown {
                        currentText: "Hyprland"
                        options: ["Hyprland", "Sway", "River"]
                        onActivated: (val) => {
                            console.log("Compositor changed to: " + val)
                        }
                    }
                }
            }
        }
    }
}
