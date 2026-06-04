import QtQuick
import QtQuick.Layouts

ColumnLayout {
    property string title: "Section"
    spacing: 12

    Text {
        text: parent.title
        color: "#888"
        font.pixelSize: 12
        font.bold: true
        Layout.leftMargin: 16
        Layout.topMargin: 8
        Layout.bottomMargin: 4
    }

    Column {
        id: inner
        Layout.fillWidth: true
        spacing: 2
    }
}
