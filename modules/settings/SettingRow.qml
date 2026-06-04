import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Rectangle {
    id: root
    property string label: "Setting"

    // Use default property to allow adding the control as a child
    default property alias control: controlItem.data

    height: 48
    width: parent ? parent.width : 400
    color: hoverArea.containsMouse ? "#15ffffff" : "transparent"

    Behavior on color { ColorAnimation { duration: 150 } }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        spacing: 0

        Text {
            text: root.label
            color: "#ddd"
            font.pixelSize: 14
            Layout.fillWidth: true
        }

        Item {
            id: controlItem
            Layout.preferredWidth: 120
            Layout.preferredHeight: 32
        }
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
    }
}
