import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Rectangle {
    id: root
    property bool checked: false
    signal toggled(bool checked)

    width: 44
    height: 24
    radius: 12
    color: checked ? "#60d394" : "#33ffffff"

    Rectangle {
        id: thumb
        width: 20
        height: 20
        radius: 10
        color: "white"
        x: checked ? (root.width - width - 2) : 2

        Behavior on x {
            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            root.checked = !root.checked
            toggled(root.checked)
        }
    }
}
