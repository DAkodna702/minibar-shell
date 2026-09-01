import QtQuick

Rectangle {
    id: root

    property int unreadCount: 0
    property bool centerOpen: false

    signal clicked()

    implicitWidth: unreadCount > 0 ? 40 : 30
    implicitHeight: 28

    radius: 9

    color: {
        if (centerOpen)
            return "#25251f"

        if (buttonMouse.containsMouse)
            return "#1d1e1a"

        return "transparent"
    }

    border.width: centerOpen ? 1 : 0
    border.color: "#d5a84f"

    Behavior on color {
        ColorAnimation {
            duration: 140
        }
    }

    Behavior on implicitWidth {
        NumberAnimation {
            duration: 160
            easing.type: Easing.OutCubic
        }
    }

    Row {
        anchors.centerIn: parent
        spacing: 3

        Text {
            text: root.unreadCount > 0 ? "󰂚" : "󰂜"

            color: root.unreadCount > 0
                ? "#d5a84f"
                : "#ece8dc"

            font.pixelSize: 15
            font.family: "JetBrainsMono Nerd Font"
        }

        Text {
            visible: root.unreadCount > 0

            text: root.unreadCount > 99
                ? "99+"
                : root.unreadCount

            color: "#ece8dc"
            font.pixelSize: 10
            font.bold: true
        }
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
