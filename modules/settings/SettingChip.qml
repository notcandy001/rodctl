import QtQuick

Rectangle {
    property string label: ""
    signal activated()

    height: 28
    width: chipText.width + 20
    radius: 8
    color: chipHover.containsMouse ? "#33ffffff" : "#18ffffff"
    Behavior on color { ColorAnimation { duration: 100 } }

    Text {
        id: chipText
        anchors.centerIn: parent
        text: label
        color: "#aaaaaa"
        font.pixelSize: 12
    }
    MouseArea {
        id: chipHover
        anchors.fill: parent
        hoverEnabled: true
        onClicked: activated()
    }
}
