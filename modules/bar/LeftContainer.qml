import QtQuick
import QtQuick.Layouts
import Quickshell.Io

Row {

    signal launcherRequested()

    spacing: 10

    // ── Launcher button (moon icon) ──────────────────────────────
    Rectangle {
        width: 32
        height: 32
        radius: 16
        color: launcherHover.containsMouse ? "#66ffffff" : "#44ffffff"

        Behavior on color { ColorAnimation { duration: 120 } }

        Text {
            anchors.centerIn: parent
            text: "󰣇"              // nerd-font moon / arch icon
            font.pixelSize: 16
            color: "white"
        }

        MouseArea {
            id: launcherHover
            anchors.fill: parent
            hoverEnabled: true
            onClicked: launcherRequested()
        }
    }

    // ── Pinned app icons ─────────────────────────────────────────
    Repeater {
        model: pinnedApps

        delegate: Rectangle {
            width: 28
            height: 28
            radius: 14
            color: appHover.containsMouse ? "#44ffffff" : "#26ffffff"

            Behavior on color { ColorAnimation { duration: 120 } }

            // Icon text (nerd font glyphs)
            Text {
                anchors.centerIn: parent
                text: model.icon
                font.pixelSize: 15
                color: "white"
            }

            MouseArea {
                id: appHover
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    var p = Qt.createQmlObject('import Quickshell.Io; Process {}', parent)
                    p.command = ["bash", "-c", model.exec + " &"]
                    p.running = true
                }
            }
        }
    }

    // ── App data ─────────────────────────────────────────────────
    ListModel {
        id: pinnedApps
        Component.onCompleted: {
            append({ icon: "󰖟",  exec: "firefox",  tooltip: "Firefox"  })
            append({ icon: "󰊠",  exec: "kitty",    tooltip: "Terminal" })
            append({ icon: "󰷏",  exec: "dolphin",  tooltip: "Files"    })
            append({ icon: "",  exec: "code",     tooltip: "VSCode"   })
        }
    }
}
