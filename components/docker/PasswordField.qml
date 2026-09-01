import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    property alias text: input.text
    property string placeholder: ""
    property bool passwordMode: false
    property bool revealed: false
    property bool enabled: true

    signal accepted()

    implicitHeight: 44
    radius: 12
    color: "#151612"
    opacity: enabled ? 1 : 0.55

    border.width: input.activeFocus ? 1 : 0
    border.color: "#d5a84f"

    RowLayout {
        anchors {
            fill: parent
            leftMargin: 12
            rightMargin: 7
        }

        spacing: 8

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: input.text === ""
                text: root.placeholder
                color: "#65675f"
                font.pixelSize: 11
            }

            TextInput {
                id: input
                anchors.fill: parent
                enabled: root.enabled
                verticalAlignment: TextInput.AlignVCenter
                color: "#ece8dc"
                font.pixelSize: 12
                clip: true

                echoMode:
                    root.passwordMode && !root.revealed
                        ? TextInput.Password
                        : TextInput.Normal

                passwordCharacter: "●"
                selectionColor: "#d5a84f"
                selectedTextColor: "#11120f"

                Keys.onReturnPressed: root.accepted()
                Keys.onEnterPressed: root.accepted()
            }
        }

        Rectangle {
            visible: root.passwordMode
            Layout.preferredWidth: visible ? 34 : 0
            Layout.preferredHeight: 34
            radius: 9
            color: eyeMouse.containsMouse ? "#292a24" : "transparent"

            Text {
                anchors.centerIn: parent
                text: root.revealed ? "󰈈" : "󰈉"
                color: "#ece8dc"
                font.pixelSize: 15
                font.family: "JetBrainsMono Nerd Font"
            }

            MouseArea {
                id: eyeMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.revealed = !root.revealed
                    input.forceActiveFocus()
                }
            }
        }
    }
}
