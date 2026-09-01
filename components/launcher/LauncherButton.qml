import QtQuick

Rectangle {
    id: root

    signal clicked()

    property bool launcherOpen: false

    implicitWidth: 34
    implicitHeight: 28

    radius: 9

    color: {
        if (root.launcherOpen)
            return "#25251f"

        if (buttonMouse.containsMouse)
            return "#1d1e1a"

        return "transparent"
    }

    border.width:
        root.launcherOpen ? 1 : 0

    border.color: "#d5a84f"

    Behavior on color {
        ColorAnimation {
            duration: 140
        }
    }

    Text {
        anchors.centerIn: parent

        text: "󰣇"

        color:
            root.launcherOpen
                ? "#d5a84f"
                : "#ece8dc"

        font.pixelSize: 17
        font.family:
            "JetBrainsMono Nerd Font"
    }

    MouseArea {
        id: buttonMouse

        anchors.fill: parent

        hoverEnabled: true
        acceptedButtons: Qt.LeftButton

        cursorShape:
            Qt.PointingHandCursor

        onClicked: function(mouse) {
            root.clicked()
            mouse.accepted = true
        }
    }
}
