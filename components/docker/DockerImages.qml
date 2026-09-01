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
                    text: "Imágenes Docker"

                    color: "#ece8dc"

                    font.pixelSize: 17
                    font.bold: true
                }

                Text {
                    text:
                        "Descarga, consulta y elimina "
                        + "imágenes Docker."

                    color: "#65675f"

                    font.pixelSize: 9
                }
            }

            Rectangle {
                Layout.preferredWidth: 120
                Layout.preferredHeight: 34

                radius: 10

                color:
                    pruneMouse.containsMouse
                        ? "#292a24"
                        : "#171814"

                Text {
                    anchors.centerIn: parent

                    text: "Limpiar sin uso"

                    color: "#d5a84f"

                    font.pixelSize: 9
                }

                MouseArea {
                    id: pruneMouse

                    anchors.fill: parent

                    hoverEnabled: true

                    cursorShape:
                        Qt.PointingHandCursor

                    onClicked:
                        root.service.pruneImages()
                }
            }
        }

        // =====================================================
        // PULL
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
                    id: imageInput

                    Layout.fillWidth: true

                    placeholder:
                        "postgres:17, nginx:alpine..."

                    onAccepted: {
                        root.service
                            .pullImage(
                                imageInput.text
                            )

                        imageInput.text = ""
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 90
                    Layout.preferredHeight: 44

                    radius: 12

                    color:
                        pullMouse.containsMouse
                            ? "#e1b75f"
                            : "#d5a84f"

                    Text {
                        anchors.centerIn: parent

                        text: "Pull"

                        color: "#11120f"

                        font.pixelSize: 11
                        font.bold: true
                    }

                    MouseArea {
                        id: pullMouse

                        anchors.fill: parent

                        hoverEnabled: true

                        cursorShape:
                            Qt.PointingHandCursor

                        onClicked: {
                            root.service
                                .pullImage(
                                    imageInput.text
                                )

                            imageInput.text = ""
                        }
                    }
                }
            }
        }

        ListView {
            id: imageList

            Layout.fillWidth: true
            Layout.fillHeight: true

            model:
                root.service.images

            spacing: 8
            clip: true

            boundsBehavior:
                Flickable.StopAtBounds

            delegate: Rectangle {
                required property var modelData

                width:
                    imageList.width

                height: 82

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
                        Layout.preferredWidth: 44
                        Layout.preferredHeight: 44

                        radius: 12

                        color: "#171814"

                        Text {
                            anchors.centerIn: parent

                            text: "󰡨"

                            color: "#d5a84f"

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

                            text:
                                (
                                    modelData.Repository
                                    || "<none>"
                                )
                                + ":"
                                + (
                                    modelData.Tag
                                    || "<none>"
                                )

                            color: "#ece8dc"

                            font.pixelSize: 11
                            font.bold: true

                            elide:
                                Text.ElideMiddle
                        }

                        Text {
                            Layout.fillWidth: true

                            text:
                                "ID: "
                                + (
                                    modelData.ID
                                    || ""
                                )
                                + "  ·  "
                                + (
                                    modelData.Size
                                    || ""
                                )

                            color: "#65675f"

                            font.pixelSize: 9

                            elide:
                                Text.ElideRight
                        }

                        Text {
                            text:
                                modelData.CreatedSince
                                || ""

                            color: "#65675f"

                            font.pixelSize: 8
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
                                    .removeImage(
                                        modelData.ID
                                    )
                        }
                    }
                }
            }
        }
    }
}
