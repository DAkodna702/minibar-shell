import QtQuick

Rectangle {
    id: root

    property bool panelOpen: false
    property date now: new Date()

    signal clicked()

    implicitWidth: 126
    implicitHeight: 28
    radius: 8
    color: root.panelOpen
        ? "#25251f"
        : clockMouse.containsMouse
            ? "#1d1e1a"
            : "#12130f"
    border.width: 1
    border.color: root.panelOpen ? "#d5a84f" : "#34362f"

    Behavior on color { ColorAnimation { duration: 140 } }

    Row {
        anchors.centerIn: parent
        spacing: 7

        Text {
            text: Qt.formatDateTime(root.now, "hh:mm:ss")
            color: "#ece8dc"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 11
            font.weight: Font.DemiBold
        }

        Rectangle {
            width: 1
            height: 13
            color: "#3a3b34"
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: Qt.formatDateTime(root.now, "ddd dd")
            color: "#8f9086"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 9
        }
    }

    MouseArea {
        id: clockMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.now = new Date()
    }
}
