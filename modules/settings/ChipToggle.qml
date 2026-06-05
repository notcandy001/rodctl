import QtQuick
import qs.theme

Rectangle {
    property string label:  ""
    property bool   active: false
    signal activated()

    height: 30
    width:  t.implicitWidth + 22
    radius: 8
    color: active
        ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.28)
        : (h.containsMouse
            ? Qt.rgba(Colors.overBackground.r, Colors.overBackground.g, Colors.overBackground.b, 0.12)
            : Qt.rgba(Colors.surfaceContainer.r, Colors.surfaceContainer.g, Colors.surfaceContainer.b, 0.7))
    Behavior on color { ColorAnimation { duration: 110 } }

    Text {
        id: t
        anchors.centerIn: parent
        text: label
        color: active ? Colors.primary : Colors.outline
        font.pixelSize: 12
        font.bold: active
        Behavior on color { ColorAnimation { duration: 110 } }
    }
    MouseArea { id: h; anchors.fill: parent; hoverEnabled: true; onClicked: activated() }
}
