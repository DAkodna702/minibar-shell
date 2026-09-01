import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    required property var container
    required property var service

    signal logsRequested(var container)
    signal consoleRequested(var container)
    signal removeRequested(var container)

    implicitHeight:
        contentColumn.implicitHeight + 22

    radius: 16
    color: cardMouse.containsMouse
        ? "#20211c"
        : "#151612"

    border.width: 1
    border.color:
        service.statusColor(container)

    ColumnLayout {
        id: contentColumn

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top

            leftMargin: 11
            rightMargin: 11
            topMargin: 11
        }

        spacing: 9

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Rectangle {
                Layout.preferredWidth: 40
                Layout.preferredHeight: 40

                radius: 12
                color: "#34362f"

                Text {
                    anchors.centerIn: parent

                    text: "󰡨"

                    color:
                        service.statusColor(
                            root.container
                        )

                    font.pixelSize: 20
                    font.family:
                        "JetBrainsMono Nerd Font"
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    Layout.fillWidth: true

                    text: root.container.name

                    color: "#ece8dc"
                    font.pixelSize: 13
                    font.bold: true

                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true

                    text: root.container.image

                    color: "#aaa89d"
                    font.pixelSize: 10

                    elide: Text.ElideMiddle
                }

                Text {
                    text:
                        service.statusLabel(
                            root.container
                        )

                    color:
                        service.statusColor(
                            root.container
                        )

                    font.pixelSize: 9
                    font.bold: true
                }
            }

            Text {
                text: root.container.shortId

                color: "#65675f"
                font.pixelSize: 9
            }
        }

        Flow {
            Layout.fillWidth: true

            visible:
                root.container.ports.length > 0

            spacing: 5

            Repeater {
                model: root.container.ports

                delegate: Rectangle {
                    required property var modelData

                    width:
                        portText.implicitWidth + 14

                    height: 24
                    radius: 9

                    color: "#25251f"

                    Text {
                        id: portText

                        anchors.centerIn: parent

                        text:
                            modelData.hostPort
                            + " → "
                            + modelData.containerPort

                        color: "#d5a84f"
                        font.pixelSize: 9
                    }
                }
            }
        }

        Flow {
            Layout.fillWidth: true
            spacing: 6

            ActionButton {
                text:
                    root.container.isRunning
                        ? "Reiniciar"
                        : "Iniciar"

                icon:
                    root.container.isRunning
                        ? "󰜉"
                        : "󰐊"

                enabled: !service.actionRunning

                onTriggered: {
                    service.executeAction(
                        root.container,
                        root.container.isRunning
                            ? "restart"
                            : "start"
                    )
                }
            }

            ActionButton {
                visible:
                    root.container.isRunning
                    || root.container.isPaused

                text:
                    root.container.isPaused
                        ? "Reanudar"
                        : "Pausar"

                icon:
                    root.container.isPaused
                        ? "󰐊"
                        : "󰏤"

                enabled: !service.actionRunning

                onTriggered: {
                    service.executeAction(
                        root.container,
                        root.container.isPaused
                            ? "unpause"
                            : "pause"
                    )
                }
            }

            ActionButton {
                visible:
                    root.container.isRunning
                    || root.container.isPaused

                text: "Detener"
                icon: "󰓛"

                enabled: !service.actionRunning

                onTriggered: {
                    service.executeAction(
                        root.container,
                        "stop"
                    )
                }
            }

            ActionButton {
                text: "Logs"
                icon: "󰆍"

                onTriggered: {
                    root.logsRequested(
                        root.container
                    )
                }
            }

            ActionButton {
                text: "Consola"
                icon: "󰆍"

                enabled:
                    root.container.isRunning
                    && !root.container.isPaused

                onTriggered: {
                    root.consoleRequested(
                        root.container
                    )
                }
            }

            ActionButton {
                text: "Eliminar"
                icon: "󰆴"
                danger: true

                enabled: !service.actionRunning

                onTriggered: {
                    root.removeRequested(
                        root.container
                    )
                }
            }
        }
    }

    MouseArea {
        id: cardMouse

        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
    }

    component ActionButton: Rectangle {
        id: actionButton

        property string text: ""
        property string icon: ""
        property bool danger: false
        property bool enabled: true

        signal triggered()

        width:
            buttonRow.implicitWidth + 18

        height: 30
        radius: 10

        opacity:
            actionButton.enabled
                ? 1
                : 0.4

        color: {
            if (!actionButton.enabled)
                return "#151612"

            if (buttonMouse.containsMouse) {
                return actionButton.danger
                    ? "#4a3038"
                    : "#25251f"
            }

            return "#171814"
        }

        Row {
            id: buttonRow

            anchors.centerIn: parent
            spacing: 5

            Text {
                text: actionButton.icon

                color:
                    actionButton.danger
                        ? "#d66d68"
                        : "#d5a84f"

                font.pixelSize: 13
                font.family:
                    "JetBrainsMono Nerd Font"
            }

            Text {
                text: actionButton.text

                color:
                    actionButton.danger
                        ? "#d66d68"
                        : "#d7d3c7"

                font.pixelSize: 10
            }
        }

        MouseArea {
            id: buttonMouse

            anchors.fill: parent
            hoverEnabled: true

            enabled: actionButton.enabled

            cursorShape:
                enabled
                    ? Qt.PointingHandCursor
                    : Qt.ForbiddenCursor

            onClicked: {
                actionButton.triggered()
            }
        }
    }
}
