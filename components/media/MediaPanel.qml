import QtQuick
import QtQuick.Layouts

import Quickshell
import Quickshell.Wayland

Item {
    id: root
    property var targetScreen: null

    required property var service

    readonly property bool opened: mediaWindow.visible

    property real barOne: 0.18
    property real barTwo: 0.42
    property real barThree: 0.27
    property real barFour: 0.58
    property real barFive: 0.34

    function open() {
        mediaWindow.visible = true
    }

    function close() {
        mediaWindow.visible = false
    }

    function toggle() {
        mediaWindow.visible
            ? root.close()
            : root.open()
    }

    SequentialAnimation {
        running: root.service.playing && mediaWindow.visible
        loops: Animation.Infinite

        ParallelAnimation {
            NumberAnimation { target: root; property: "barOne"; to: 0.72; duration: 320; easing.type: Easing.InOutSine }
            NumberAnimation { target: root; property: "barTwo"; to: 0.25; duration: 320; easing.type: Easing.InOutSine }
            NumberAnimation { target: root; property: "barThree"; to: 0.88; duration: 320; easing.type: Easing.InOutSine }
            NumberAnimation { target: root; property: "barFour"; to: 0.38; duration: 320; easing.type: Easing.InOutSine }
            NumberAnimation { target: root; property: "barFive"; to: 0.64; duration: 320; easing.type: Easing.InOutSine }
        }

        ParallelAnimation {
            NumberAnimation { target: root; property: "barOne"; to: 0.22; duration: 360; easing.type: Easing.InOutSine }
            NumberAnimation { target: root; property: "barTwo"; to: 0.82; duration: 360; easing.type: Easing.InOutSine }
            NumberAnimation { target: root; property: "barThree"; to: 0.35; duration: 360; easing.type: Easing.InOutSine }
            NumberAnimation { target: root; property: "barFour"; to: 0.78; duration: 360; easing.type: Easing.InOutSine }
            NumberAnimation { target: root; property: "barFive"; to: 0.26; duration: 360; easing.type: Easing.InOutSine }
        }
    }

    PanelWindow {
        id: mediaWindow
        screen: root.targetScreen

        visible: false
        color: "transparent"

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        WlrLayershell.namespace: "minibar-media-panel"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.exclusiveZone: -1
        WlrLayershell.keyboardFocus:
            mediaWindow.visible
                ? WlrKeyboardFocus.OnDemand
                : WlrKeyboardFocus.None

        Rectangle {
            anchors.fill: parent
            color: "#73050605"

            MouseArea {
                anchors.fill: parent
                onClicked: root.close()
            }
        }

        Rectangle {
            id: card

            anchors {
                top: parent.top
                horizontalCenter: parent.horizontalCenter
                topMargin: 52
            }

            width: Math.min(390, parent.width - 24)
            height: 382
            radius: 18
            color: "#f50b0c0a"
            border.width: 1
            border.color: "#4a4b42"
            clip: true

            scale: mediaWindow.visible ? 1 : 0.96
            opacity: mediaWindow.visible ? 1 : 0

            Behavior on scale {
                NumberAnimation {
                    duration: 220
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on opacity {
                NumberAnimation { duration: 160 }
            }

            MouseArea { anchors.fill: parent }

            Rectangle {
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                }

                height: 3
                color: "#d5a84f"
            }

            ColumnLayout {
                anchors {
                    fill: parent
                    margins: 16
                }

                spacing: 12

                RowLayout {
                    Layout.fillWidth: true

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        Text {
                            text: "NOW PLAYING"
                            color: "#ece8dc"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                            font.letterSpacing: 1.8
                        }

                        Text {
                            text: root.service.playerName.toUpperCase()
                            color: "#74766d"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 8
                            font.letterSpacing: 1.2
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 30
                        Layout.preferredHeight: 30
                        radius: 9
                        color: closeMouse.containsMouse
                            ? "#292a24"
                            : "#151612"
                        border.width: 1
                        border.color: "#36372f"

                        Text {
                            anchors.centerIn: parent
                            text: "×"
                            color: "#c9c6ba"
                            font.pixelSize: 18
                        }

                        MouseArea {
                            id: closeMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.close()
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: "#31322c"
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 142
                    spacing: 14

                    Rectangle {
                        Layout.preferredWidth: 142
                        Layout.preferredHeight: 142
                        radius: 12
                        color: "#191a16"
                        border.width: 1
                        border.color: "#3b3c34"
                        clip: true

                        Image {
                            anchors.fill: parent
                            source: root.service.artUrl
                            sourceSize: Qt.size(256, 256)
                            asynchronous: true
                            fillMode: Image.PreserveAspectCrop
                            visible: status === Image.Ready
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: root.service.artUrl === ""
                            text: "󰎆"
                            color: "#d5a84f"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 46
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 4

                        Item { Layout.fillHeight: true }

                        Text {
                            Layout.fillWidth: true
                            text: root.service.title
                            color: "#f0ece1"
                            elide: Text.ElideRight
                            maximumLineCount: 2
                            wrapMode: Text.Wrap
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 15
                            font.weight: Font.DemiBold
                        }

                        Text {
                            Layout.fillWidth: true
                            text: root.service.artist
                            color: "#aaa89d"
                            elide: Text.ElideRight
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 11
                        }

                        Text {
                            Layout.fillWidth: true
                            text: root.service.album
                            visible: text !== ""
                            color: "#73756c"
                            elide: Text.ElideRight
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 9
                        }

                        Item { Layout.fillHeight: true }

                        Row {
                            spacing: 5

                            Repeater {
                                model: [
                                    root.barOne,
                                    root.barTwo,
                                    root.barThree,
                                    root.barFour,
                                    root.barFive
                                ]

                                Rectangle {
                                    required property real modelData

                                    width: 4
                                    height: 28 * (
                                        root.service.active
                                            ? modelData
                                            : 0.12
                                    )
                                    radius: 2
                                    color: "#d5a84f"
                                    anchors.bottom: parent.bottom

                                    Behavior on height {
                                        NumberAnimation { duration: 180 }
                                    }
                                }
                            }
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    visible: root.service.active

                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 12

                        Rectangle {
                            id: progressTrack

                            anchors {
                                left: parent.left
                                right: parent.right
                                verticalCenter: parent.verticalCenter
                            }

                            height: 4
                            radius: 2
                            color: "#2d2f29"

                            Rectangle {
                                width: parent.width * (
                                    root.service.currentLength > 0
                                        ? Math.min(
                                            1,
                                            root.service.currentPosition
                                                / root.service.currentLength
                                        )
                                        : 0
                                )
                                height: parent.height
                                radius: 2
                                color: "#d5a84f"

                                Behavior on width {
                                    NumberAnimation { duration: 430 }
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: root.service.player
                                && root.service.player.canSeek
                            cursorShape: enabled
                                ? Qt.PointingHandCursor
                                : Qt.ArrowCursor

                            onClicked: function(mouse) {
                                root.service.seekTo(
                                    mouse.x / width
                                )
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: root.service.formatTime(
                                root.service.currentPosition
                            )
                            color: "#77796f"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 9
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: root.service.formatTime(
                                root.service.currentLength
                            )
                            color: "#77796f"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 9
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 64

                    Row {
                        anchors.centerIn: parent
                        spacing: 18

                        Rectangle {
                            width: 42
                            height: 42
                            radius: 13
                            color: previousMouse.containsMouse
                                ? "#24251f"
                                : "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: "󰒮"
                                color: root.service.player
                                        && root.service.player.canGoPrevious
                                    ? "#cbc8bc"
                                    : "#505249"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 21
                            }

                            MouseArea {
                                id: previousMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                enabled: root.service.active
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.service.previous()
                            }
                        }

                        Rectangle {
                            width: 56
                            height: 56
                            radius: 18
                            color: playMouse.containsMouse
                                ? "#e1b75f"
                                : "#d5a84f"

                            Text {
                                anchors.centerIn: parent
                                text: root.service.playing
                                    ? "󰏤"
                                    : "󰐊"
                                color: "#0b0c09"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 24
                            }

                            MouseArea {
                                id: playMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                enabled: root.service.active
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.service.togglePlaying()
                            }
                        }

                        Rectangle {
                            width: 42
                            height: 42
                            radius: 13
                            color: nextMouse.containsMouse
                                ? "#24251f"
                                : "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: "󰒭"
                                color: root.service.player
                                        && root.service.player.canGoNext
                                    ? "#cbc8bc"
                                    : "#505249"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 21
                            }

                            MouseArea {
                                id: nextMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                enabled: root.service.active
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.service.next()
                            }
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    visible: !root.service.active
                    text: "No hay un reproductor activo"
                    color: "#77796f"
                    horizontalAlignment: Text.AlignHCenter
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 11
                }
            }
        }
    }
}
