import QtQuick

Rectangle {
    id: root

    property bool panelOpen: false
    property int itemCount: 0

    signal clicked()

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

    border.width:
        root.panelOpen ? 1 : 0

    border.color: "#d5a84f"

    Behavior on color {
        ColorAnimation {
            duration: 140
        }
    }

    Text {
        anchors.centerIn: parent

        text: "󰅌"

        color: root.panelOpen
            ? "#d5a84f"
            : "#ece8dc"

        font.pixelSize: 15
        font.family:
            "JetBrainsMono Nerd Font"
    }

    Rectangle {
        visible: root.itemCount > 0

        anchors {
            right: parent.right
            top: parent.top

            rightMargin: -3
            topMargin: -4
        }

        width: 14
        height: 14
        radius: 7

        color: "#d5a84f"

        Text {
            anchors.centerIn: parent

            text:
                root.itemCount > 9
                    ? "9+"
                    : root.itemCount

            color: "#11120f"

            font.pixelSize: 8
            font.bold: true
        }
    }

    MouseArea {
        id: buttonMouse

        anchors.fill: parent
        hoverEnabled: true

        acceptedButtons:
            Qt.LeftButton

        cursorShape:
            Qt.PointingHandCursor

        onClicked: function(mouse) {
            root.clicked()
            mouse.accepted = true
        }
    }
}
