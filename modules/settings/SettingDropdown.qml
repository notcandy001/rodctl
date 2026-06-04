import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Rectangle {
    id: root
    property string label: "Option"
    property string currentText: "Select..."
    property var options: []
    signal activated(string value)

    height: 32
    width: 120
    radius: 8
    color: "#1affffff"
    border.color: "#33ffffff"
    border.width: 1

    Text {
        anchors.centerIn: parent
        text: root.currentText
        color: "white"
        font.pixelSize: 13
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            // In a real app, this would open a Popup menu.
            // For this implementation, we'll simulate a simple cycle for demo purposes
            // unless the parent handles the menu logic.
            if (options.length > 0) {
                var currentIndex = options.indexOf(currentText)
                var nextIndex = (currentIndex + 1) % options.length
                var nextValue = options[nextIndex]
                currentText = nextValue
                activated(nextValue)
            }
        }
    }
}
