import QtQuick

Rectangle {
    id: root

    required property var service
    property bool panelOpen: false

    signal clicked()

    implicitWidth: root.service.active ? 246 : 34
    implicitHeight: 28

    radius: 8
    color: {
        if (root.panelOpen)
            return "#25251f"

        if (mainMouse.containsMouse)
            return "#1d1e1a"

        return "#12130f"
    }

    border.width: 1
    border.color: root.panelOpen
        ? "#d5a84f"
        : "#34362f"

    clip: true

    Behavior on implicitWidth {
        NumberAnimation {
            duration: 220
            easing.type: Easing.OutCubic
        }
    }

    Behavior on color {
        ColorAnimation { duration: 140 }
    }

    MouseArea {
        id: mainMouse

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: function(mouse) {
            root.clicked()
            mouse.accepted = true
        }
    }

    Text {
        anchors.centerIn: parent
        visible: !root.service.active

        text: "󰎆"
        color: root.panelOpen ? "#d5a84f" : "#918f84"
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 15
    }

    Row {
        anchors {
            fill: parent
            leftMargin: 8
            rightMargin: 6
        }

        visible: root.service.active
        spacing: 7

        Item {
            width: 16
            height: parent.height

            Row {
                anchors.centerIn: parent
                spacing: 2

                Repeater {
                    model: 3

                    Rectangle {
                        required property int index

                        width: 3
                        height: root.service.playing
                            ? [8, 15, 11][index]
                            : 4
                        radius: 2
                        color: "#d5a84f"
                        anchors.verticalCenter: parent.verticalCenter

                        SequentialAnimation on height {
                            running: root.service.playing
                            loops: Animation.Infinite

                            NumberAnimation {
                                to: [15, 7, 14][index]
                                duration: [300, 250, 340][index]
                                easing.type: Easing.InOutSine
                            }

                            NumberAnimation {
                                to: [7, 15, 6][index]
                                duration: [250, 330, 280][index]
                                easing.type: Easing.InOutSine
                            }
                        }

                        Behavior on height {
                            NumberAnimation { duration: 180 }
                        }
                    }
                }
            }
        }

        Item {
            width: 138
            height: parent.height
            clip: true

            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                spacing: -1

                Text {
                    width: parent.width
                    text: root.service.title
                    color: "#ece8dc"
                    elide: Text.ElideRight
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 10
                    font.weight: Font.Medium
                }

                Text {
                    width: parent.width
                    text: root.service.artist
                    color: "#8f9086"
                    elide: Text.ElideRight
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 8
                }
            }
        }

        Rectangle {
            width: 1
            height: 14
            anchors.verticalCenter: parent.verticalCenter
            color: "#34362f"
        }

        Text {
            width: 25
            height: parent.height
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            text: root.service.playing ? "󰏤" : "󰐊"
            color: root.service.active ? "#d5a84f" : "#56584f"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 13

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor

                onClicked: function(mouse) {
                    root.service.togglePlaying()
                    mouse.accepted = true
                }
            }
        }

        Text {
            width: 19
            height: parent.height
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            text: "󰒭"
            color: root.service.player
                    && root.service.player.canGoNext
                ? "#c9c6ba"
                : "#56584f"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 13

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor

                onClicked: function(mouse) {
                    root.service.next()
                    mouse.accepted = true
                }
            }
        }
    }
}
