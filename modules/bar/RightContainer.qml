import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.modules.settings
import qs.services

Row {
    spacing: 10

    // ── Settings Pill ───────────────────────────────────────────
    Rectangle {
        width: 38
        height: 38
        radius: 19
        color: settingsHover.containsMouse ? "#44ffffff" : "#2aFFFFFF"

        Behavior on color { ColorAnimation { duration: 120 } }

        Text {
            anchors.centerIn: parent
            text: ""
            font.pixelSize: 18
            color: "white"
        }

        MouseArea {
            id: settingsHover
            anchors.fill: parent
            hoverEnabled: true
            onClicked: SettingsWindow.open("general")
        }
    }

    // ── WiFi pill ────────────────────────────────────────────────
    Rectangle {
        id: wifiPill
        width: wifiRow.width + 24
        height: 38
        radius: 19
        color: wifiHover.containsMouse ? "#44ffffff" : "#2aFFFFFF"

        Behavior on color { ColorAnimation { duration: 120 } }

        Row {
            id: wifiRow
            anchors.centerIn: parent
            spacing: 8

            Text {
                text: NetworkInfo.wifiIcon
                font.pixelSize: 16
                color: NetworkInfo.connected ? "white" : "#ff6b6b"
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: NetworkInfo.ssid !== "" ? NetworkInfo.ssid : "Offline"
                font.pixelSize: 14
                color: "white"
                visible: NetworkInfo.ssid !== ""
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        MouseArea {
            id: wifiHover
            anchors.fill: parent
            hoverEnabled: true
            onClicked: SettingsWindow.open("network")
        }
    }

    // ── Power button ─────────────────────────────────────────────
    Rectangle {
        width: 38
        height: 38
        radius: 19
        color: powerHover.containsMouse ? "#55ff6b6b" : "#33ff6b6b"

        Behavior on color { ColorAnimation { duration: 120 } }

        Text {
            anchors.centerIn: parent
            text: "⏻"
            font.pixelSize: 18
            color: "#ff8888"
        }

        MouseArea {
            id: powerHover
            anchors.fill: parent
            hoverEnabled: true
            onClicked: SettingsWindow.open("power")
        }
    }
}
