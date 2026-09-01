import QtQuick

Rectangle {
    id: root

    required property var service

    property bool panelOpen: false

    signal clicked()

    implicitWidth:
        service.runningCount > 0
            ? 43
            : 30

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

    border.color: {
        if (!service.dockerAvailable)
            return "#d66d68"

        if (service.runningCount > 0)
            return "#d5a84f"

        return "#3a3b34"
    }

    Row {
        anchors.centerIn: parent
        spacing: 4

        Text {
            text: "󰡨"

            color: {
                if (!root.service.dockerAvailable)
                    return "#d66d68"

                if (root.service.runningCount > 0)
                    return "#d5a84f"

                return "#ece8dc"
            }

            font.pixelSize: 16
            font.family:
                "JetBrainsMono Nerd Font"
        }

        Text {
            visible:
                root.service.runningCount > 0

            text:
                root.service.runningCount > 9
                    ? "9+"
                    : root.service.runningCount

            color: "#ece8dc"
            font.pixelSize: 9
            font.bold: true
        }
    }

    MouseArea {
        id: buttonMouse

        anchors.fill: parent
        hoverEnabled: true

        cursorShape:
            Qt.PointingHandCursor

        onClicked: function(mouse) {
            root.clicked()
            mouse.accepted = true
        }
    }
}
