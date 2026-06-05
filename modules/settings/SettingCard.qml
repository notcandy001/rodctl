import QtQuick
import QtQuick.Layouts
import qs.theme

ColumnLayout {
    property string label: ""
    default property alias content: contentSlot.data
    spacing: 8

    Text {
        text: label
        color: Colors.outline
        font.pixelSize: 12
        Behavior on color { ColorAnimation { duration: 200 } }
    }

    Item {
        id: contentSlot
        Layout.fillWidth: true
        implicitHeight: childrenRect.height
    }
}
