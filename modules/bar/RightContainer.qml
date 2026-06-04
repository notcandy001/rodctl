import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.modules.settings

Row {

    spacing: 10

    // ── WiFi pill ────────────────────────────────────────────────
    Rectangle {
        id: wifiPill
        width: wifiRow.width + 16
        height: 28
        radius: 14
        color: wifiHover.containsMouse ? "#44ffffff" : "#2aFFFFFF"

        Behavior on color { ColorAnimation { duration: 120 } }

        Row {
            id: wifiRow
            anchors.centerIn: parent
            spacing: 5

            Text {
                text: NetworkInfo.wifiIcon
                font.pixelSize: 14
                color: NetworkInfo.connected ? "white" : "#ff6b6b"
            }

            Text {
                text: NetworkInfo.ssid !== "" ? NetworkInfo.ssid : "Offline"
                font.pixelSize: 12
                color: "white"
                visible: NetworkInfo.ssid !== ""
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
        width: 32
        height: 32
        radius: 16
        color: powerHover.containsMouse ? "#55ff6b6b" : "#33ff6b6b"

        Behavior on color { ColorAnimation { duration: 120 } }

        Text {
            anchors.centerIn: parent
            text: "⏻"
            font.pixelSize: 15
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
