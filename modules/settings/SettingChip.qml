import QtQuick

Rectangle {
    property string label: ""
    property bool active: false
    signal activated()

    height: 28
    width: chipText.width + 20
    radius: 8
    color: active ? "#44ffffff" : (chipHover.containsMouse ? "#33ffffff" : "#18ffffff")
    Behavior on color { ColorAnimation { duration: 100 } }

    Text {
        id: chipText
        anchors.centerIn: parent
        text: label
        color: active ? "white" : "#aaaaaa"
        font.pixelSize: 12
        font.bold: active
    }
    MouseArea {
        id: chipHover
        anchors.fill: parent
        hoverEnabled: true
        enabled: !active
        onClicked: activated()
    }
}
