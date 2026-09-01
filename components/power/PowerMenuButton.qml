import QtQuick

Rectangle {
    id: root

    signal clicked()

    implicitWidth: 34
    implicitHeight: 28

    radius: 9

    color: buttonMouse.containsMouse
        ? "#1d1e1a"
        : "transparent"

    border.width: buttonMouse.containsMouse ? 1 : 0

    border.color: "#d66d68"

    Behavior on color {
        ColorAnimation {
            duration: 140
        }
    }

    Text {
        anchors.centerIn: parent

        text: "󰐥"
        color: "#d66d68"

        font.pixelSize: 16
        font.family: "JetBrainsMono Nerd Font"
    }

    MouseArea {
        id: buttonMouse

        anchors.fill: parent

        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        cursorShape: Qt.PointingHandCursor

        onClicked: function(mouse) {
            root.clicked()
            mouse.accepted = true
        }
    }
}
