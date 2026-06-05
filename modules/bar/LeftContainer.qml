import QtQuick
import Quickshell.Io
import qs.theme

Row {
    signal launcherRequested()
    spacing: 10

    // Launcher button
    Rectangle {
        width: 32; height: 32; radius: 16
        color: lh.containsMouse ? Colors.pillHover : Colors.pillBg
        Behavior on color { ColorAnimation { duration: 120 } }
        Text {
            anchors.centerIn: parent
            text: "󰣇"
            font.pixelSize: 16
            color: Colors.overBackground
            Behavior on color { ColorAnimation { duration: 200 } }
        }
        MouseArea { id: lh; anchors.fill: parent; hoverEnabled: true; onClicked: launcherRequested() }
    }

    // Pinned apps
    Repeater {
        model: pinnedApps
        delegate: Rectangle {
            width: 28; height: 28; radius: BarSettings.pillRadius
            color: ah.containsMouse ? Colors.pillHover : Colors.pillBg
            Behavior on color { ColorAnimation { duration: 120 } }
            Text {
                anchors.centerIn: parent
                text: model.icon
                font.pixelSize: 15
                color: Colors.overBackground
                Behavior on color { ColorAnimation { duration: 200 } }
            }
            MouseArea {
                id: ah; anchors.fill: parent; hoverEnabled: true
                onClicked: {
                    var p = Qt.createQmlObject('import Quickshell.Io; Process {}', parent)
                    p.command = ["bash", "-c", model.exec + " &"]
                    p.running = true
                }
            }
        }
    }

    ListModel {
        id: pinnedApps
        Component.onCompleted: {
            append({ icon: "󰖟", exec: "firefox",  tooltip: "Firefox"  })
            append({ icon: "󰊠", exec: "kitty",    tooltip: "Terminal" })
            append({ icon: "󰷏", exec: "dolphin",  tooltip: "Files"    })
            append({ icon: "",  exec: "code",     tooltip: "VSCode"   })
        }
    }
}
