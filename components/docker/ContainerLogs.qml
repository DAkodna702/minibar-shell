import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property var service

    property var container: null
    property var lines: []
    property bool paused: false
    property bool followOutput: true
    property int maximumLines: 2000

    signal backRequested()

    function openContainer(targetContainer) {
        root.container = targetContainer
        root.lines = []
        root.paused = false
        root.followOutput = true

        service.startLogs(targetContainer)
    }

    function appendLine(line) {
        if (root.paused)
            return

        let updated = root.lines.slice()

        updated.push(String(line))

        if (updated.length > root.maximumLines) {
            updated = updated.slice(
                updated.length - root.maximumLines
            )
        }

        root.lines = updated

        if (root.followOutput) {
            Qt.callLater(function() {
                logsList.positionViewAtEnd()
            })
        }
    }

    function closeLogs() {
        service.stopLogs()
        root.container = null
        root.lines = []
    }

    Connections {
        target: root.service

        function onLogsLineReceived(line) {
            root.appendLine(line)
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        RowLayout {
            Layout.fillWidth: true

            Rectangle {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32

                radius: 10
                color: backMouse.containsMouse
                    ? "#292a24"
                    : "#171814"

                Text {
                    anchors.centerIn: parent

                    text: "󰁍"
                    color: "#ece8dc"

                    font.pixelSize: 15
                    font.family:
                        "JetBrainsMono Nerd Font"
                }

                MouseArea {
                    id: backMouse

                    anchors.fill: parent
                    hoverEnabled: true

                    cursorShape:
                        Qt.PointingHandCursor

                    onClicked: {
                        root.closeLogs()
                        root.backRequested()
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true

                Text {
                    text:
                        root.container
                            ? root.container.name
                            : "Logs"

                    color: "#ece8dc"
                    font.pixelSize: 14
                    font.bold: true
                }

                Text {
                    text: "Logs en tiempo real"

                    color: "#65675f"
                    font.pixelSize: 9
                }
            }

            SmallButton {
                text:
                    root.paused
                        ? "Continuar"
                        : "Pausar"

                onClicked: {
                    root.paused = !root.paused
                }
            }

            SmallButton {
                text: "Limpiar"

                onClicked: {
                    root.lines = []
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true

            radius: 14
            color: "#11120f"

            border.width: 1
            border.color: "#34362f"

            ListView {
                id: logsList

                anchors {
                    fill: parent
                    margins: 10
                }

                model: root.lines

                spacing: 2
                clip: true

                delegate: Text {
                    required property string modelData

                    width: logsList.width

                    text: modelData

                    color: "#ece8dc"
                    font.pixelSize: 10
                    font.family: "Monospace"

                    wrapMode: Text.WrapAnywhere
                    textFormat: Text.PlainText
                }

                onMovementStarted: {
                    root.followOutput = false
                }

                onAtYEndChanged: {
                    if (atYEnd)
                        root.followOutput = true
                }
            }
        }
    }

    component SmallButton: Rectangle {
        id: smallButton

        property string text: ""

        signal clicked()

        width:
            buttonText.implicitWidth + 18

        height: 30
        radius: 10

        color: buttonMouse.containsMouse
            ? "#25251f"
            : "#171814"

        Text {
            id: buttonText

            anchors.centerIn: parent

            text: smallButton.text
            color: "#ece8dc"

            font.pixelSize: 10
        }

        MouseArea {
            id: buttonMouse

            anchors.fill: parent
            hoverEnabled: true

            cursorShape:
                Qt.PointingHandCursor

            onClicked: smallButton.clicked()
        }
    }
}
