import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property var service

    property var container: null
    property string outputText: ""
    property bool commandRunning: false

    signal backRequested()

    function openContainer(targetContainer) {
        root.container = targetContainer
        root.outputText = ""
        root.commandRunning = false

        commandInput.text = ""
        focusTimer.restart()
    }

    function closeConsole() {
        if (root.service.consoleProcess.running)
            root.service.consoleProcess.running = false

        root.container = null
        root.outputText = ""
        root.commandRunning = false
        commandInput.text = ""
    }

    function runCommand() {
        const command = commandInput.text.trim()

        if (
            !root.container
            || command === ""
            || root.commandRunning
        ) {
            return
        }

        if (!root.container.isRunning) {
            root.outputText +=
                "\n[El contenedor no está ejecutándose]\n"

            return
        }

        if (root.container.isPaused) {
            root.outputText +=
                "\n[El contenedor está pausado]\n"

            return
        }

        root.commandRunning = true

        root.outputText +=
            (root.outputText === "" ? "" : "\n")
            + "$ "
            + command
            + "\n"

        root.service.runConsoleCommand(
            root.container,
            command
        )
    }

    Connections {
        target: root.service.consoleProcess

        function onExited(exitCode, exitStatus) {
            /*
             * Estos son los nombres corregidos:
             *
             * stdoutCollector.text
             * stderrCollector.text
             */
            const stdoutText =
                root.service
                    .consoleProcess
                    .stdoutCollector
                    .text

            const stderrText =
                root.service
                    .consoleProcess
                    .stderrCollector
                    .text

            if (
                stdoutText
                && stdoutText !== ""
            ) {
                root.outputText += stdoutText

                if (!stdoutText.endsWith("\n"))
                    root.outputText += "\n"
            }

            if (
                stderrText
                && stderrText !== ""
            ) {
                root.outputText += stderrText

                if (!stderrText.endsWith("\n"))
                    root.outputText += "\n"
            }

            root.outputText +=
                "[código de salida: "
                + exitCode
                + "]\n"

            root.commandRunning = false
            commandInput.text = ""

            Qt.callLater(function() {
                outputFlickable.contentY =
                    Math.max(
                        0,
                        outputFlickable.contentHeight
                        - outputFlickable.height
                    )

                commandInput.forceActiveFocus()
            })
        }
    }

    Timer {
        id: focusTimer

        interval: 80
        repeat: false

        onTriggered: {
            commandInput.forceActiveFocus()
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        // =====================================================
        // CABECERA
        // =====================================================

        RowLayout {
            Layout.fillWidth: true
            spacing: 9

            Rectangle {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32

                radius: 10

                color:
                    backMouse.containsMouse
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
                        root.closeConsole()
                        root.backRequested()
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    Layout.fillWidth: true

                    text:
                        root.container
                            ? root.container.name
                            : "Consola"

                    color: "#ece8dc"
                    font.pixelSize: 14
                    font.bold: true

                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true

                    text:
                        root.container
                            ? root.container.image
                            : "Ejecuta comandos mediante /bin/sh"

                    color: "#65675f"
                    font.pixelSize: 9

                    elide: Text.ElideMiddle
                }
            }

            Text {
                visible:
                    root.commandRunning

                text: "Ejecutando…"
                color: "#d5a84f"
                font.pixelSize: 10
            }

            Rectangle {
                Layout.preferredWidth:
                    clearText.implicitWidth + 18

                Layout.preferredHeight: 30

                radius: 10

                color:
                    clearMouse.containsMouse
                        ? "#292a24"
                        : "#171814"

                Text {
                    id: clearText

                    anchors.centerIn: parent

                    text: "Limpiar"
                    color: "#ece8dc"

                    font.pixelSize: 10
                }

                MouseArea {
                    id: clearMouse

                    anchors.fill: parent
                    hoverEnabled: true

                    cursorShape:
                        Qt.PointingHandCursor

                    onClicked: {
                        root.outputText = ""
                    }
                }
            }
        }

        // =====================================================
        // SALIDA DE LA CONSOLA
        // =====================================================

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true

            radius: 14
            color: "#11120f"

            border.width: 1
            border.color: "#34362f"

            Flickable {
                id: outputFlickable

                anchors {
                    fill: parent
                    margins: 11
                }

                contentWidth: width
                contentHeight:
                    Math.max(
                        height,
                        outputTextItem.implicitHeight
                    )

                clip: true

                flickableDirection:
                    Flickable.VerticalFlick

                boundsBehavior:
                    Flickable.StopAtBounds

                Text {
                    id: outputTextItem

                    width: outputFlickable.width

                    text:
                        root.outputText !== ""
                            ? root.outputText
                            : (
                                root.container
                                    ? "Consola de "
                                        + root.container.name
                                        + "\n\nEscribe un comando abajo."
                                    : "Selecciona un contenedor."
                            )

                    color:
                        root.outputText !== ""
                            ? "#ece8dc"
                            : "#65675f"

                    font.pixelSize: 10
                    font.family: "Monospace"

                    wrapMode: Text.WrapAnywhere
                    textFormat: Text.PlainText
                }
            }
        }

        // =====================================================
        // ENTRADA DEL COMANDO
        // =====================================================

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 48

            radius: 13
            color: "#151612"

            border.width:
                commandInput.activeFocus
                    ? 1
                    : 0

            border.color: "#d5a84f"

            opacity:
                root.container
                && root.container.isRunning
                && !root.container.isPaused
                    ? 1
                    : 0.55

            RowLayout {
                anchors {
                    fill: parent
                    margins: 7
                }

                spacing: 8

                Text {
                    text: "$"

                    color: "#9eb39d"
                    font.pixelSize: 14
                    font.family: "Monospace"
                    font.bold: true
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Text {
                        anchors.verticalCenter:
                            parent.verticalCenter

                        visible:
                            commandInput.text === ""

                        text:
                            root.container
                            && root.container.isRunning
                            && !root.container.isPaused
                                ? "Escribe un comando…"
                                : "El contenedor no está disponible"

                        color: "#65675f"
                        font.pixelSize: 11
                        font.family: "Monospace"
                    }

                    TextInput {
                        id: commandInput

                        anchors.fill: parent

                        verticalAlignment:
                            TextInput.AlignVCenter

                        enabled:
                            root.container
                            && root.container.isRunning
                            && !root.container.isPaused
                            && !root.commandRunning

                        color: "#ece8dc"

                        font.pixelSize: 12
                        font.family: "Monospace"

                        selectionColor: "#d5a84f"
                        selectedTextColor: "#11120f"

                        clip: true

                        Keys.onReturnPressed: {
                            root.runCommand()
                        }

                        Keys.onEnterPressed: {
                            root.runCommand()
                        }

                        Keys.onEscapePressed: {
                            root.closeConsole()
                            root.backRequested()
                        }
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 40
                    Layout.fillHeight: true

                    radius: 10

                    color: {
                        if (!runMouse.enabled)
                            return "#292a24"

                        if (runMouse.containsMouse)
                            return "#e1b75f"

                        return "#d5a84f"
                    }

                    opacity:
                        runMouse.enabled ? 1 : 0.45

                    Text {
                        anchors.centerIn: parent

                        text:
                            root.commandRunning
                                ? "…"
                                : "󰘧"

                        color:
                            runMouse.enabled
                                ? "#11120f"
                                : "#65675f"

                        font.pixelSize: 15
                        font.family:
                            "JetBrainsMono Nerd Font"
                    }

                    MouseArea {
                        id: runMouse

                        anchors.fill: parent
                        hoverEnabled: true

                        enabled:
                            root.container
                            && root.container.isRunning
                            && !root.container.isPaused
                            && !root.commandRunning
                            && commandInput.text.trim() !== ""

                        cursorShape:
                            enabled
                                ? Qt.PointingHandCursor
                                : Qt.ForbiddenCursor

                        onClicked: {
                            root.runCommand()
                        }
                    }
                }
            }
        }
    }
}
