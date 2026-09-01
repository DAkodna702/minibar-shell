import QtQuick
import QtQuick.Layouts

import Quickshell
import Quickshell.Wayland

Item {
    id: root
    property var targetScreen: null

    required property var service

    readonly property bool opened: centerWindow.visible

    function open() {
        centerWindow.visible = true
        service.markAllRead()
    }

    function close() {
        centerWindow.visible = false
    }

    function toggle() {
        centerWindow.visible ? close() : open()
    }

    PanelWindow {
        id: centerWindow
        screen: root.targetScreen

        visible: false
        color: "transparent"

        anchors {
            top: true
            right: true
            bottom: true
            left: true
        }

        WlrLayershell.namespace: "minibar-notification-center"
        WlrLayershell.layer: WlrLayershell.Overlay
        WlrLayershell.exclusiveZone: -1

        WlrLayershell.keyboardFocus:
            centerWindow.visible
                ? WlrKeyboardFocus.OnDemand
                : WlrKeyboardFocus.None

        // Fondo transparente que cierra el panel al pulsar fuera.
        Rectangle {
            anchors.fill: parent
            color: "#59050605"

            MouseArea {
                anchors.fill: parent
                onClicked: root.close()
            }
        }

        // Panel lateral.
        Rectangle {
            id: panel

            anchors {
                top: parent.top
                right: parent.right
                bottom: parent.bottom

                topMargin: 48
                rightMargin: 8
                bottomMargin: 8
            }

            width: Math.min(400, parent.width - 16)
            radius: 20

            color: "#f70b0c0a"

            border.width: 1
            border.color: "#4a4b42"

            MouseArea {
                anchors.fill: parent
            }

            transform: Translate {
                x: centerWindow.visible ? 0 : 35

                Behavior on x {
                    NumberAnimation {
                        duration: 240
                        easing.type: Easing.OutCubic
                    }
                }
            }

            ColumnLayout {
                anchors {
                    fill: parent
                    margins: 16
                }

                spacing: 12

                // Cabecera.
                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        Layout.fillWidth: true

                        text: "Notificaciones"
                        color: "#ece8dc"

                        font.pixelSize: 19
                        font.bold: true
                    }

                    Rectangle {
                        visible:
                            root.service.server
                                .trackedNotifications
                                .values.length > 0

                        Layout.preferredWidth:
                            clearText.implicitWidth + 18

                        Layout.preferredHeight: 30

                        radius: 10

                        color: clearMouse.containsMouse
                            ? "#4a3038"
                            : "#171814"

                        Text {
                            id: clearText

                            anchors.centerIn: parent

                            text: "Limpiar todo"

                            color: clearMouse.containsMouse
                                ? "#d66d68"
                                : "#ece8dc"

                            font.pixelSize: 11
                            font.weight: Font.Medium
                        }

                        MouseArea {
                            id: clearMouse

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor

                            onClicked: {
                                root.service.clearAll()
                            }
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 30
                        Layout.preferredHeight: 30

                        radius: 10

                        color: closeMouse.containsMouse
                            ? "#292a24"
                            : "#171814"

                        Text {
                            anchors.centerIn: parent

                            text: "󰅖"
                            color: "#ece8dc"

                            font.pixelSize: 15
                            font.family: "JetBrainsMono Nerd Font"
                        }

                        MouseArea {
                            id: closeMouse

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor

                            onClicked: root.close()
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: "#34362f"
                }

                // Área de contenido.
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    // Estado vacío.
                    Text {
                        anchors.centerIn: parent

                        visible:
                            root.service.server
                                .trackedNotifications
                                .values.length === 0

                        text: "󰂜\nNo tienes notificaciones"

                        horizontalAlignment: Text.AlignHCenter

                        color: "#65675f"
                        font.pixelSize: 14
                        font.family: "JetBrainsMono Nerd Font"
                    }

                    // Lista de notificaciones.
                    ListView {
                        id: notificationList

                        anchors.fill: parent

                        visible:
                            root.service.server
                                .trackedNotifications
                                .values.length > 0

                        model:
                            root.service.server
                                .trackedNotifications

                        spacing: 9
                        clip: true

                        boundsBehavior: Flickable.StopAtBounds

                        delegate: NotificationCard {
                            required property var modelData

                            width: notificationList.width
                            notification: modelData
                        }
                    }
                }
            }
        }

        // Permite cerrar con Escape.
        Item {
            anchors.fill: parent
            focus: centerWindow.visible

            Keys.onEscapePressed: root.close()
        }
    }
}
