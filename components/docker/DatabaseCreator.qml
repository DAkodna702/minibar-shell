import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property var service

    property string selectedEngine: "postgres"

    signal created()

    function defaults() {
        return root.service.engineDefaults(
            root.selectedEngine
        )
    }

    function applyDefaults() {
        const values = root.defaults()

        containerNameInput.text =
            root.selectedEngine + "-dev"

        imageInput.text =
            values.image || ""

        userInput.text =
            values.user || ""

        databaseInput.text =
            values.database || ""

        passwordInput.text = ""
        passwordInput.revealed = false

        portInput.text =
            String(values.hostPort || "")

        volumeInput.text =
            root.selectedEngine + "-dev-data"

        networkInput.text = ""
    }

    function submit() {
        root.service.createDatabase({
            engine: root.selectedEngine,

            containerName:
                containerNameInput.text.trim(),

            image:
                imageInput.text.trim(),

            user:
                userInput.text.trim(),

            database:
                databaseInput.text.trim(),

            password:
                passwordInput.text,

            hostPort:
                portInput.text.trim(),

            volumeName:
                volumeInput.text.trim(),

            network:
                networkInput.text.trim()
        })
    }

    Connections {
        target: root.service

        function onCreationSucceeded(name) {
            root.applyDefaults()
            root.created()
        }
    }

    Component.onCompleted: {
        root.applyDefaults()
    }

    Flickable {
        id: formFlickable

        anchors.fill: parent

        contentWidth: width
        contentHeight:
            formColumn.implicitHeight + 12

        clip: true

        flickableDirection:
            Flickable.VerticalFlick

        boundsBehavior:
            Flickable.StopAtBounds

        ColumnLayout {
            id: formColumn

            width: formFlickable.width

            spacing: 12

            Text {
                Layout.fillWidth: true

                text: "Crear base de datos"

                color: "#ece8dc"

                font.pixelSize: 17
                font.bold: true
            }

            Text {
                Layout.fillWidth: true

                text:
                    "Selecciona un motor y configura "
                    + "el contenedor, puerto, usuario, "
                    + "contraseña, volumen y red."

                color: "#aaa89d"

                font.pixelSize: 10
                wrapMode: Text.Wrap
            }

            // =============================================
            // MOTORES
            // =============================================

            Flow {
                Layout.fillWidth: true
                spacing: 7

                Repeater {
                    model: [
                        {
                            id: "postgres",
                            label: "PostgreSQL"
                        },
                        {
                            id: "mysql",
                            label: "MySQL"
                        },
                        {
                            id: "mongo",
                            label: "MongoDB"
                        },
                        {
                            id: "redis",
                            label: "Redis"
                        },
                        {
                            id: "mssql",
                            label: "SQL Server"
                        },
                        {
                            id: "oracle",
                            label: "Oracle Free"
                        }
                    ]

                    delegate: Rectangle {
                        required property var modelData

                        width:
                            engineLabel.implicitWidth + 22

                        height: 34
                        radius: 11

                        color: {
                            if (
                                root.selectedEngine
                                === modelData.id
                            ) {
                                return "#d5a84f"
                            }

                            if (engineMouse.containsMouse)
                                return "#292a24"

                            return "#171814"
                        }

                        Text {
                            id: engineLabel

                            anchors.centerIn: parent

                            text: modelData.label

                            color:
                                root.selectedEngine
                                === modelData.id
                                    ? "#11120f"
                                    : "#ece8dc"

                            font.pixelSize: 10

                            font.bold:
                                root.selectedEngine
                                === modelData.id
                        }

                        MouseArea {
                            id: engineMouse

                            anchors.fill: parent
                            hoverEnabled: true

                            cursorShape:
                                Qt.PointingHandCursor

                            onClicked: {
                                root.selectedEngine =
                                    modelData.id

                                root.applyDefaults()
                            }
                        }
                    }
                }
            }

            Text {
                Layout.fillWidth: true

                visible:
                    root.selectedEngine === "oracle"

                text:
                    "Oracle puede tardar varios minutos "
                    + "en iniciar y consume bastante memoria."

                color: "#d5a84f"

                font.pixelSize: 10
                wrapMode: Text.Wrap
            }

            Text {
                Layout.fillWidth: true

                visible:
                    root.selectedEngine === "mssql"

                text:
                    "SQL Server necesita una contraseña "
                    + "compleja y al menos 8 caracteres."

                color: "#d5a84f"

                font.pixelSize: 10
                wrapMode: Text.Wrap
            }

            // =============================================
            // DATOS PRINCIPALES
            // =============================================

            GridLayout {
                Layout.fillWidth: true

                columns: 2
                columnSpacing: 10
                rowSpacing: 10

                FieldContainer {
                    Layout.fillWidth: true

                    title: "Nombre del contenedor"

                    PasswordField {
                        id: containerNameInput

                        anchors.fill: parent

                        placeholder:
                            "postgres-dev"
                    }
                }

                FieldContainer {
                    Layout.fillWidth: true

                    title: "Puerto del host"

                    PasswordField {
                        id: portInput

                        anchors.fill: parent

                        placeholder:
                            "5432"
                    }
                }

                FieldContainer {
                    Layout.columnSpan: 2
                    Layout.fillWidth: true

                    title: "Imagen Docker"

                    PasswordField {
                        id: imageInput

                        anchors.fill: parent

                        placeholder:
                            "postgres:17"
                    }
                }

                FieldContainer {
                    Layout.fillWidth: true

                    title: "Usuario"

                    PasswordField {
                        id: userInput

                        anchors.fill: parent

                        placeholder:
                            "usuario"
                    }
                }

                FieldContainer {
                    Layout.fillWidth: true

                    title:
                        root.selectedEngine === "redis"
                            ? "Base lógica"
                            : "Base de datos"

                    PasswordField {
                        id: databaseInput

                        anchors.fill: parent

                        placeholder:
                            "appdb"
                    }
                }

                FieldContainer {
                    Layout.columnSpan: 2
                    Layout.fillWidth: true

                    title: "Contraseña"

                    PasswordField {
                        id: passwordInput

                        anchors.fill: parent

                        placeholder:
                            "Contraseña"

                        passwordMode: true

                        onAccepted:
                            root.submit()
                    }
                }

                FieldContainer {
                    Layout.fillWidth: true

                    title: "Volumen persistente"

                    PasswordField {
                        id: volumeInput

                        anchors.fill: parent

                        placeholder:
                            "postgres-dev-data"
                    }
                }

                FieldContainer {
                    Layout.fillWidth: true

                    title: "Red Docker opcional"

                    PasswordField {
                        id: networkInput

                        anchors.fill: parent

                        placeholder:
                            "bridge"
                    }
                }
            }

            // =============================================
            // RESUMEN
            // =============================================

            Rectangle {
                Layout.fillWidth: true

                implicitHeight:
                    summaryColumn.implicitHeight + 20

                radius: 14
                color: "#151612"

                border.width: 1
                border.color: "#34362f"

                ColumnLayout {
                    id: summaryColumn

                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top

                        leftMargin: 10
                        rightMargin: 10
                        topMargin: 10
                    }

                    spacing: 5

                    Text {
                        Layout.fillWidth: true

                        text: "Resumen"

                        color: "#d5a84f"

                        font.pixelSize: 11
                        font.bold: true
                    }

                    Text {
                        Layout.fillWidth: true

                        text:
                            "Contenedor: "
                            + containerNameInput.text

                        color: "#ece8dc"
                        font.pixelSize: 9

                        elide: Text.ElideMiddle
                    }

                    Text {
                        Layout.fillWidth: true

                        text:
                            "Imagen: "
                            + imageInput.text

                        color: "#ece8dc"
                        font.pixelSize: 9

                        elide: Text.ElideMiddle
                    }

                    Text {
                        Layout.fillWidth: true

                        text:
                            "Puerto: localhost:"
                            + portInput.text

                        color: "#ece8dc"
                        font.pixelSize: 9
                    }

                    Text {
                        Layout.fillWidth: true

                        text:
                            "Volumen: "
                            + volumeInput.text

                        color: "#ece8dc"
                        font.pixelSize: 9

                        elide: Text.ElideMiddle
                    }
                }
            }

            // =============================================
            // CREAR
            // =============================================

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 46

                radius: 13

                color: {
                    if (root.service.creating)
                        return "#292a24"

                    if (createMouse.containsMouse)
                        return "#e1b75f"

                    return "#d5a84f"
                }

                opacity:
                    root.service.creating
                        ? 0.6
                        : 1

                Text {
                    anchors.centerIn: parent

                    text:
                        root.service.creating
                            ? "Creando contenedor…"
                            : "Crear base de datos"

                    color:
                        root.service.creating
                            ? "#aaa89d"
                            : "#11120f"

                    font.pixelSize: 12
                    font.bold: true
                }

                MouseArea {
                    id: createMouse

                    anchors.fill: parent
                    hoverEnabled: true

                    enabled:
                        !root.service.creating

                    cursorShape:
                        enabled
                            ? Qt.PointingHandCursor
                            : Qt.ForbiddenCursor

                    onClicked:
                        root.submit()
                }
            }

            Item {
                Layout.preferredHeight: 10
            }
        }
    }

    component FieldContainer: ColumnLayout {
        id: fieldContainer

        property string title: ""

        implicitHeight: 66
        spacing: 5

        default property alias content:
            inputContainer.data

        Text {
            text:
                fieldContainer.title

            color: "#aaa89d"
            font.pixelSize: 10
        }

        Item {
            id: inputContainer

            Layout.fillWidth: true
            Layout.preferredHeight: 44
        }
    }
}
