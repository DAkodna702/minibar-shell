import QtQuick

import Quickshell.Services.Pipewire

Rectangle {
    id: root

    signal clicked()

    property bool panelOpen: false
    property int volumeStep: 3
    property int maxVolume: 100

    readonly property var sink:
        Pipewire.defaultAudioSink

    readonly property int volume:
        sink && sink.audio
            ? Math.round(sink.audio.volume * 100)
            : 0

    readonly property bool muted:
        sink && sink.audio
            ? sink.audio.muted
            : false

    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }

    implicitWidth: 30
    implicitHeight: 28

    radius: 9

    color: {
        if (root.panelOpen)
            return "#25251f"

        if (buttonMouse.containsMouse)
            return "#1d1e1a"

        return "transparent"
    }

    border.width: root.panelOpen ? 1 : 0
    border.color: "#d5a84f"

    Behavior on color {
        ColorAnimation {
            duration: 140
        }
    }

    function speakerIcon() {
        if (!root.sink || !root.sink.audio)
            return "󰖁"

        if (root.muted || root.volume === 0)
            return "󰖁"

        if (root.volume < 34)
            return "󰕿"

        if (root.volume < 67)
            return "󰖀"

        return "󰕾"
    }

    function changeVolume(delta) {
        if (!root.sink || !root.sink.audio)
            return

        if (root.sink.audio.muted)
            root.sink.audio.muted = false

        const nextVolume = Math.max(
            0,
            Math.min(
                root.maxVolume,
                root.volume + delta
            )
        )

        root.sink.audio.volume =
            nextVolume / 100
    }

    function toggleMute() {
        if (!root.sink || !root.sink.audio)
            return

        root.sink.audio.muted =
            !root.sink.audio.muted
    }

    Text {
        anchors.centerIn: parent

        text: root.speakerIcon()

        color: root.muted
            ? "#65675f"
            : "#d5a84f"

        font.pixelSize: 15
        font.family: "JetBrainsMono Nerd Font"
    }

    MouseArea {
        id: buttonMouse

        anchors.fill: parent
        hoverEnabled: true

        acceptedButtons:
            Qt.LeftButton
            | Qt.MiddleButton

        cursorShape: Qt.PointingHandCursor

        onClicked: function(mouse) {
            if (mouse.button === Qt.LeftButton) {
                root.clicked()
            } else if (mouse.button === Qt.MiddleButton) {
                root.toggleMute()
            }

            mouse.accepted = true
        }

        onWheel: function(wheel) {
            if (wheel.angleDelta.y > 0)
                root.changeVolume(root.volumeStep)
            else if (wheel.angleDelta.y < 0)
                root.changeVolume(-root.volumeStep)

            wheel.accepted = true
        }
    }
}
