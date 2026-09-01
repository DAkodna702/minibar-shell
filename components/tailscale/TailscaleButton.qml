import QtQuick

Rectangle {
    id: root

    required property var service

    implicitWidth: 46
    implicitHeight: 28
    radius: 9

    color: buttonMouse.containsMouse
        ? "#1d1e1a"
        : "transparent"
    border.width: 1
    border.color: root.service.connected
        ? "#668165"
        : root.service.statusError
            ? "#a95551"
            : "#34362f"

    Row {
        anchors.centerIn: parent
        spacing: 5

        Text {
            text: "TS"
            color: root.service.connected
                ? "#91ad8f"
                : "#85877d"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 9
            font.weight: Font.DemiBold
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 6
            height: 6
            radius: 3
            color: root.service.busy
                ? "#d5a84f"
                : root.service.connected
                    ? "#78a176"
                    : "#55574f"

            SequentialAnimation on opacity {
                running: root.service.busy
                loops: Animation.Infinite
                NumberAnimation { to: 0.25; duration: 450 }
                NumberAnimation { to: 1; duration: 450 }
            }
        }
    }

    MouseArea {
        id: buttonMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.service.toggle()
    }
}
