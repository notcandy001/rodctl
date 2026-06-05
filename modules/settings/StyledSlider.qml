import QtQuick
import QtQuick.Controls
import qs.theme

Slider {
    property color accentColor: Colors.primary

    implicitWidth:  200
    implicitHeight: 28

    background: Rectangle {
        x: parent.leftPadding
        y: parent.topPadding + parent.availableHeight / 2 - height / 2
        width: parent.availableWidth
        height: 4
        radius: 2
        color: Qt.rgba(Colors.outlineVariant.r, Colors.outlineVariant.g, Colors.outlineVariant.b, 0.5)

        Rectangle {
            width: parent.parent.visualPosition * parent.width
            height: 4
            radius: 2
            color: accentColor
            Behavior on color { ColorAnimation { duration: 200 } }
        }
    }

    handle: Rectangle {
        x: parent.leftPadding + parent.visualPosition * (parent.availableWidth - width)
        y: parent.topPadding + parent.availableHeight / 2 - height / 2
        width: 16; height: 16; radius: 8
        color: accentColor
        Behavior on color { ColorAnimation { duration: 200 } }
        Rectangle {
            anchors.centerIn: parent
            width: 6; height: 6; radius: 3
            color: Colors.overPrimary
        }
    }
}
