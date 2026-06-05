import QtQuick

Rectangle {
    property string label: ""

    height: 28
    width: chipText.width + 20
    radius: 8
    color: "#44ffffff"

    Text {
        id: chipText
        anchors.centerIn: parent
        text: label
        color: "white"
        font.pixelSize: 12
        font.bold: true
    }
}
