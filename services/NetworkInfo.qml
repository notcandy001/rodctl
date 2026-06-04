pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool connected: false
    property string ssid: ""
    property int strength: 0   // 0-100

    // Nerd-font WiFi strength icons
    readonly property string wifiIcon: {
        if (!connected) return "󰤭"          // disconnected
        if (strength >= 75) return "󰤨"     // full
        if (strength >= 50) return "󰤥"     // good
        if (strength >= 25) return "󰤢"     // weak
        return "󰤟"                          // very weak
    }

    // Poll every 10 seconds
    Timer {
        interval: 10000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            wifiProc.running = true
        }
    }

    Process {
        id: wifiProc
        running: false
        command: ["bash", "-c",
            "nmcli -t -f active,ssid,signal dev wifi 2>/dev/null | grep '^yes' | head -1"]
        stdout: StdioCollector {
            onStreamFinished: {
                var line = this.text.trim()
                if (line === "") {
                    root.connected = false
                    root.ssid = ""
                    root.strength = 0
                    return
                }
                // format: yes:SSID:signal
                var parts = line.split(":")
                root.connected = true
                root.ssid = parts.length >= 2 ? parts[1] : ""
                root.strength = parts.length >= 3 ? parseInt(parts[2]) || 0 : 0
            }
        }
    }
}
