import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    property string query: ""

    ColumnLayout {
        anchors.fill: parent
        spacing: 20

        // ===== SEARCH BAR =====
        Rectangle {
            Layout.fillWidth: true
            height: 44
            radius: 22
            color: "#1a1a1a"

            TextField {
                id: searchField
                anchors.fill: parent
                anchors.margins: 12
                placeholderText: "Search..."
                color: "white"
                background: null

                onTextChanged: query = text
                focus: true
            }
        }

        // ===== APP LIST =====
        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: column.height
            clip: true

            Column {
                id: column
                width: parent.width
                spacing: 10

                Repeater {
                    model: appModel

                    delegate: Rectangle {
                        width: parent.width
                        height: 60
                        radius: 16
                        color: "#121212"

                        visible: model.name.toLowerCase()
                                 .includes(query.toLowerCase())

                        Row {
                            anchors.fill: parent
                            anchors.margins: 16
                            spacing: 16

                            Image {
                                source: model.icon
                                width: 32
                                height: 32
                                fillMode: Image.PreserveAspectFit
                            }

                            Column {
                                spacing: 4

                                Text {
                                    text: model.name
                                    color: "white"
                                    font.pixelSize: 15
                                }

                                Text {
                                    text: model.comment
                                    color: "#888"
                                    font.pixelSize: 12
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: Qt.openUrlExternally(model.exec)
                        }
                    }
                }
            }
        }
    }

    // ===== MANUAL DESKTOP APP MODEL =====
    ListModel {
        id: appModel

        Component.onCompleted: {
            // simple fallback example
            append({
                name: "Firefox",
                icon: "firefox",
                exec: "firefox",
                comment: "Web Browser"
            })

            append({
                name: "Dolphin",
                icon: "system-file-manager",
                exec: "dolphin",
                comment: "File Manager"
            })

            append({
                name: "Terminal",
                icon: "utilities-terminal",
                exec: "kitty",
                comment: "Terminal Emulator"
            })
        }
    }
}
