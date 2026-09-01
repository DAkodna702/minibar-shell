import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property var service
    required property var dockerService

    property int activeTab: 0
    property var pendingRemoval: null
    property string statusMessage: ""

    signal logsRequested(var containerLike)

    function showList() {
        root.activeTab = 0
        root.service.refresh()
    }

    function showCreator() {
        root.activeTab = 1
    }

    Connections {
        target: root.service

        function onCreationSucceeded(name) {
            root.statusMessage =
                "Base creada: " + name

            root.activeTab = 0

            root.service.refresh()
            root.dockerService.refresh()

            messageTimer.restart()
        }

        function onCreationFailed(message) {
            root.statusMessage = message
            messageTimer.restart()
        }

        function onCopySucceeded(label) {
            root.statusMessage =
                label + " copiado"

            messageTimer.restart()
        }
    }

    Timer {
        id: messageTimer

        interval: 3500
        repeat: false

        onTriggered:
            root.statusMessage = ""
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        // =============================================
        // PESTAÑAS
        // =============================================

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 44

            radius: 12
            color: "#151612"

            Row {
                anchors {
                    fill: parent
                    margins: 3
                }

                Rectangle {
                    width: parent.width / 2
                    height: parent.height

                    radius: 9

                    color:
                        root.activeTab === 0
                            ? "#d5a84f"
                            : "transparent"

                    Row {
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            text: "󰆼"

                            color:
                                root.activeTab === 0
                                    ? "#11120f"
                                    : "#ece8dc"

                            font.pixelSize: 14
                            font.family:
                                "JetBrainsMono Nerd Font"
                        }

                        Text {
                            text:
                                "Mis bases ("
                                + root.service
                                    .databases.length
                                + ")"

                            color:
                                root.activeTab === 0
                                    ? "#11120f"
                                    : "#ece8dc"

                            font.pixelSize: 11

                            font.bold:
                                root.activeTab === 0
                        }
                    }

                    MouseArea {
                        anchors.fill: parent

                        cursorShape:
                            Qt.PointingHandCursor

                        onClicked:
                            root.showList()
                    }
                }

                Rectangle {
                    width: parent.width / 2
                    height: parent.height

                    radius: 9

                    color:
                        root.activeTab === 1
                            ? "#d5a84f"
                            : "transparent"

                    Row {
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            text: "󰐕"

                            color:
                                root.activeTab === 1
                                    ? "#11120f"
                                    : "#ece8dc"

                            font.pixelSize: 14
                            font.family:
                                "JetBrainsMono Nerd Font"
                        }

                        Text {
                            text: "Crear nueva"

                            color:
                                root.activeTab === 1
                                    ? "#11120f"
                                    : "#ece8dc"

                            font.pixelSize: 11

                            font.bold:
                                root.activeTab === 1
                        }
                    }

                    MouseArea {
                        anchors.fill: parent

                        cursorShape:
                            Qt.PointingHandCursor

                        onClicked:
                            root.showCreator()
                    }
                }
            }
        }

        Text {
            Layout.fillWidth: true

            visible:
                root.statusMessage !== ""

            text: root.statusMessage

            color: "#d5a84f"

            font.pixelSize: 10

            horizontalAlignment:
                Text.AlignHCenter

            wrapMode: Text.Wrap
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // =========================================
            // LISTADO
            // =========================================

            Item {
                anchors.fill: parent

                visible:
                    root.activeTab === 0

                Text {
                    anchors.centerIn: parent

                    visible:
                        !root.service.loading
                        && root.service
                            .databases.length === 0

                    text:
                        "󰆼\n"
                        + "No has creado bases "
                        + "desde Minibar"

                    horizontalAlignment:
                        Text.AlignHCenter

                    color: "#65675f"

                    font.pixelSize: 13
                    font.family:
                        "JetBrainsMono Nerd Font"
                }

                ListView {
                    id: databaseList

                    anchors.fill: parent

                    visible:
                        root.service
                            .databases.length > 0

                    model:
                        root.service.databases

                    spacing: 9
                    clip: true

                    boundsBehavior:
                        Flickable.StopAtBounds

                    delegate: DatabaseCard {
                        required property var modelData

                        width: databaseList.width

                        database: modelData
                        service: root.service

                        onLogsRequested:
                            function(database) {
                                root.logsRequested(
                                    database
                                )
                            }

                        onRemoveRequested:
                            function(database) {
                                root.pendingRemoval =
                                    database

                                confirmDialog.opened =
                                    true
                            }
                    }
                }
            }

            // =========================================
            // CREADOR
            // =========================================

            DatabaseCreator {
                id: databaseCreator

                anchors.fill: parent

                visible:
                    root.activeTab === 1

                service: root.service

                onCreated: {
                    root.showList()
                }
            }
        }
    }

    ConfirmDialog {
        id: confirmDialog

        anchors.fill: parent

        title:
            "Eliminar base de datos"

        confirmText:
            "Eliminar"

        danger: true

        message:
            root.pendingRemoval
                ? (
                    "Se eliminará el contenedor \""
                    + root.pendingRemoval.name
                    + "\".\n\n"
                    + "El volumen \""
                    + root.pendingRemoval.volume
                    + "\" se conservará para "
                    + "proteger tus datos."
                )
                : ""

        onConfirmed: {
            if (root.pendingRemoval) {
                root.service.performAction(
                    root.pendingRemoval,
                    "remove"
                )
            }

            root.pendingRemoval = null
        }

        onCancelled: {
            root.pendingRemoval = null
        }
    }
}
