pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland._WlrLayerShell
import Quickshell.Io
import qs.services
import qs.theme

// ─────────────────────────────────────────────────────────────────────────────
//  SettingsWindow  –  Moonsshell settings panel
//  Opens anchored top-right.  Call SettingsWindow.open("page").
//  Pages: general | appearance | theme | network | power
// ─────────────────────────────────────────────────────────────────────────────

Singleton {
    id: root

    property bool visible:      false
    property string activePage: "general"

    function open(page) {
        activePage = page !== undefined ? page : "general"
        visible    = true
    }
    function close() { visible = false }

    WlrLayershell {
        id: win
        visible: root.visible
        layer:   WlrLayer.Overlay

        anchors.top:    true
        anchors.right:  true
        margins.top:    12
        margins.right:  12

        implicitWidth:  480
        implicitHeight: 640
        color: "transparent"
        exclusiveZone: 0
        keyboardFocus: WlrKeyboardFocus.OnDemand
        Keys.onEscapePressed: root.close()

        // ── Outer card ────────────────────────────────────────────
        Rectangle {
            anchors.fill: parent
            radius: 22
            color: Qt.rgba(Colors.background.r, Colors.background.g, Colors.background.b, 0.94)
            border.color: Qt.rgba(Colors.outlineVariant.r, Colors.outlineVariant.g, Colors.outlineVariant.b, 0.35)
            border.width: 1

            Behavior on color { ColorAnimation { duration: 200 } }

            RowLayout {
                anchors.fill: parent
                spacing: 0

                // ── Sidebar ───────────────────────────────────────
                Rectangle {
                    Layout.preferredWidth: 148
                    Layout.fillHeight: true
                    color: Qt.rgba(Colors.overBackground.r, Colors.overBackground.g, Colors.overBackground.b, 0.05)
                    radius: 22
                    // Cover the right side to not double-round
                    Rectangle {
                        anchors { top: parent.top; bottom: parent.bottom; right: parent.right }
                        width: 22
                        color: parent.color
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 4

                        Text {
                            text: "Settings"
                            color: Colors.overBackground
                            font.pixelSize: 17
                            font.bold: true
                            Layout.topMargin: 6
                            Layout.bottomMargin: 10
                            Behavior on color { ColorAnimation { duration: 200 } }
                        }

                        Repeater {
                            model: [
                                { id: "general",    icon: "󰒓", label: "General"    },
                                { id: "theme",      icon: "󰉼", label: "Theme"      },
                                { id: "appearance", icon: "󰔈", label: "Appearance" },
                                { id: "network",    icon: "󰤨", label: "Network"    },
                                { id: "power",      icon: "⏻",  label: "Power"      }
                            ]

                            delegate: Rectangle {
                                Layout.fillWidth: true
                                height: 36
                                radius: 10
                                color: root.activePage === modelData.id
                                    ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.22)
                                    : (navHover.containsMouse
                                        ? Qt.rgba(Colors.overBackground.r, Colors.overBackground.g, Colors.overBackground.b, 0.10)
                                        : "transparent")
                                Behavior on color { ColorAnimation { duration: 100 } }

                                Row {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    spacing: 9
                                    Text {
                                        text: modelData.icon
                                        color: root.activePage === modelData.id
                                            ? Colors.primary : Colors.outline
                                        font.pixelSize: 14
                                        anchors.verticalCenter: parent.verticalCenter
                                        Behavior on color { ColorAnimation { duration: 150 } }
                                    }
                                    Text {
                                        text: modelData.label
                                        color: root.activePage === modelData.id
                                            ? Colors.overBackground : Colors.outline
                                        font.pixelSize: 13
                                        anchors.verticalCenter: parent.verticalCenter
                                        Behavior on color { ColorAnimation { duration: 150 } }
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

                        // Theme name + variant badge
                        Rectangle {
                            Layout.fillWidth: true
                            height: 38
                            radius: 10
                            color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.12)
                            Column {
                                anchors.centerIn: parent
                                spacing: 2
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: ThemeService.currentTheme
                                    color: Colors.primary
                                    font.pixelSize: 12
                                    font.bold: true
                                    Behavior on color { ColorAnimation { duration: 200 } }
                                }
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: ThemeService.currentVariant
                                    color: Colors.outline
                                    font.pixelSize: 10
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    ThemeService.toggleVariant()
                                    root.activePage = "theme"
                                }
                            }
                        }

                        // Close
                        Rectangle {
                            Layout.fillWidth: true
                            height: 34
                            radius: 10
                            color: closeHov.containsMouse
                                ? Qt.rgba(Colors.error.r, Colors.error.g, Colors.error.b, 0.22)
                                : Qt.rgba(Colors.error.r, Colors.error.g, Colors.error.b, 0.10)
                            Behavior on color { ColorAnimation { duration: 100 } }
                            Row {
                                anchors.centerIn: parent
                                spacing: 6
                                Text { text: "✕"; color: Colors.error; font.pixelSize: 13 }
                                Text { text: "Close"; color: Colors.error; font.pixelSize: 13 }
                            }
                            MouseArea { id: closeHov; anchors.fill: parent; hoverEnabled: true; onClicked: root.close() }
                        }
                    }
                }

                // ── Content area ──────────────────────────────────
                Flickable {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentHeight: pageLoader.item ? pageLoader.item.implicitHeight : height
                    clip: true
                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                    Loader {
                        id: pageLoader
                        width: parent.width - 24
                        x: 12
                        y: 16
                        sourceComponent: {
                            switch (root.activePage) {
                                case "general":    return cGeneral
                                case "theme":      return cTheme
                                case "appearance": return cAppearance
                                case "network":    return cNetwork
                                case "power":      return cPower
                                default:           return cGeneral
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
        id: cGeneral
        ColumnLayout {
            spacing: 18

            SectionTitle { text: "General" }

            SettingCard {
                label: "Bar position"
                Layout.fillWidth: true
                content: Row {
                    spacing: 8
                    Repeater {
                        model: ["top", "bottom"]
                        delegate: ChipToggle {
                            label: modelData
                            active: BarSettings.barPosition === modelData
                            onActivated: BarSettings.barPosition = modelData
                        }
                    }
                }
            }

            SettingCard {
                label: "Bar height  •  " + BarSettings.barHeight + "px"
                Layout.fillWidth: true
                content: StyledSlider {
                    from: 32; to: 64; stepSize: 2
                    value: BarSettings.barHeight
                    onMoved: BarSettings.barHeight = value
                    accentColor: Colors.primary
                }
            }

            SettingCard {
                label: "Left margin  •  " + BarSettings.leftMargin + "px"
                Layout.fillWidth: true
                content: StyledSlider {
                    from: 0; to: 48; stepSize: 1
                    value: BarSettings.leftMargin
                    onMoved: BarSettings.leftMargin = value
                    accentColor: Colors.primary
                }
            }

            SettingCard {
                label: "Right margin  •  " + BarSettings.rightMargin + "px"
                Layout.fillWidth: true
                content: StyledSlider {
                    from: 0; to: 48; stepSize: 1
                    value: BarSettings.rightMargin
                    onMoved: BarSettings.rightMargin = value
                    accentColor: Colors.primary
                }
            }

            SettingCard {
                label: "Workspaces shown  •  " + BarSettings.workspacesShown
                Layout.fillWidth: true
                content: StyledSlider {
                    from: 1; to: 10; stepSize: 1
                    value: BarSettings.workspacesShown
                    onMoved: BarSettings.workspacesShown = value
                    accentColor: Colors.primary
                }
            }

            Item { implicitHeight: 8 }
        }
    }

    // ════════════════════════════════════════════════════════════════
    // PAGE: Theme  (the Ambxst-inspired part)
    // ════════════════════════════════════════════════════════════════
    Component {
        id: cTheme
        ColumnLayout {
            spacing: 18

            SectionTitle { text: "Theme" }

            // Dark / Light toggle
            SettingCard {
                label: "Variant"
                Layout.fillWidth: true
                content: Row {
                    spacing: 8
                    Repeater {
                        model: ["dark", "light"]
                        delegate: ChipToggle {
                            label: modelData
                            active: ThemeService.currentVariant === modelData
                            onActivated: ThemeService.setTheme(ThemeService.currentTheme, modelData)
                        }
                    }
                }
            }

            // Theme grid
            SettingCard {
                label: "Color scheme"
                Layout.fillWidth: true
                content: Flow {
                    width: parent.width
                    spacing: 8

                    Repeater {
                        model: Colors.themeList
                        delegate: ThemeChip {
                            themeName: modelData
                            variant: ThemeService.currentVariant
                            active: ThemeService.currentTheme === modelData
                            onActivated: ThemeService.setTheme(modelData, ThemeService.currentVariant)
                        }
                    }
                }
            }

            // Live color preview swatches
            SettingCard {
                label: "Active palette"
                Layout.fillWidth: true
                content: Flow {
                    spacing: 6
                    Repeater {
                        model: [
                            { name: "bg",      color: Colors.background },
                            { name: "surface", color: Colors.surface },
                            { name: "primary", color: Colors.primary },
                            { name: "secondary",color: Colors.secondary },
                            { name: "tertiary", color: Colors.tertiary },
                            { name: "red",     color: Colors.red },
                            { name: "green",   color: Colors.green },
                            { name: "blue",    color: Colors.blue },
                            { name: "yellow",  color: Colors.yellow },
                            { name: "cyan",    color: Colors.cyan },
                            { name: "magenta", color: Colors.magenta },
                            { name: "white",   color: Colors.white }
                        ]
                        delegate: Column {
                            spacing: 3
                            Rectangle {
                                width: 28; height: 28; radius: 6
                                color: modelData.color
                                Behavior on color { ColorAnimation { duration: 200 } }
                                border.color: Qt.rgba(1,1,1,0.08)
                            }
                            Text {
                                text: modelData.name
                                color: Colors.outline
                                font.pixelSize: 9
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }
                    }
                }
            }

            Item { implicitHeight: 8 }
        }
    }

    // ════════════════════════════════════════════════════════════════
    // PAGE: Appearance
    // ════════════════════════════════════════════════════════════════
    Component {
        id: cAppearance
        ColumnLayout {
            spacing: 18

            SectionTitle { text: "Appearance" }

            SettingCard {
                label: "Notch opacity  •  " + Math.round(BarSettings.notchOpacity * 100) + "%"
                Layout.fillWidth: true
                content: StyledSlider {
                    from: 0.3; to: 1.0; stepSize: 0.05
                    value: BarSettings.notchOpacity
                    onMoved: BarSettings.notchOpacity = value
                    accentColor: Colors.primary
                }
            }

            SettingCard {
                label: "Pill opacity  •  " + Math.round(BarSettings.pillOpacity * 100) + "%"
                Layout.fillWidth: true
                content: StyledSlider {
                    from: 0.05; to: 1.0; stepSize: 0.05
                    value: BarSettings.pillOpacity
                    onMoved: BarSettings.pillOpacity = value
                    accentColor: Colors.primary
                }
            }

            SettingCard {
                label: "Corner radius  •  " + BarSettings.pillRadius + "px"
                Layout.fillWidth: true
                content: StyledSlider {
                    from: 0; to: 24; stepSize: 1
                    value: BarSettings.pillRadius
                    onMoved: BarSettings.pillRadius = value
                    accentColor: Colors.primary
                }
            }

            Item { implicitHeight: 8 }
        }
    }

    // ════════════════════════════════════════════════════════════════
    // PAGE: Network
    // ════════════════════════════════════════════════════════════════
    Component {
        id: cNetwork
        ColumnLayout {
            spacing: 18

            SectionTitle { text: "Network" }

            Rectangle {
                Layout.fillWidth: true
                height: 68
                radius: 14
                color: Qt.rgba(
                    Colors.surfaceContainer.r,
                    Colors.surfaceContainer.g,
                    Colors.surfaceContainer.b, 0.7)
                Behavior on color { ColorAnimation { duration: 200 } }

                Row {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 14
                    Text {
                        text: NetworkInfo.wifiIcon
                        font.pixelSize: 26
                        color: NetworkInfo.connected ? Colors.green : Colors.error
                        anchors.verticalCenter: parent.verticalCenter
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2
                        Text {
                            text: NetworkInfo.connected ? NetworkInfo.ssid : "Not connected"
                            color: Colors.overBackground
                            font.pixelSize: 14
                            Behavior on color { ColorAnimation { duration: 200 } }
                        }
                        Text {
                            text: NetworkInfo.connected ? "Signal: " + NetworkInfo.strength + "%" : "No WiFi"
                            color: Colors.outline
                            font.pixelSize: 12
                        }
                    }
                }
            }

            ActionButton {
                label: "Open nm-applet"
                Layout.fillWidth: true
                onActivated: {
                    var p = Qt.createQmlObject('import Quickshell.Io; Process {}', parent)
                    p.command = ["bash", "-c", "nm-applet &"]
                    p.running = true
                }
            }
            ActionButton {
                label: "Restart NetworkManager"
                Layout.fillWidth: true
                onActivated: {
                    var p = Qt.createQmlObject('import Quickshell.Io; Process {}', parent)
                    p.command = ["bash", "-c", "systemctl restart NetworkManager"]
                    p.running = true
                }
            }

            Item { implicitHeight: 8 }
        }
    }

    // ════════════════════════════════════════════════════════════════
    // PAGE: Power
    // ════════════════════════════════════════════════════════════════
    Component {
        id: cPower
        ColumnLayout {
            spacing: 10

            SectionTitle { text: "Power" }

            Repeater {
                model: [
                    { label: "Lock",     icon: "󰌾", cmd: "hyprlock",              accent: Colors.green    },
                    { label: "Logout",   icon: "󰍃", cmd: "hyprctl dispatch exit",  accent: Colors.yellow   },
                    { label: "Reboot",   icon: "󰑓", cmd: "systemctl reboot",       accent: Colors.secondary},
                    { label: "Shutdown", icon: "⏻",  cmd: "systemctl poweroff",     accent: Colors.error    }
                ]
                delegate: Rectangle {
                    Layout.fillWidth: true
                    height: 50
                    radius: 12
                    color: pwh.containsMouse
                        ? Qt.rgba(modelData.accent.r, modelData.accent.g, modelData.accent.b, 0.18)
                        : Qt.rgba(Colors.surfaceContainer.r, Colors.surfaceContainer.g, Colors.surfaceContainer.b, 0.6)
                    Behavior on color { ColorAnimation { duration: 100 } }

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 18
                        spacing: 14
                        Text {
                            text: modelData.icon
                            font.pixelSize: 18
                            color: modelData.accent
                            anchors.verticalCenter: parent.verticalCenter
                            Behavior on color { ColorAnimation { duration: 200 } }
                        }
                        Text {
                            text: modelData.label
                            color: Colors.overBackground
                            font.pixelSize: 14
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    MouseArea {
                        id: pwh
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

            Item { implicitHeight: 8 }
        }
    }
}
