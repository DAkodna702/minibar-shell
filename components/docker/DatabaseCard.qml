import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    required property var database
    required property var service

    property string loadedPassword: ""
    property bool passwordVisible: false
    property bool waitingPassword: false

    signal logsRequested(var database)
    signal removeRequested(var database)

    implicitHeight: contentColumn.implicitHeight + 22
    radius: 16
    color: cardMouse.containsMouse ? "#20211c" : "#151612"

    border.width: 1
    border.color: database.isRunning ? "#9eb39d" : "#d66d68"

    function engineLabel() {
        switch (database.engine) {
        case "postgres": return "PostgreSQL"
        case "mysql": return "MySQL"
        case "mongo": return "MongoDB"
        case "redis": return "Redis"
        case "mssql": return "SQL Server"
        case "oracle": return "Oracle Free"
        default: return database.engine
        }
    }

    function requestPassword() {
        if (root.loadedPassword !== "") {
            root.passwordVisible = !root.passwordVisible
            return
        }

        root.waitingPassword = true
        root.service.requestPassword(root.database)
    }

    Connections {
        target: root.service

        function onPasswordLoaded(containerId, password) {
            if (containerId !== root.database.id)
                return

            root.waitingPassword = false
            root.loadedPassword = password
            root.passwordVisible = password !== ""
        }
    }

    MouseArea {
        id: cardMouse
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        hoverEnabled: true
    }

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

        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Rectangle {
                Layout.preferredWidth: 42
                Layout.preferredHeight: 42
                radius: 12
                color: "#34362f"

                Text {
                    anchors.centerIn: parent
                    text: "󰆼"
                    color: database.isRunning ? "#9eb39d" : "#d66d68"
                    font.pixelSize: 20
                    font.family: "JetBrainsMono Nerd Font"
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    Layout.fillWidth: true
                    text: root.engineLabel() + " · " + database.name
                    color: "#ece8dc"
                    font.pixelSize: 13
                    font.bold: true
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    text: database.image
                    color: "#65675f"
                    font.pixelSize: 9
                    elide: Text.ElideMiddle
                }

                Text {
                    text: database.isRunning ? "Ejecutándose" : database.status
                    color: database.isRunning ? "#9eb39d" : "#d66d68"
                    font.pixelSize: 9
                    font.bold: true
                }
            }
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: 8
            rowSpacing: 7

            InfoRow {
                Layout.fillWidth: true
                label: "Host"
                value: database.host
                onCopyRequested: service.copyText(value, "Host")
            }

            InfoRow {
                Layout.fillWidth: true
                label: "Puerto"
                value: database.port
                onCopyRequested: service.copyText(value, "Puerto")
            }

            InfoRow {
                Layout.fillWidth: true
                label: "Usuario"
                value: database.user
                onCopyRequested: service.copyText(value, "Usuario")
            }

            InfoRow {
                Layout.fillWidth: true
                label: "Base"
                value: database.database
                onCopyRequested: service.copyText(value, "Base")
            }

            InfoRow {
                Layout.columnSpan: 2
                Layout.fillWidth: true
                label: "Contraseña"
                value:
                    root.waitingPassword
                        ? "Cargando…"
                        : root.passwordVisible
                            ? root.loadedPassword
                            : "••••••••••"

                showEye: true
                eyeActive: root.passwordVisible

                onEyeRequested: root.requestPassword()

                onCopyRequested: {
                    if (root.loadedPassword !== "")
                        service.copyText(root.loadedPassword, "Contraseña")
                    else {
                        root.waitingPassword = true
                        service.requestPassword(root.database)
                    }
                }
            }
        }

        Flow {
            Layout.fillWidth: true
            spacing: 6

            ActionButton {
                text: database.isRunning ? "Reiniciar" : "Iniciar"
                onTriggered: service.performAction(
                    database,
                    database.isRunning ? "restart" : "start"
                )
            }

            ActionButton {
                visible: database.isRunning
                text: "Detener"
                onTriggered: service.performAction(database, "stop")
            }

            ActionButton {
                text: "Logs"
                onTriggered: root.logsRequested(database)
            }

            ActionButton {
                text: "Eliminar"
                danger: true
                onTriggered: root.removeRequested(database)
            }
        }
    }

    component InfoRow: Rectangle {
        id: info

        property string label: ""
        property string value: ""
        property bool showEye: false
        property bool eyeActive: false

        signal copyRequested()
        signal eyeRequested()

        implicitHeight: 52
        radius: 12
        color: "#151612"

        Column {
            anchors {
                left: parent.left
                right: controls.left
                top: parent.top
                margins: 9
            }

            spacing: 2

            Text {
                text: info.label
                color: "#65675f"
                font.pixelSize: 8
            }

            Text {
                width: parent.width
                text: info.value
                color: "#d7d3c7"
                font.pixelSize: 10
                elide: Text.ElideMiddle
            }
        }

        Row {
            id: controls
            anchors {
                right: parent.right
                rightMargin: 6
                verticalCenter: parent.verticalCenter
            }

            spacing: 2

            Rectangle {
                visible: info.showEye
                width: visible ? 28 : 0
                height: 28
                radius: 8
                color: eyeMouse.containsMouse ? "#292a24" : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: info.eyeActive ? "󰈈" : "󰈉"
                    color: "#ece8dc"
                    font.pixelSize: 13
                    font.family: "JetBrainsMono Nerd Font"
                }

                MouseArea {
                    id: eyeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: info.eyeRequested()
                }
            }

            Rectangle {
                width: 28
                height: 28
                radius: 8
                color: copyMouse.containsMouse ? "#25251f" : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "󰆏"
                    color: "#d5a84f"
                    font.pixelSize: 13
                    font.family: "JetBrainsMono Nerd Font"
                }

                MouseArea {
                    id: copyMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: info.copyRequested()
                }
            }
        }
    }

    component ActionButton: Rectangle {
        id: action

        property string text: ""
        property bool danger: false

        signal triggered()

        width: actionText.implicitWidth + 20
        height: 30
        radius: 10

        color:
            actionMouse.containsMouse
                ? action.danger ? "#4a3038" : "#25251f"
                : "#171814"

        Text {
            id: actionText
            anchors.centerIn: parent
            text: action.text
            color: action.danger ? "#d66d68" : "#d7d3c7"
            font.pixelSize: 10
        }

        MouseArea {
            id: actionMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: action.triggered()
        }
    }
}
