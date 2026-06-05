import QtQuick
import qs.theme

Text {
    property alias text: t.text
    Text {
        id: t
        color: Colors.overBackground
        font.pixelSize: 18
        font.bold: true
        Behavior on color { ColorAnimation { duration: 200 } }
    }
    implicitWidth:  t.implicitWidth
    implicitHeight: t.implicitHeight
}
