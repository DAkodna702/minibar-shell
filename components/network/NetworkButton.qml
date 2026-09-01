import QtQuick

Rectangle {
    id: root

    required property var service

    property bool panelOpen: false

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

        text: root.service.mainIcon()

        color:
            root.service.connectionType === "none"
                ? "#65675f"
                : "#d5a84f"

        font.pixelSize: 15
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
