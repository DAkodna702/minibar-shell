import QtQuick
import QtQuick.Layouts

import Quickshell
import Quickshell.Wayland

Item {
    id: root
    property var targetScreen: null

    required property var service
    required property var databaseService
    required property var infraService

    readonly property bool opened:
        dockerWindow.visible

    property int mainTab: 0
    property int currentView: 0

    property var selectedContainer: null

    property string panelMessage: ""

    // =========================================================
    // CONTROL DEL PANEL
    // =========================================================

    function open() {
        dockerWindow.visible = true

        root.mainTab = 0
        root.currentView = 0

        root.service.refresh()
        root.databaseService.refresh()
        root.infraService.refresh()
    }

    function close() {
        dockerWindow.visible = false

        logsView.closeLogs()
        consoleView.closeConsole()

        root.currentView = 0
        root.selectedContainer = null
    }

    function toggle() {
        if (dockerWindow.visible)
            root.close()
        else
            root.open()
    }

    function openLogs(container) {
        root.selectedContainer =
            container

        root.currentView = 1

        logsView.openContainer(
            container
        )
    }

    function openConsole(container) {
        root.selectedContainer =
            container

        root.currentView = 2

        consoleView.openContainer(
            container
        )
    }

    function showMessage(message) {
        root.panelMessage = message
        messageTimer.restart()
    }

    // =========================================================
    // MENSAJES DOCKER
    // =========================================================

    Connections {
        target: root.service

        function onActionSucceeded(message) {
            root.showMessage(message)
        }

        function onActionFailed(message) {
            root.showMessage(message)
        }
    }

    Connections {
        target: root.infraService

        function onActionSucceeded(message) {
            root.showMessage(message)
        }

        function onActionFailed(message) {
            root.showMessage(message)
        }
    }

    Timer {
        id: messageTimer

        interval: 3200
        repeat: false

        onTriggered:
            root.panelMessage = ""
    }

    // =========================================================
    // WINDOW
    // =========================================================

    PanelWindow {
        id: dockerWindow
        screen: root.targetScreen

        visible: false

        color: "transparent"

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        exclusionMode:
            ExclusionMode.Ignore

        WlrLayershell.namespace:
            "minibar-docker-panel"

        WlrLayershell.layer:
            WlrLayershell.Overlay

        WlrLayershell.exclusiveZone:
            -1

        WlrLayershell.keyboardFocus:
            dockerWindow.visible
                ? WlrKeyboardFocus.Exclusive
                : WlrKeyboardFocus.None

        // =====================================================
        // FONDO
        // =====================================================

        Rectangle {
            anchors.fill: parent

            color: "#66050605"

            MouseArea {
                anchors.fill: parent

                onClicked:
                    root.close()
            }
        }

        // =====================================================
        // CARD
        // =====================================================

        Rectangle {
            id: dockerCard

            anchors.centerIn: parent

            width:
                Math.min(
                    dockerWindow.width - 70,
                    1180
                )

            height:
                Math.min(
                    dockerWindow.height - 80,
                    790
                )

            radius: 22

            color: "#f70b0c0a"

            border.width: 1
            border.color: "#4a4b42"

            MouseArea {
                anchors.fill: parent
            }

            ColumnLayout {
                anchors {
                    fill: parent
                    margins: 20
                }

                spacing: 12

                // =============================================
                // HEADER
                // =============================================

                RowLayout {
                    Layout.fillWidth: true

                    spacing: 10

                    Rectangle {
                        Layout.preferredWidth: 44
                        Layout.preferredHeight: 44

                        radius: 14

                        color: "#25251f"

                        Text {
                            anchors.centerIn: parent

                            text: "󰡨"

                            color: "#d5a84f"

                            font.pixelSize: 23

                            font.family:
                                "JetBrainsMono Nerd Font"
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true

                        spacing: 2

                        Text {
                            text:
                                "Docker Manager"

                            color: "#ece8dc"

                            font.pixelSize: 19
                            font.bold: true
                        }

                        Text {
                            text:
                                root.service
                                    .dockerAvailable
                                    ? (
                                        root.service
                                            .runningCount
                                        + " de "
                                        + root.service
                                            .containers
                                            .length
                                        + " contenedores "
                                        + "ejecutándose"
                                    )
                                    : "Docker no disponible"

                            color:
                                root.service
                                    .dockerAvailable
                                    ? "#aaa89d"
                                    : "#d66d68"

                            font.pixelSize: 10
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

                            onClicked: {
                                root.service.refresh()

                                root.databaseService
                                    .refresh()

                                root.infraService
                                    .refresh()
                            }
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 34
                        Layout.preferredHeight: 34

                        radius: 10

                        color:
                            closeMouse.containsMouse
                                ? "#51313a"
                                : "#171814"

                        Text {
                            anchors.centerIn: parent

                            text: "󰅖"

                            color: "#d66d68"

                            font.pixelSize: 15

                            font.family:
                                "JetBrainsMono Nerd Font"
                        }

                        MouseArea {
                            id: closeMouse

                            anchors.fill: parent

                            hoverEnabled: true

                            cursorShape:
                                Qt.PointingHandCursor

                            onClicked:
                                root.close()
                        }
                    }
                }

                // =============================================
                // TABS
                // =============================================

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 46

                    visible:
                        root.currentView === 0

                    radius: 14

                    color: "#151612"

                    RowLayout {
                        anchors {
                            fill: parent
                            margins: 4
                        }

                        spacing: 4

                        Repeater {
                            model: [
                                "Contenedores",
                                "Bases de datos",
                                "Volúmenes",
                                "Redes",
                                "Imágenes"
                            ]

                            delegate: Rectangle {
                                required property string modelData
                                required property int index

                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                radius: 10

                                color:
                                    root.mainTab === index
                                        ? "#d5a84f"
                                        : tabMouse.containsMouse
                                            ? "#34362f"
                                            : "transparent"

                                Text {
                                    anchors.centerIn: parent

                                    text: modelData

                                    color:
                                        root.mainTab === index
                                            ? "#11120f"
                                            : "#ece8dc"

                                    font.pixelSize: 10

                                    font.bold:
                                        root.mainTab === index
                                }

                                MouseArea {
                                    id: tabMouse

                                    anchors.fill: parent

                                    hoverEnabled: true

                                    cursorShape:
                                        Qt.PointingHandCursor

                                    onClicked: {
                                        root.mainTab =
                                            index

                                        if (index === 0) {
                                            root.service
                                                .refresh()
                                        }

                                        if (index === 1) {
                                            root.databaseService
                                                .refresh()
                                        }

                                        if (index >= 2) {
                                            root.infraService
                                                .refresh()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // =============================================
                // MENSAJE
                // =============================================

                Text {
                    Layout.fillWidth: true

                    visible:
                        root.panelMessage !== ""

                    text:
                        root.panelMessage

                    color: "#d5a84f"

                    font.pixelSize: 10

                    horizontalAlignment:
                        Text.AlignHCenter

                    wrapMode:
                        Text.Wrap
                }

                // =============================================
                // CONTENIDO
                // =============================================

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    // -----------------------------------------
                    // CONTENEDORES
                    // -----------------------------------------

                    Item {
                        anchors.fill: parent

                        visible:
                            root.currentView === 0
                            && root.mainTab === 0

                        Text {
                            anchors.centerIn: parent

                            visible:
                                !root.service.loading
                                && root.service
                                    .containers
                                    .length === 0

                            text:
                                root.service
                                    .dockerAvailable
                                    ? (
                                        "󰡨\n"
                                        + "No hay contenedores"
                                    )
                                    : (
                                        "󰡨\n"
                                        + "Docker no "
                                        + "está disponible"
                                    )

                            horizontalAlignment:
                                Text.AlignHCenter

                            color: "#65675f"

                            font.pixelSize: 14

                            font.family:
                                "JetBrainsMono Nerd Font"
                        }

                        ListView {
                            id: containerList

                            anchors.fill: parent

                            visible:
                                root.service
                                    .containers
                                    .length > 0

                            model:
                                root.service.containers

                            spacing: 9
                            clip: true

                            boundsBehavior:
                                Flickable.StopAtBounds

                            delegate: ContainerCard {
                                required property var modelData

                                width:
                                    containerList.width

                                container:
                                    modelData

                                service:
                                    root.service

                                onLogsRequested:
                                    function(container) {
                                        root.openLogs(
                                            container
                                        )
                                    }

                                onConsoleRequested:
                                    function(container) {
                                        root.openConsole(
                                            container
                                        )
                                    }

                                onRemoveRequested:
                                    function(container) {
                                        root.selectedContainer =
                                            container

                                        confirmRemove.message =
                                            "¿Eliminar el "
                                            + "contenedor \""
                                            + container.name
                                            + "\"?"

                                        confirmRemove.opened =
                                            true
                                    }
                            }
                        }
                    }

                    // -----------------------------------------
                    // BASES DE DATOS
                    // -----------------------------------------

                    DatabaseManager {
                        anchors.fill: parent

                        visible:
                            root.currentView === 0
                            && root.mainTab === 1

                        service:
                            root.databaseService

                        dockerService:
                            root.service

                        onLogsRequested:
                            function(database) {
                                root.openLogs(
                                    database
                                )
                            }
                    }

                    // -----------------------------------------
                    // VOLUMES
                    // -----------------------------------------

                    DockerVolumes {
                        anchors.fill: parent

                        visible:
                            root.currentView === 0
                            && root.mainTab === 2

                        service:
                            root.infraService
                    }

                    // -----------------------------------------
                    // NETWORKS
                    // -----------------------------------------

                    DockerNetworks {
                        anchors.fill: parent

                        visible:
                            root.currentView === 0
                            && root.mainTab === 3

                        service:
                            root.infraService
                    }

                    // -----------------------------------------
                    // IMAGES
                    // -----------------------------------------

                    DockerImages {
                        anchors.fill: parent

                        visible:
                            root.currentView === 0
                            && root.mainTab === 4

                        service:
                            root.infraService
                    }

                    // -----------------------------------------
                    // LOGS
                    // -----------------------------------------

                    ContainerLogs {
                        id: logsView

                        anchors.fill: parent

                        visible:
                            root.currentView === 1

                        service:
                            root.service

                        onBackRequested:
                            root.currentView = 0
                    }

                    // -----------------------------------------
                    // CONSOLA
                    // -----------------------------------------

                    ContainerConsole {
                        id: consoleView

                        anchors.fill: parent

                        visible:
                            root.currentView === 2

                        service:
                            root.service

                        onBackRequested:
                            root.currentView = 0
                    }
                }
            }
        }

        // =====================================================
        // CONFIRM REMOVE CONTAINER
        // =====================================================

        ConfirmDialog {
            id: confirmRemove

            anchors.fill: parent

            title:
                "Eliminar contenedor"

            confirmText:
                "Eliminar"

            danger: true

            onConfirmed: {
                if (!root.selectedContainer)
                    return

                root.service.executeAction(
                    root.selectedContainer,

                    root.selectedContainer
                        .isRunning
                        ? "forceRemove"
                        : "remove"
                )

                root.selectedContainer = null
            }

            onCancelled: {
                root.selectedContainer = null
            }
        }

        // =====================================================
        // ESC
        // =====================================================

        Item {
            anchors.fill: parent

            focus:
                dockerWindow.visible

            Keys.onEscapePressed: {
                if (confirmRemove.opened) {
                    confirmRemove.opened =
                        false

                    return
                }

                if (root.currentView !== 0) {
                    logsView.closeLogs()
                    consoleView.closeConsole()

                    root.currentView = 0

                    return
                }

                root.close()
            }
        }
    }
}
