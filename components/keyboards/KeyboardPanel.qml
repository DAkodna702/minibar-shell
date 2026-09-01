import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

Item {
    id: root
    required property var service
    property var targetScreen: null
    readonly property bool opened: keyboardWindow.visible

    function open() { keyboardWindow.visible = true; service.refresh() }
    function close() { keyboardWindow.visible = false }
    function toggle() { opened ? close() : open() }

    PanelWindow {
        id: keyboardWindow
        screen: root.targetScreen
        visible: false
        color: "transparent"
        anchors { top: true; bottom: true; left: true; right: true }
        WlrLayershell.namespace: "minibar-keyboard-manager"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.exclusiveZone: -1
        WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        Rectangle {
            anchors.fill: parent
            color: "#66050605"
            MouseArea { anchors.fill: parent; onClicked: root.close() }
        }

        Rectangle {
            anchors { top: parent.top; horizontalCenter: parent.horizontalCenter; topMargin: 55 }
            width: Math.min(630, parent.width - 28)
            height: Math.min(820, parent.height - 72)
            radius: 20
            color: "#f70b0c0a"
            border.width: 1
            border.color: "#4a4b42"
            clip: true
            MouseArea { anchors.fill: parent }
            Rectangle { anchors { top: parent.top; left: parent.left; right: parent.right } height: 3; color: "#d5a84f" }

            ColumnLayout {
                anchors { fill: parent; margins: 18 }
                spacing: 11

                RowLayout {
                    Layout.fillWidth: true
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 2
                        Text { text: "TECLADOS"; color: "#ece8dc"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 17; font.weight: Font.DemiBold }
                        Text { text: root.service.summary + " · configuración persistente"; color: "#77796f"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 9 }
                    }
                    Text {
                        text: "×"; color: closeMouse.containsMouse ? "#d5a84f" : "#aaa89d"; font.pixelSize: 21
                        MouseArea { id: closeMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.close() }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: "Puedes dejar uno o los dos teclados físicos activos. “Solo este” apaga los demás sin desconectarlos físicamente."
                    wrapMode: Text.WordWrap; color: "#929489"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 9
                }

                Rectangle {
                    Layout.fillWidth: true; Layout.preferredHeight: 112; radius: 14
                    color: "#141511"; border.width: 1; border.color: root.service.laptopEnabled ? "#615536" : "#34362f"
                    RowLayout {
                        anchors { fill: parent; margins: 13 } spacing: 12
                        Rectangle { Layout.preferredWidth: 52; Layout.preferredHeight: 52; radius: 13; color: "#20211b"
                            Text { anchors.centerIn: parent; text: "󰌢"; color: "#d5a84f"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 23 }
                        }
                        ColumnLayout { Layout.fillWidth: true; spacing: 3
                            Text { text: "Teclado de la laptop"; color: "#e4e0d5"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11; font.weight: Font.DemiBold }
                            Text { text: "AT Translated Set 2 · integrado"; color: "#77796f"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 8 }
                            Text { text: root.service.laptopPresent ? "DETECTADO" : "NO DETECTADO"; color: root.service.laptopPresent ? "#8fa18a" : "#c47872"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 7; font.weight: Font.Bold }
                        }
                        Rectangle { Layout.preferredWidth: 86; Layout.preferredHeight: 30; radius: 9; color: onlyLaptopMouse.containsMouse ? "#292a24" : "#191a16"; border.width: 1; border.color: "#3c3d35"
                            Text { anchors.centerIn: parent; text: "SOLO ESTE"; color: "#aaa99f"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 8 }
                            MouseArea { id: onlyLaptopMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.service.only("laptop") }
                        }
                        Rectangle { Layout.preferredWidth: 48; Layout.preferredHeight: 28; radius: 14; color: root.service.laptopEnabled ? "#d5a84f" : "#30312b"
                            Rectangle { width: 20; height: 20; radius: 10; y: 4; x: root.service.laptopEnabled ? 24 : 4; color: root.service.laptopEnabled ? "#11120e" : "#77796f"; Behavior on x { NumberAnimation { duration: 140 } } }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.service.setEnabled("laptop", !root.service.laptopEnabled) }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true; Layout.preferredHeight: 112; radius: 14
                    color: "#141511"; border.width: 1; border.color: root.service.externalEnabled ? "#615536" : "#34362f"
                    RowLayout {
                        anchors { fill: parent; margins: 13 } spacing: 12
                        Rectangle { Layout.preferredWidth: 52; Layout.preferredHeight: 52; radius: 13; color: "#20211b"
                            Text { anchors.centerIn: parent; text: "󰌌"; color: "#d5a84f"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 23 }
                        }
                        ColumnLayout { Layout.fillWidth: true; spacing: 3
                            Text { text: "BY‑TECH Gaming Keyboard"; color: "#e4e0d5"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11; font.weight: Font.DemiBold }
                            Text { text: "USB externo · se detectó Caps Lock desincronizado"; color: "#77796f"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 8 }
                            Text { text: root.service.externalEnabled ? "ACTIVO" : "BLOQUEADO"; color: root.service.externalEnabled ? "#8fa18a" : "#c47872"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 7; font.weight: Font.Bold }
                        }
                        Rectangle { Layout.preferredWidth: 86; Layout.preferredHeight: 30; radius: 9; color: onlyExternalMouse.containsMouse ? "#292a24" : "#191a16"; border.width: 1; border.color: "#3c3d35"
                            Text { anchors.centerIn: parent; text: "SOLO ESTE"; color: "#aaa99f"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 8 }
                            MouseArea { id: onlyExternalMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.service.only("external") }
                        }
                        Rectangle { Layout.preferredWidth: 48; Layout.preferredHeight: 28; radius: 14; color: root.service.externalEnabled ? "#d5a84f" : "#30312b"
                            Rectangle { width: 20; height: 20; radius: 10; y: 4; x: root.service.externalEnabled ? 24 : 4; color: root.service.externalEnabled ? "#11120e" : "#77796f"; Behavior on x { NumberAnimation { duration: 140 } } }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.service.setEnabled("external", !root.service.externalEnabled) }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true; Layout.preferredHeight: 94; radius: 14
                    color: "#141511"; border.width: 1; border.color: root.service.mouseKeyboardEnabled ? "#615536" : "#34362f"
                    RowLayout {
                        anchors { fill: parent; margins: 13 } spacing: 12
                        Rectangle { Layout.preferredWidth: 52; Layout.preferredHeight: 52; radius: 13; color: "#20211b"
                            Text { anchors.centerIn: parent; text: "󰍽"; color: "#d5a84f"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 23 }
                        }
                        ColumnLayout { Layout.fillWidth: true; spacing: 3
                            Text { text: "Teclado auxiliar del mouse"; color: "#e4e0d5"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11; font.weight: Font.DemiBold }
                            Text { text: "Macros y botones laterales · el puntero no se desactiva"; color: "#77796f"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 8 }
                        }
                        Rectangle { Layout.preferredWidth: 48; Layout.preferredHeight: 28; radius: 14; color: root.service.mouseKeyboardEnabled ? "#d5a84f" : "#30312b"
                            Rectangle { width: 20; height: 20; radius: 10; y: 4; x: root.service.mouseKeyboardEnabled ? 24 : 4; color: root.service.mouseKeyboardEnabled ? "#11120e" : "#77796f"; Behavior on x { NumberAnimation { duration: 140 } } }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.service.setEnabled("mouse", !root.service.mouseKeyboardEnabled) }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true; Layout.preferredHeight: 66; radius: 13; color: "#171814"; border.width: 1; border.color: "#383a32"
                    RowLayout {
                        anchors { fill: parent; margins: 12 } spacing: 9
                        ColumnLayout { Layout.fillWidth: true; spacing: 2
                            Text { text: "Bloqueo de mayúsculas"; color: "#d7d3c7"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10 }
                            Text { text: "Desactivarlo evita otra desincronización de Caps Lock"; color: "#707269"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 8 }
                        }
                        Repeater {
                            model: [{ key: "normal", label: "NORMAL" }, { key: "disabled", label: "DESACTIVADO" }]
                            delegate: Rectangle {
                                id: capsChoice
                                required property var modelData
                                Layout.preferredWidth: modelData.key === "disabled" ? 105 : 76; Layout.preferredHeight: 31; radius: 9
                                color: root.service.capsMode === modelData.key ? "#d5a84f" : "#20211c"
                                border.width: 1; border.color: root.service.capsMode === modelData.key ? "#d5a84f" : "#3a3b34"
                                Text { anchors.centerIn: parent; text: capsChoice.modelData.label; color: root.service.capsMode === capsChoice.modelData.key ? "#11120e" : "#92948a"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 8; font.weight: Font.Bold }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.service.setCapsMode(capsChoice.modelData.key) }
                            }
                        }
                    }
                }

                Text { text: "ILUMINACIÓN"; color: "#73756c"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 8; font.letterSpacing: 1.2 }

                Rectangle {
                    Layout.fillWidth: true; Layout.preferredHeight: 82; radius: 13; color: "#141511"; border.width: 1; border.color: "#34362f"
                    RowLayout {
                        anchors { fill: parent; margins: 12 } spacing: 11
                        Rectangle { Layout.preferredWidth: 46; Layout.preferredHeight: 46; radius: 12; color: "#20211b"
                            Text { anchors.centerIn: parent; text: root.service.laptopLightingOn ? "󰌵" : "󰌶"; color: "#d5a84f"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 21 }
                        }
                        ColumnLayout { Layout.fillWidth: true; spacing: 2
                            Text { text: "Luz del teclado HP Victus"; color: "#e4e0d5"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10; font.weight: Font.DemiBold }
                            Text { text: root.service.laptopLightingAvailable ? (root.service.laptopLightingOn ? "ENCENDIDA · control del kernel disponible" : "APAGADA · control del kernel disponible") : "El kernel no publica un control; usa Fn + F4/F5"; color: root.service.laptopLightingAvailable ? "#8fa18a" : "#b49a65"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 8 }
                        }
                        Rectangle {
                            Layout.preferredWidth: 92; Layout.preferredHeight: 31; radius: 9
                            color: root.service.laptopLightingAvailable ? (laptopLightMouse.containsMouse ? "#e0b45a" : "#d5a84f") : "#272821"
                            border.width: 1; border.color: root.service.laptopLightingAvailable ? "#d5a84f" : "#3a3b34"
                            Text { anchors.centerIn: parent; text: root.service.laptopLightingOn ? "APAGAR" : "ENCENDER"; color: root.service.laptopLightingAvailable ? "#11120e" : "#66685f"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 8; font.weight: Font.Bold }
                            MouseArea { id: laptopLightMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: root.service.laptopLightingAvailable ? Qt.PointingHandCursor : Qt.ArrowCursor; onClicked: root.service.toggleLaptopLighting() }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true; Layout.preferredHeight: 82; radius: 13; color: "#141511"; border.width: 1; border.color: root.service.externalLightingConnected ? "#615536" : "#34362f"
                    RowLayout {
                        anchors { fill: parent; margins: 12 } spacing: 11
                        Rectangle { Layout.preferredWidth: 46; Layout.preferredHeight: 46; radius: 12; color: "#20211b"
                            Text { anchors.centerIn: parent; text: "󰌌"; color: "#d5a84f"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 21 }
                        }
                        ColumnLayout { Layout.fillWidth: true; spacing: 2
                            Text { text: "Iluminación del teclado externo"; color: "#e4e0d5"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10; font.weight: Font.DemiBold }
                            Text { text: root.service.externalLightingConnected ? "BY Tech 258a:0049 detectado · falta identificar el modelo/protocolo" : "Esperando que conectes el teclado USB"; color: root.service.externalLightingConnected ? "#b49a65" : "#707269"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 8 }
                        }
                        Rectangle { Layout.preferredWidth: 88; Layout.preferredHeight: 29; radius: 9; color: "#23241e"; border.width: 1; border.color: "#383a32"
                            Text { anchors.centerIn: parent; text: root.service.externalLightingConnected ? "ANALIZAR" : "DESCONECTADO"; color: "#77796f"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 7; font.weight: Font.Bold }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true; Layout.preferredHeight: root.service.statusMessage === "" ? 0 : 34; visible: height > 0; radius: 9
                    color: root.service.statusError ? "#351d1c" : "#1c241b"; border.width: 1; border.color: root.service.statusError ? "#70403d" : "#3e513d"
                    Text { anchors { fill: parent; leftMargin: 10; rightMargin: 10 } verticalAlignment: Text.AlignVCenter; text: root.service.statusMessage; color: root.service.statusError ? "#df8c86" : "#a9b7a0"; elide: Text.ElideRight; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 8 }
                }

                Item { Layout.fillHeight: true }
            }
        }
    }
}
