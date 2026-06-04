import QtQuick

Rectangle {
    property string label: ""
    signal activated()

    width: parent ? parent.width : 200
    height: 38
    radius: 10
    color: btnHover.containsMouse ? "#33ffffff" : "#18ffffff"
    Behavior on color { ColorAnimation { duration: 100 } }

    Text {
        anchors.centerIn: parent
        text: label
        color: "white"
        font.pixelSize: 13
    }

    MouseArea {
        id: btnHover
        anchors.fill: parent
        hoverEnabled: true
        onClicked: activated()
    }
}
