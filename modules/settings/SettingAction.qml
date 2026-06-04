import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

SettingRow {
    id: root
    property string actionLabel: "Click me"
    signal activated()

    // We can't assign to 'control' anymore, so we just add the child
    // Since SettingRow has a default property alias for control,
    // this will be placed inside the controlItem Item.
    Text {
        text: "›"
        color: "#888"
        font.pixelSize: 20
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.activated()
    }
}
