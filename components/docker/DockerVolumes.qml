import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property var service

    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        RowLayout {
            Layout.fillWidth: true

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    text: "Volúmenes"

                    color: "#ece8dc"

                    font.pixelSize: 17
                    font.bold: true
                }

                Text {
                    text:
                        "Administra el almacenamiento "
                        + "persistente de Docker."

                    color: "#65675f"

                    font.pixelSize: 9
                }
            }

            Rectangle {
                Layout.preferredWidth: 34
                Layout.preferredHeight: 34

                radius: 10

                color:
                    refreshMouse.containsMouse
                        ? "#292a24"
                        : "#171814"

                Text {
                    anchors.centerIn: parent

                    text: "󰑐"

                    color: "#d5a84f"

                    font.pixelSize: 15

                    font.family:
                        "JetBrainsMono Nerd Font"
                }

                MouseArea {
                    id: refreshMouse

                    anchors.fill: parent

                    hoverEnabled: true

                    cursorShape:
                        Qt.PointingHandCursor

                    onClicked:
                        root.service.refresh()
                }
            }
        }

        // =====================================================
        // CREAR
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
                    id: volumeName

                    Layout.fillWidth: true

                    placeholder:
                        "Nombre del volumen"
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
                                .createVolume(
                                    volumeName.text
                                )

                            volumeName.text = ""
                        }
                    }
                }
            }
        }

        Text {
            Layout.fillWidth: true

            visible:
                !root.service.loading
                && root.service.volumes.length === 0

            text:
                "󰋊\nNo hay volúmenes Docker"

            color: "#65675f"

            horizontalAlignment:
                Text.AlignHCenter

            font.pixelSize: 12

            font.family:
                "JetBrainsMono Nerd Font"
        }

        ListView {
            id: volumeList

            Layout.fillWidth: true
            Layout.fillHeight: true

            model:
                root.service.volumes

            spacing: 8
            clip: true

            boundsBehavior:
                Flickable.StopAtBounds

            delegate: Rectangle {
                required property var modelData

                width:
                    volumeList.width

                height: 68

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

                            text: "󰋊"

                            color: "#d5a84f"

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
                                Text.ElideMiddle
                        }

                        Text {
                            text:
                                "Driver: "
                                + (
                                    modelData.Driver
                                    || "local"
                                )

                            color: "#65675f"

                            font.pixelSize: 9
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 75
                        Layout.preferredHeight: 32

                        radius: 10

                        color:
                            removeMouse.containsMouse
                                ? "#51313a"
                                : "#171814"

                        Text {
                            anchors.centerIn: parent

                            text: "Eliminar"

                            color: "#d66d68"

                            font.pixelSize: 10
                        }

                        MouseArea {
                            id: removeMouse

                            anchors.fill: parent

                            hoverEnabled: true

                            cursorShape:
                                Qt.PointingHandCursor

                            onClicked:
                                root.service
                                    .removeVolume(
                                        modelData.Name
                                    )
                        }
                    }
                }
            }
        }
    }
}
