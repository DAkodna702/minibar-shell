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

    border.width: root.panelOpen ? 1 : 0
    border.color: "#9eb39d"

    Behavior on color {
        ColorAnimation { duration: 140 }
    }

    Text {
        anchors.centerIn: parent
        text: "󰌆"
        color: root.service.activeTunnelIds.length > 0
            ? "#9eb39d"
            : "#ece8dc"
        font.pixelSize: 16
        font.family: "JetBrainsMono Nerd Font"
    }

    MouseArea {
        id: buttonMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
