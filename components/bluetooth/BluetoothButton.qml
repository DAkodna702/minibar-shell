import QtQuick

Rectangle {
    id: root

    required property var service
    property bool panelOpen: false

    signal clicked()

    implicitWidth:
        root.service.connectedCount > 0
            ? 42
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

    border.width: root.panelOpen ? 1 : 0
    border.color: root.service.enabled
        ? "#d5a84f"
        : "#566173"

    Behavior on color {
        ColorAnimation { duration: 140 }
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
            text: {
                if (!root.service.enabled)
                    return "󰂲"

                if (root.service.connectedCount > 0)
                    return "󰂱"

                return "󰂯"
            }

            color: {
                if (root.service.connectedCount > 0)
                    return "#9eb39d"

                if (root.service.enabled)
                    return "#d5a84f"

                return "#65675f"
            }

            font.pixelSize: 16
            font.family: "JetBrainsMono Nerd Font"
        }

        Text {
            visible: root.service.connectedCount > 0
            text: root.service.connectedCount
            color: "#ece8dc"
            font.pixelSize: 9
            font.bold: true
        }
    }

    MouseArea {
        id: buttonMouse

        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor

        onClicked: function(mouse) {
            if (mouse.button === Qt.MiddleButton)
                root.service.togglePower()
            else
                root.clicked()

            mouse.accepted = true
        }
    }
}
