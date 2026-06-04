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
    property string activePage: "general"
    property int selectedIndex: 0
    property string searchQuery: ""

    readonly property var sectionModel: [
        { id: "general",    icon: "󰒓", label: "General"    },
        { id: "appearance", icon: "󰉼", label: "Appearance" },
        { id: "network",    icon: "󰤨", label: "Network"    },
        { id: "power",      icon: "⏻",  label: "Power"      },
        { id: "compositor", icon: "⚙",  label: "Compositor" }
    ]

    property var filteredSections: {
        if (searchQuery === "") return sectionModel;
        var query = searchQuery.toLowerCase();
        return sectionModel.filter(item => item.label.toLowerCase().includes(query));
    }

    onSearchQueryChanged: {
        selectedIndex = 0;
        if (filteredSections.length > 0) {
            activePage = filteredSections[0].id;
        }
    }

    function open(page) {
        if (page !== undefined) {
            activePage = page
            searchQuery = "" // Reset search when opening specific page
            for (let i = 0; i < sectionModel.length; i++) {
                if (sectionModel[i].id === page) {
                    selectedIndex = i;
                    break;
                }
            }
        } else {
            if (filteredSections.length > 0) {
                activePage = filteredSections[selectedIndex].id
            }
        }
        visible = true
    }

    function close() {
        visible = false
    }

    WlrLayershell {
        id: win
        visible: root.visible
        layer: WlrLayer.Overlay
        anchors.centerIn: Quickshell.screens[0] // Approximation
        implicitWidth:  900
        implicitHeight: 650
        color: "transparent"
        exclusiveZone: 0
        keyboardFocus: WlrKeyboardFocus.OnDemand

        Keys.onEscapePressed: root.close()

        Rectangle {
            anchors.fill: parent
            radius: 12
            color: "#1a1a1a"
            border.color: "#33ffffff"
            border.width: 1
            clip: true

            RowLayout {
                anchors.fill: parent
                spacing: 8
                anchors.margins: 16

                // ── Sidebar ───────────────────────────────────────
                ColumnLayout {
                    Layout.preferredWidth: 200
                    Layout.maximumWidth: 200
                    Layout.fillHeight: true
                    spacing: 8

                    // Search input
                    TextField {
                        id: searchInput
                        Layout.fillWidth: true
                        placeholderText: "Search..."
                        placeholderTextColor: "#888"
                        color: "white"
                        font.pixelSize: 14
                        background: Rectangle {
                            color: "#22ffffff"
                            radius: 8
                        }
                        onTextChanged: root.searchQuery = text
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        // Sliding highlight
                        Rectangle {
                            id: tabHighlight
                            width: parent.width
                            height: 48
                            radius: 8
                            color: "#33ffffff"
                            y: root.selectedIndex * (48 + 4)
                            visible: root.filteredSections.length > 0
                            Behavior on y {
                                NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                            }
                        }

                        Column {
                            id: sidebar
                            width: parent.width
                            spacing: 4

                            Repeater {
                                model: root.filteredSections

                                delegate: Item {
                                    width: sidebar.width
                                    height: 48
                                    
                                    property bool isActive: index === root.selectedIndex

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 12
                                        anchors.rightMargin: 12
                                        spacing: 12

                                        Text {
                                            text: modelData.icon
                                            color: isActive ? "white" : "#aaa"
                                            font.pixelSize: 18
                                            Behavior on color { ColorAnimation { duration: 150 } }
                                        }
                                        Text {
                                            text: modelData.label
                                            color: isActive ? "white" : "#aaa"
                                            font.pixelSize: 15
                                            font.bold: isActive
                                            Behavior on color { ColorAnimation { duration: 150 } }
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: {
                                            root.selectedIndex = index;
                                            root.activePage = modelData.id;
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 40
                        radius: 8
                        color: closeHover.containsMouse ? "#33ff6b6b" : "transparent"
                        border.color: "#18ff6b6b"
                        border.width: 1

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 8
                            Text { text: "✕"; color: "#ff8888"; font.pixelSize: 14 }
                            Text { text: "Close"; color: "#ff8888"; font.pixelSize: 14; font.bold: true }
                        }

                        MouseArea {
                            id: closeHover
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: root.close()
                        }
                    }
                }

                // Vertical separator
                Rectangle {
                    Layout.fillHeight: true
                    width: 1
                    color: "#22ffffff"
                }

                // ── Content area ──────────────────────────────────
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Loader {
                        id: panelLoader
                        anchors.fill: parent
                        anchors.margins: 16
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
                        
                        opacity: status === Loader.Ready ? 1 : 0
                        Behavior on opacity {
                            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
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
            spacing: 24

            Text {
                text: "General"
                color: "white"
                font.pixelSize: 28
                font.bold: true
            }

            SettingsSection {
                title: "Bar Layout"
                Layout.fillWidth: true

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
                        width: 160
                    }
                }
                SettingRow {
                    label: "Left Margin"
                    control: Slider {
                        from: 0; to: 40; stepSize: 1
                        value: BarSettings.leftMargin
                        onMoved: BarSettings.leftMargin = value
                        width: 160
                    }
                }
                SettingRow {
                    label: "Right Margin"
                    control: Slider {
                        from: 0; to: 40; stepSize: 1
                        value: BarSettings.rightMargin
                        onMoved: BarSettings.rightMargin = value
                        width: 160
                    }
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
            spacing: 24

            Text {
                text: "Appearance"
                color: "white"
                font.pixelSize: 28
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
                        width: 160
                    }
                }
                SettingRow {
                    label: "Pill Opacity"
                    control: Slider {
                        from: 0.1; to: 1.0; stepSize: 0.05
                        value: BarSettings.pillOpacity
                        onMoved: BarSettings.pillOpacity = value
                        width: 160
                    }
                }
                SettingRow {
                    label: "Corner Radius"
                    control: Slider {
                        from: 0; to: 24; stepSize: 1
                        value: BarSettings.pillRadius
                        onMoved: BarSettings.pillRadius = value
                        width: 160
                    }
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
            spacing: 24

            Text {
                text: "Network"
                color: "white"
                font.pixelSize: 28
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
            Item { Layout.fillHeight: true }
        }
    }

    // ════════════════════════════════════════════════════════════════
    // PAGE: Power
    // ════════════════════════════════════════════════════════════════
    Component {
        id: powerPage
        ColumnLayout {
            spacing: 24

            Text {
                text: "Power"
                color: "white"
                font.pixelSize: 28
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
                        p.command = ["bash", "-c", "hyprctl dispatch exit"]
                        p.running = true
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
                        var p = Qt.createQmlObject('import Quickshell.Io; Process {}', parent)
                        p.command = ["bash", "-c", "systemctl poweroff"]
                        p.running = true
                    }
                }
            }
            Item { Layout.fillHeight: true }
        }
    }

    // ════════════════════════════════════════════════════════════════
    // PAGE: Compositor
    // ════════════════════════════════════════════════════════════════
    Component {
        id: compositorPage
        ColumnLayout {
            spacing: 24

            Text {
                text: "Compositor"
                color: "white"
                font.pixelSize: 28
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
            Item { Layout.fillHeight: true }
        }
    }
}
