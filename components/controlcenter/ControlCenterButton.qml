import QtQuick

import Quickshell.Services.Pipewire
import Quickshell.Services.UPower

Rectangle {
    id: root

    required property var networkService
    required property var systemService
    property bool panelOpen: false
    property int unreadCount: 0

    signal clicked()

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property int volume: sink && sink.audio
        ? Math.round(sink.audio.volume * 100)
        : 0
    readonly property int battery: UPower.displayDevice.ready
        ? Math.round(UPower.displayDevice.percentage * 100)
        : 0

    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }

    implicitWidth: 174
    implicitHeight: 28
    radius: 8
    color: root.panelOpen
        ? "#25251f"
        : buttonMouse.containsMouse
            ? "#1d1e1a"
            : "#12130f"
    border.width: 1
    border.color: root.panelOpen ? "#d5a84f" : "#34362f"

    Row {
        anchors.centerIn: parent
        spacing: 8

        Text {
            text: root.networkService ? root.networkService.mainIcon() : "󰤭"
            color: !root.networkService || root.networkService.connectionType === "none" ? "#5d5f57" : "#c9c6ba"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 13
        }
        Text {
            text: root.sink && root.sink.audio && root.sink.audio.muted ? "󰖁" : "󰕾"
            color: "#c9c6ba"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 13
        }
        Text {
            text: root.volume + "%"
            color: "#85877d"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 9
        }
        Text {
            text: "󰁹 " + (UPower.displayDevice.ready ? root.battery + "%" : "--")
            color: root.battery <= 15 ? "#d66d68" : "#9ea692"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 9
        }
        Rectangle { width: 1; height: 13; color: "#3a3b34"; anchors.verticalCenter: parent.verticalCenter }
        Text {
            text: root.unreadCount > 0 ? "󰂚" : "󰒓"
            color: root.unreadCount > 0 ? "#d5a84f" : root.panelOpen ? "#d5a84f" : "#ece8dc"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 14
        }
    }

    MouseArea {
        id: buttonMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
