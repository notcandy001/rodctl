pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland._WlrLayerShell
import Quickshell.Io
import qs.services

// ─────────────────────────────────────────────────────────────────────────────
//  Moonsshell Settings Panel
//  Opens as a floating layer-shell popup anchored to the right.
//  Call SettingsWindow.open("page") to jump straight to a section.
// ─────────────────────────────────────────────────────────────────────────────

Singleton {
    id: root

    property bool visible: false
    property string activePage: "general"   // general | network | power | appearance

    function open(page) {
        activePage = page !== undefined ? page : "general"
        visible = true
    }

    function close() {
        visible = false
    }

    // ── Layer-shell window ────────────────────────────────────────
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

        implicitWidth:  440
        implicitHeight: 580

        color: "transparent"
        exclusiveZone: 0
        keyboardFocus: WlrKeyboardFocus.OnDemand

        Keys.onEscapePressed: root.close()

        // ── Outer card ────────────────────────────────────────────
        Rectangle {
            anchors.fill: parent
            radius: 24
            color: "#e8101018"
            border.color: "#22ffffff"
            border.width: 1

            // ── Sidebar + content split ───────────────────────────
            RowLayout {
                anchors.fill: parent
                anchors.margins: 0
                spacing: 0

                // ── Sidebar ───────────────────────────────────────
                Rectangle {
                    Layout.preferredWidth: 140
                    Layout.fillHeight: true
                    color: "#0cffffff"
                    radius: 24

                    // Clip left radius only by covering right half
                    Rectangle {
                        anchors { top: parent.top; bottom: parent.bottom; right: parent.right }
                        width: parent.radius
                        color: parent.color
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 6

                        // Header
                        Text {
                            text: "Settings"
                            color: "white"
                            font.pixelSize: 16
                            font.bold: true
                            Layout.topMargin: 8
                            Layout.bottomMargin: 8
                        }

                        Repeater {
                            model: [
                                { id: "general",    icon: "󰒓", label: "General"    },
                                { id: "appearance", icon: "󰉼", label: "Appearance" },
                                { id: "network",    icon: "󰤨", label: "Network"    },
                                { id: "power",      icon: "⏻",  label: "Power"      }
                            ]

                            delegate: Rectangle {
                                Layout.fillWidth: true
                                height: 36
                                radius: 10
                                color: root.activePage === modelData.id
                                    ? "#33ffffff" : (navHover.containsMouse ? "#18ffffff" : "transparent")

                                Behavior on color { ColorAnimation { duration: 100 } }

                                Row {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    spacing: 8

                                    Text {
                                        text: modelData.icon
                                        color: "white"
                                        font.pixelSize: 14
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    Text {
                                        text: modelData.label
                                        color: root.activePage === modelData.id ? "white" : "#aaaaaa"
                                        font.pixelSize: 13
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }

                                MouseArea {
                                    id: navHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: root.activePage = modelData.id
                                }
                            }
                        }

                        Item { Layout.fillHeight: true }

                        // Close button
                        Rectangle {
                            Layout.fillWidth: true
                            height: 34
                            radius: 10
                            color: closeHover.containsMouse ? "#33ff6b6b" : "#18ff6b6b"

                            Behavior on color { ColorAnimation { duration: 100 } }

                            Row {
                                anchors.centerIn: parent
                                spacing: 6
                                Text { text: "✕"; color: "#ff8888"; font.pixelSize: 13 }
                                Text { text: "Close"; color: "#ff8888"; font.pixelSize: 13 }
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
                        anchors.margins: 20
                        sourceComponent: {
                            switch (root.activePage) {
                                case "general":    return generalPage
                                case "appearance": return appearancePage
                                case "network":    return networkPage
                                case "power":      return powerPage
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
            spacing: 16

            Text { text: "General"; color: "white"; font.pixelSize: 18; font.bold: true }

            // Bar position
            SettingsSection {
                title: "Bar position"
                Layout.fillWidth: true

                Row {
                    spacing: 8
                    Repeater {
                        model: ["Top", "Bottom"]
                        delegate: SettingChip {
                            label: modelData
                            active: BarSettings.barPosition === modelData
                            onActivated: BarSettings.barPosition = modelData
                        }
                    }
                }
            }

            // Bar height slider
            SettingsSection {
                title: "Bar height  •  " + BarSettings.barHeight + "px"
                Layout.fillWidth: true

                Slider {
                    width: parent.width
                    from: 32; to: 64; stepSize: 2
                    value: BarSettings.barHeight
                    onMoved: BarSettings.barHeight = value
                }
            }

            // Left-pill margin
            SettingsSection {
                title: "Left margin  •  " + BarSettings.leftMargin + "px"
                Layout.fillWidth: true
                Slider {
                    width: parent.width
                    from: 0; to: 40; stepSize: 1
                    value: BarSettings.leftMargin
                    onMoved: BarSettings.leftMargin = value
                }
            }

            // Right-pill margin
            SettingsSection {
                title: "Right margin  •  " + BarSettings.rightMargin + "px"
                Layout.fillWidth: true
                Slider {
                    width: parent.width
                    from: 0; to: 40; stepSize: 1
                    value: BarSettings.rightMargin
                    onMoved: BarSettings.rightMargin = value
                }
            }

            Item { Layout.fillHeight: true }
        }
    }

    // ════════════════════════════════════════════════════════════════
    // PAGE: Appearance
    // ════════════════════════════════════════════════════════════════
    Component {
        id: appearancePage
        ColumnLayout {
            spacing: 16

            Text { text: "Appearance"; color: "white"; font.pixelSize: 18; font.bold: true }

            SettingsSection {
                title: "Notch opacity  •  " + Math.round(BarSettings.notchOpacity * 100) + "%"
                Layout.fillWidth: true
                Slider {
                    width: parent.width
                    from: 0.3; to: 1.0; stepSize: 0.05
                    value: BarSettings.notchOpacity
                    onMoved: BarSettings.notchOpacity = value
                }
            }

            SettingsSection {
                title: "Pill opacity  •  " + Math.round(BarSettings.pillOpacity * 100) + "%"
                Layout.fillWidth: true
                Slider {
                    width: parent.width
                    from: 0.1; to: 1.0; stepSize: 0.05
                    value: BarSettings.pillOpacity
                    onMoved: BarSettings.pillOpacity = value
                }
            }

            SettingsSection {
                title: "Corner radius  •  " + BarSettings.pillRadius + "px"
                Layout.fillWidth: true
                Slider {
                    width: parent.width
                    from: 0; to: 24; stepSize: 1
                    value: BarSettings.pillRadius
                    onMoved: BarSettings.pillRadius = value
                }
            }

            Item { Layout.fillHeight: true }
        }
    }

    // ════════════════════════════════════════════════════════════════
    // PAGE: Network
    // ════════════════════════════════════════════════════════════════
    Component {
        id: networkPage
        ColumnLayout {
            spacing: 16

            Text { text: "Network"; color: "white"; font.pixelSize: 18; font.bold: true }

            // Status card
            Rectangle {
                Layout.fillWidth: true
                height: 72
                radius: 14
                color: "#16ffffff"

                Row {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 16

                    Text {
                        text: NetworkInfo.wifiIcon
                        font.pixelSize: 28
                        color: NetworkInfo.connected ? "#60d394" : "#ff6b6b"
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2
                        Text {
                            text: NetworkInfo.connected
                                ? NetworkInfo.ssid : "Not connected"
                            color: "white"
                            font.pixelSize: 14
                        }
                        Text {
                            text: NetworkInfo.connected
                                ? "Signal: " + NetworkInfo.strength + "%" : "No WiFi"
                            color: "#888"
                            font.pixelSize: 12
                        }
                    }
                }
            }

            // Quick actions
            SettingsSection {
                title: "Quick actions"
                Layout.fillWidth: true

                Column {
                    width: parent.width
                    spacing: 8

                    SettingsButton {
                        label: "Open nm-applet"
                        onActivated: {
                            var p = Qt.createQmlObject('import Quickshell.Io; Process {}', parent)
                            p.command = ["bash", "-c", "nm-applet &"]
                            p.running = true
                        }
                    }

                    SettingsButton {
                        label: "Restart NetworkManager"
                        onActivated: {
                            var p = Qt.createQmlObject('import Quickshell.Io; Process {}', parent)
                            p.command = ["bash", "-c", "systemctl restart NetworkManager"]
                            p.running = true
                        }
                    }
                }
            }

            Item { Layout.fillHeight: true }
        }
    }

    // ════════════════════════════════════════════════════════════════
    // PAGE: Power
    // ════════════════════════════════════════════════════════════════
    Component {
        id: powerPage
        ColumnLayout {
            spacing: 12

            Text { text: "Power"; color: "white"; font.pixelSize: 18; font.bold: true }

            Repeater {
                model: [
                    { label: "Lock",     icon: "󰌾", cmd: "hyprlock",               color: "#60d394" },
                    { label: "Logout",   icon: "󰍃", cmd: "hyprctl dispatch exit",   color: "#ffd166" },
                    { label: "Reboot",   icon: "󰑓", cmd: "systemctl reboot",        color: "#f4a261" },
                    { label: "Shutdown", icon: "⏻",  cmd: "systemctl poweroff",      color: "#ff6b6b" }
                ]

                delegate: Rectangle {
                    Layout.fillWidth: true
                    height: 52
                    radius: 14
                    color: pwHover.containsMouse ? Qt.rgba(0.2,0.2,0.2,0.9) : "#14ffffff"

                    Behavior on color { ColorAnimation { duration: 100 } }

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 20
                        spacing: 14

                        Text {
                            text: modelData.icon
                            font.pixelSize: 18
                            color: modelData.color
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: modelData.label
                            color: "white"
                            font.pixelSize: 14
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        id: pwHover
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            root.close()
                            var p = Qt.createQmlObject('import Quickshell.Io; Process {}', parent)
                            p.command = ["bash", "-c", modelData.cmd]
                            p.running = true
                        }
                    }
                }
            }

            Item { Layout.fillHeight: true }
        }
    }
}
