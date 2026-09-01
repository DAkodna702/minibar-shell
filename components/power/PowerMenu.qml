import QtQuick
import QtQuick.Layouts

import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Item {
    id: root
    property var targetScreen: null

    readonly property bool opened: overlay.visible

    function open() {
        overlay.visible = true
    }

    function close() {
        overlay.visible = false
    }

    function toggle() {
        overlay.visible ? close() : open()
    }

    function execute(processObject, command) {
        console.log("Ejecutando comando:", JSON.stringify(command))

        // Inicia directamente el comando.
        processObject.exec(command)

        // Cierra el menú después de enviar la acción.
        root.close()
    }

    // =========================================================
    // VENTANA FULLSCREEN
    // =========================================================

    PanelWindow {
        id: overlay
        screen: root.targetScreen

        visible: false
        color: "transparent"

        WlrLayershell.namespace: "minibar-power-menu"
        WlrLayershell.layer: WlrLayershell.Overlay
        WlrLayershell.exclusiveZone: -1

        WlrLayershell.keyboardFocus:
            overlay.visible
                ? WlrKeyboardFocus.Exclusive
                : WlrKeyboardFocus.None

        anchors {
            top: true
            left: true
            right: true
            bottom: true
        }

        // Fondo oscuro.
        Rectangle {
            anchors.fill: parent
            color: "#080b10"
            opacity: overlay.visible ? 0.68 : 0

            Behavior on opacity {
                NumberAnimation {
                    duration: 220
                    easing.type: Easing.OutCubic
                }
            }

            MouseArea {
                anchors.fill: parent

                onClicked: {
                    root.close()
                }
            }
        }

        // Tarjeta central.
        Rectangle {
            id: menuCard

            anchors.centerIn: parent

            width: powerGrid.implicitWidth + 48
            height: powerGrid.implicitHeight + 48

            radius: 22
            color: "#f70b0c0a"

            border.width: 1
            border.color: "#4a4b42"

            scale: overlay.visible ? 1.0 : 0.90
            opacity: overlay.visible ? 1.0 : 0.0

            Behavior on scale {
                NumberAnimation {
                    duration: 260
                    easing.type: Easing.OutBack
                }
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: 180
                }
            }

            GridLayout {
                id: powerGrid

                anchors.centerIn: parent

                columns: overlay.width >= 1050 ? 6 : 3

                columnSpacing: 12
                rowSpacing: 12

                // BLOQUEAR
                PowerAction {
                    label: "Bloquear"
                    shortcut: "L"
                    icon: "󰌾"
                    accentColor: "#93c5fd"

                    onActivated: {
                        console.log("Clic en Bloquear")
                        lockProcess.startCommand()
                    }
                }

                // SUSPENDER
                PowerAction {
                    label: "Suspender"
                    shortcut: "S"
                    icon: "󰒲"
                    accentColor: "#a5b4fc"

                    onActivated: {
                        console.log("Clic en Suspender")
                        suspendProcess.startCommand()
                    }
                }

                // REINICIAR BARRA
                PowerAction {
                    label: "Reiniciar barra"
                    shortcut: "B"
                    icon: "󰑐"
                    accentColor: "#fde047"

                    onActivated: {
                        console.log("Clic en Reiniciar barra")
                        restartBarProcess.startCommand()
                    }
                }

                // REINICIAR PC
                PowerAction {
                    label: "Reiniciar PC"
                    shortcut: "R"
                    icon: "󰜉"
                    accentColor: "#86efac"

                    onActivated: {
                        console.log("Clic en Reiniciar PC")
                        rebootProcess.startCommand()
                    }
                }

                // CERRAR SESIÓN
                PowerAction {
                    label: "Cerrar sesión"
                    shortcut: "X"
                    icon: "󰗼"
                    accentColor: "#fdba74"

                    onActivated: {
                        console.log("Clic en Cerrar sesión")
                        logoutProcess.startCommand()
                    }
                }

                // APAGAR
                PowerAction {
                    label: "Apagar"
                    shortcut: "P"
                    icon: "󰐥"
                    accentColor: "#fca5a5"
                    primaryAction: true

                    onActivated: {
                        console.log("Clic en Apagar")
                        shutdownProcess.startCommand()
                    }
                }
            }
        }

        // Captura las teclas cuando el menú está abierto.
        Item {
            anchors.fill: parent
            focus: overlay.visible

            Keys.onEscapePressed: {
                root.close()
            }

            Keys.onPressed: function(event) {
                if (event.key === Qt.Key_L) {
                    lockProcess.startCommand()
                    event.accepted = true
                } else if (event.key === Qt.Key_S) {
                    suspendProcess.startCommand()
                    event.accepted = true
                } else if (event.key === Qt.Key_B) {
                    restartBarProcess.startCommand()
                    event.accepted = true
                } else if (event.key === Qt.Key_R) {
                    rebootProcess.startCommand()
                    event.accepted = true
                } else if (event.key === Qt.Key_X) {
                    logoutProcess.startCommand()
                    event.accepted = true
                } else if (event.key === Qt.Key_P) {
                    shutdownProcess.startCommand()
                    event.accepted = true
                }
            }
        }
    }

    // =========================================================
    // PROCESOS
    // =========================================================

    Process {
        id: lockProcess

        function startCommand() {
            root.execute(
                lockProcess,
                ["loginctl", "lock-session"]
            )
        }
    }

    Process {
        id: suspendProcess

        function startCommand() {
            root.execute(
                suspendProcess,
                ["systemctl", "suspend"]
            )
        }
    }

    Process {
        id: restartBarProcess

        function startCommand() {
            root.execute(
                restartBarProcess,
                [
                    "sh",
                    "-c",
                    "sleep 0.3; pkill -x qs; sleep 1; nohup qs -c minibar >/tmp/minibar.log 2>&1 &"
                ]
            )
        }
    }

    Process {
        id: rebootProcess

        function startCommand() {
            root.execute(
                rebootProcess,
                ["systemctl", "reboot"]
            )
        }
    }

    Process {
        id: logoutProcess

        function startCommand() {
            root.execute(
                logoutProcess,
                [
                    "sh",
                    "-c",
                    "loginctl terminate-session \"$XDG_SESSION_ID\""
                ]
            )
        }
    }

    Process {
        id: shutdownProcess

        function startCommand() {
            root.execute(
                shutdownProcess,
                ["systemctl", "poweroff"]
            )
        }
    }

    // =========================================================
    // COMPONENTE DE CADA BOTÓN
    // =========================================================

    component PowerAction: Item {
        id: action

        property string label: ""
        property string shortcut: ""
        property string icon: ""

        property color accentColor: "#ece8dc"
        property bool primaryAction: false

        signal activated()

        implicitWidth: 140
        implicitHeight: 140

        scale: actionMouse.pressed ? 0.92 : 1.0

        Behavior on scale {
            NumberAnimation {
                duration: 130
                easing.type: Easing.OutBack
            }
        }

        Rectangle {
            anchors.fill: parent

            radius: actionMouse.containsMouse ? 48 : 18

            color: {
                if (action.primaryAction) {
                    return actionMouse.containsMouse
                        ? "#55f38ba8"
                        : "#35f38ba8"
                }

                return actionMouse.containsMouse
                    ? "#34362f"
                    : "#151612"
            }

            border.width: 1

            border.color: actionMouse.containsMouse
                ? action.accentColor
                : "#3c424f"

            Behavior on radius {
                NumberAnimation {
                    duration: 300
                    easing.type: Easing.OutExpo
                }
            }

            Behavior on color {
                ColorAnimation {
                    duration: 140
                }
            }

            Behavior on border.color {
                ColorAnimation {
                    duration: 140
                }
            }

            Column {
                anchors.centerIn: parent
                spacing: 10

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter

                    width: 56
                    height: 56

                    radius: actionMouse.containsMouse ? 18 : 28

                    color: Qt.rgba(
                        action.accentColor.r,
                        action.accentColor.g,
                        action.accentColor.b,
                        0.16
                    )

                    Behavior on radius {
                        NumberAnimation {
                            duration: 300
                            easing.type: Easing.OutExpo
                        }
                    }

                    Text {
                        anchors.centerIn: parent

                        text: action.icon
                        color: action.accentColor

                        font.pixelSize: 29
                        font.family: "JetBrainsMono Nerd Font"
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter

                    text: action.label
                    color: "#d7d3c7"

                    font.pixelSize: 13
                    font.weight: Font.Medium
                }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter

                    width: 24
                    height: 24
                    radius: 7

                    color: "#20232b"

                    border.width: 1
                    border.color: "#464d5b"

                    Text {
                        anchors.centerIn: parent

                        text: action.shortcut
                        color: action.accentColor

                        font.pixelSize: 11
                        font.bold: true
                    }
                }
            }

            MouseArea {
                id: actionMouse

                anchors.fill: parent

                hoverEnabled: true
                acceptedButtons: Qt.LeftButton
                cursorShape: Qt.PointingHandCursor

                onClicked: function(mouse) {
                    console.log("Botón pulsado:", action.label)

                    action.activated()
                    mouse.accepted = true
                }
            }
        }
    }
}
