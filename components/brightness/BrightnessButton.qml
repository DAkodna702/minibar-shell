import QtQuick

Rectangle {
    id: root

    required property var service

    property bool panelOpen: false
    property int brightnessStep: 5

    signal clicked()

    implicitWidth: 30
    implicitHeight: 28

    radius: 9

    color: {
        if (root.panelOpen)
            return "#433b2b"

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

        text:
            root.service.available
                ? root.service.brightnessIcon(
                    root.service.primaryBrightness
                )
                : "󰃞"

        color:
            root.service.available
                ? "#d5a84f"
                : "#65675f"

        font.pixelSize: 16
        font.family:
            "JetBrainsMono Nerd Font"
    }

    MouseArea {
        id: buttonMouse

        anchors.fill: parent
        hoverEnabled: true

        acceptedButtons:
            Qt.LeftButton
            | Qt.MiddleButton

        cursorShape:
            Qt.PointingHandCursor

        onClicked: function(mouse) {
            if (mouse.button === Qt.LeftButton) {
                root.clicked()
            } else if (mouse.button === Qt.MiddleButton) {
                root.service.changePrimaryBrightness(
                    -root.brightnessStep
                )
            }

            mouse.accepted = true
        }

        onWheel: function(wheel) {
            if (wheel.angleDelta.y > 0) {
                root.service.changePrimaryBrightness(
                    root.brightnessStep
                )
            } else if (wheel.angleDelta.y < 0) {
                root.service.changePrimaryBrightness(
                    -root.brightnessStep
                )
            }

            wheel.accepted = true
        }
    }
}
