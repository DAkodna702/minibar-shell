import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

Scope {
    id: root
    required property var service

    Variants {
        model: Quickshell.screens
        PanelWindow {
            id: layer
            required property var modelData
            readonly property var monitor: Hyprland.monitorFor(layer.screen)
            readonly property string monitorName: monitor ? monitor.name : ""
            readonly property int monitorIndex: root.service.indexForName(monitorName)
            readonly property int level: root.service.brightnessFor(monitorName)
            screen: modelData
            visible: root.service.identifying || level < 100
            color: "transparent"
            anchors { top: true; bottom: true; left: true; right: true }
            WlrLayershell.namespace: "minibar-monitor-layer-" + monitorName
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.exclusiveZone: -1
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            mask: Region {}

            Rectangle {
                anchors.fill: parent
                color: "black"
                opacity: root.service.identifying ? 0 : Math.max(0, (100 - layer.level) / 100 * 0.72)
            }

            Rectangle {
                anchors.centerIn: parent
                width: Math.min(390, parent.width * 0.48); height: 235; radius: 28
                visible: root.service.identifying
                color: "#f20b0c0a"; border.width: 3; border.color: "#d5a84f"
                Column {
                    anchors.centerIn: parent; spacing: 8
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: layer.monitorIndex + 1; color: "#d5a84f"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 90; font.weight: Font.Bold }
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: root.service.friendlyName(root.service.monitors[layer.monitorIndex]); color: "#ece8dc"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 15 }
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: layer.monitorName; color: "#8a8c82"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11 }
                }
            }
        }
    }
}
