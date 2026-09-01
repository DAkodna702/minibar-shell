import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property var service

    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                text: "Redes Docker"

                color: "#ece8dc"

                font.pixelSize: 17
                font.bold: true
            }

            Text {
                text:
                    "Crea y administra las redes "
                    + "utilizadas por tus contenedores."

                color: "#65675f"

                font.pixelSize: 9
            }
        }

        // =====================================================
        // CREAR RED
        // =====================================================

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 64

            radius: 14

            color: "#151612"

            border.width: 1
            border.color: "#34362f"

            RowLayout {
                anchors {
                    fill: parent
                    margins: 10
                }

                spacing: 8

                PasswordField {
                    id: networkName

                    Layout.fillWidth: true

                    placeholder:
                        "Nombre de la red"
                }

                Rectangle {
                    Layout.preferredWidth: 100
                    Layout.preferredHeight: 44

                    radius: 12

                    color: "#151612"

                    Text {
                        anchors.centerIn: parent

                        text: "bridge"

                        color: "#ece8dc"

                        font.pixelSize: 10
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 80
                    Layout.preferredHeight: 44

                    radius: 12

                    color:
                        createMouse.containsMouse
                            ? "#e1b75f"
                            : "#d5a84f"

                    Text {
                        anchors.centerIn: parent

                        text: "Crear"

                        color: "#11120f"

                        font.pixelSize: 11
                        font.bold: true
                    }

                    MouseArea {
                        id: createMouse

                        anchors.fill: parent

                        hoverEnabled: true

                        cursorShape:
                            Qt.PointingHandCursor

                        onClicked: {
                            root.service
                                .createNetwork(
                                    networkName.text,
                                    "bridge"
                                )

                            networkName.text = ""
                        }
                    }
                }
            }
        }

        ListView {
            id: networkList

            Layout.fillWidth: true
            Layout.fillHeight: true

            model:
                root.service.networks

            spacing: 8
            clip: true

            boundsBehavior:
                Flickable.StopAtBounds

            delegate: Rectangle {
                required property var modelData

                width:
                    networkList.width

                height: 74

                radius: 14

                color: "#151612"

                border.width: 1
                border.color: "#34362f"

                RowLayout {
                    anchors {
                        fill: parent
                        margins: 10
                    }

                    spacing: 10

                    Rectangle {
                        Layout.preferredWidth: 42
                        Layout.preferredHeight: 42

                        radius: 12

                        color: "#171814"

                        Text {
                            anchors.centerIn: parent

                            text: "󰛳"

                            color: "#9eb39d"

                            font.pixelSize: 19

                            font.family:
                                "JetBrainsMono Nerd Font"
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true

                        spacing: 2

                        Text {
                            Layout.fillWidth: true

                            text:
                                modelData.Name || ""

                            color: "#ece8dc"

                            font.pixelSize: 11
                            font.bold: true

                            elide:
                                Text.ElideRight
                        }

                        Text {
                            text:
                                "Driver: "
                                + (
                                    modelData.Driver
                                    || ""
                                )
                                + "  ·  Scope: "
                                + (
                                    modelData.Scope
                                    || ""
                                )

                            color: "#65675f"

                            font.pixelSize: 9
                        }

                        Text {
                            text:
                                "ID: "
                                + (
                                    modelData.ID
                                    || ""
                                )

                            color: "#65675f"

                            font.pixelSize: 8
                        }
                    }

                    Rectangle {
                        property bool protectedNetwork:
                            modelData.Name === "bridge"
                            || modelData.Name === "host"
                            || modelData.Name === "none"

                        Layout.preferredWidth: 75
                        Layout.preferredHeight: 32

                        radius: 10

                        opacity:
                            protectedNetwork
                                ? 0.4
                                : 1

                        color:
                            removeMouse.containsMouse
                            && !protectedNetwork
                                ? "#51313a"
                                : "#171814"

                        Text {
                            anchors.centerIn: parent

                            text:
                                parent.protectedNetwork
                                    ? "Sistema"
                                    : "Eliminar"

                            color:
                                parent.protectedNetwork
                                    ? "#65675f"
                                    : "#d66d68"

                            font.pixelSize: 10
                        }

                        MouseArea {
                            id: removeMouse

                            anchors.fill: parent

                            hoverEnabled: true

                            enabled:
                                !parent.protectedNetwork

                            cursorShape:
                                enabled
                                    ? Qt.PointingHandCursor
                                    : Qt.ForbiddenCursor

                            onClicked:
                                root.service
                                    .removeNetwork(
                                        modelData.ID,
                                        modelData.Name
                                    )
                        }
                    }
                }
            }
        }
    }
}
