import QtQuick
import qs.theme

Rectangle {
    property string label: ""
    signal activated()

    height: 40
    radius: 10
    color: h.containsMouse
        ? Qt.rgba(Colors.overBackground.r, Colors.overBackground.g, Colors.overBackground.b, 0.14)
        : Qt.rgba(Colors.surfaceContainer.r, Colors.surfaceContainer.g, Colors.surfaceContainer.b, 0.6)
    Behavior on color { ColorAnimation { duration: 100 } }

    Text {
        anchors.centerIn: parent
        text: label
        color: Colors.overBackground
        font.pixelSize: 13
        Behavior on color { ColorAnimation { duration: 200 } }
    }
    MouseArea { id: h; anchors.fill: parent; hoverEnabled: true; onClicked: activated() }
}
