import QtQuick
import QtQuick.Layouts

ColumnLayout {
    property string title: ""
    default property alias content: inner.data
    spacing: 8

    Text {
        text: title
        color: "#aaaaaa"
        font.pixelSize: 12
    }

    Item {
        id: inner
        Layout.fillWidth: true
        implicitHeight: childrenRect.height
    }
}
