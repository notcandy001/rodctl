import QtQuick
import Quickshell.Io
import qs.theme
import qs.modules.settings
import qs.services

Row {
    spacing: 10

    // WiFi pill
    Rectangle {
        height: 28
        width: wifiRow.implicitWidth + 18
        radius: BarSettings.pillRadius
        color: wh.containsMouse ? Colors.pillHover : Colors.pillBg
        Behavior on color { ColorAnimation { duration: 120 } }

        Row {
            id: wifiRow
            anchors.centerIn: parent
            spacing: 5
            Text {
                text: NetworkInfo.wifiIcon
                font.pixelSize: 14
                color: NetworkInfo.connected ? Colors.green : Colors.error
                Behavior on color { ColorAnimation { duration: 200 } }
            }
            Text {
                text: NetworkInfo.ssid
                font.pixelSize: 12
                color: Colors.overBackground
                visible: NetworkInfo.connected && NetworkInfo.ssid !== ""
                Behavior on color { ColorAnimation { duration: 200 } }
            }
        }
        MouseArea { id: wh; anchors.fill: parent; hoverEnabled: true; onClicked: SettingsWindow.open("network") }
    }

    // Power button
    Rectangle {
        width: 32; height: 32; radius: 16
        color: ph.containsMouse
            ? Qt.rgba(Colors.error.r, Colors.error.g, Colors.error.b, 0.28)
            : Qt.rgba(Colors.error.r, Colors.error.g, Colors.error.b, 0.14)
        Behavior on color { ColorAnimation { duration: 120 } }
        Text {
            anchors.centerIn: parent
            text: "⏻"
            font.pixelSize: 15
            color: Colors.error
            Behavior on color { ColorAnimation { duration: 200 } }
        }
        MouseArea { id: ph; anchors.fill: parent; hoverEnabled: true; onClicked: SettingsWindow.open("power") }
    }
}
