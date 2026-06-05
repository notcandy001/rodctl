pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.services
import qs.theme

// ─────────────────────────────────────────────────────────────────────────────
//  Workspaces  –  workspace dots for the bar
//
//  Shows up to `maxShown` workspace dots.
//  Active workspace is highlighted with primary color.
//  Occupied workspaces get a small filled dot.
//  Scroll up/down to switch.
// ─────────────────────────────────────────────────────────────────────────────

Item {
    id: root

    property int maxShown: 9
    property int dotSize:  8
    property int dotSpacing: 6
    property int activeDotSize: 12

    // Track which workspaces are occupied
    property var occupied: ({})
    property int activeId: HyprlandData.focusedWorkspaceId

    implicitWidth:  row.implicitWidth  + 16
    implicitHeight: row.implicitHeight + 8

    // Refresh on any Hyprland event
    Connections {
        target: HyprlandData
        function onStateChanged() { root._refresh() }
    }
    Component.onCompleted: _refresh()

    function _refresh() {
        var map = {}
        var wsList = HyprlandData.workspaces
        if (!wsList) return
        for (var i = 0; i < wsList.values.length; i++) {
            var ws = wsList.values[i]
            if (ws && ws.lastIpcObject && ws.lastIpcObject.windows > 0)
                map[ws.id] = true
        }
        occupied = map
        activeId = HyprlandData.focusedWorkspaceId
    }

    // Background pill
    Rectangle {
        anchors.fill: parent
        radius: parent.height / 2
        color: Colors.pillBg
    }

    // Wheel to switch workspace
    WheelHandler {
        onWheel: event => {
            if (event.angleDelta.y < 0)
                HyprlandData.dispatch("workspace r+1")
            else
                HyprlandData.dispatch("workspace r-1")
        }
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: root.dotSpacing

        Repeater {
            model: root.maxShown
            delegate: Item {
                required property int index
                readonly property int wsId: index + 1
                readonly property bool isActive:   root.activeId === wsId
                readonly property bool isOccupied: root.occupied[wsId] === true

                width:  isActive ? root.activeDotSize : root.dotSize
                height: isActive ? root.activeDotSize : root.dotSize
                anchors.verticalCenter: parent.verticalCenter

                Behavior on width  { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                Behavior on height { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                Rectangle {
                    anchors.centerIn: parent
                    width:  parent.width
                    height: parent.height
                    radius: width / 2

                    color: {
                        if (isActive)   return Colors.primary
                        if (isOccupied) return Qt.rgba(
                            Colors.overBackground.r,
                            Colors.overBackground.g,
                            Colors.overBackground.b, 0.55)
                        return Qt.rgba(
                            Colors.outlineVariant.r,
                            Colors.outlineVariant.g,
                            Colors.outlineVariant.b, 0.40)
                    }

                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: HyprlandData.dispatch("workspace " + wsId)
                }
            }
        }
    }
}
