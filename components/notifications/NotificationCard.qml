import QtQuick
import QtQuick.Layouts

import Quickshell
import Quickshell.Widgets

Rectangle {
    id: root

    required property var notification

    property string resolvedIcon: resolveIcon()

    signal dismissed()

    width: parent ? parent.width : 360
    implicitHeight: contentColumn.implicitHeight + 24

    radius: 16

    color: cardMouse.containsMouse
        ? "#292d37"
        : "#151612"

    border.width: 1
    border.color: "#3a3b34"

    // =========================================================
    // RESOLVER ICONO
    // =========================================================

    function resolveIcon() {
        if (!root.notification)
            return ""

        let iconName = ""

        /*
         * Primero intentamos usar el icono enviado directamente
         * por la aplicación.
         */
        if (
            root.notification.appIcon
            && root.notification.appIcon !== ""
        ) {
            iconName = root.notification.appIcon
        }

        /*
         * Si la aplicación no envió un icono válido,
         * intentamos encontrar su archivo .desktop.
         */
        if (
            iconName === ""
            && root.notification.desktopEntry
            && root.notification.desktopEntry !== ""
        ) {
            const desktopEntry =
                DesktopEntries.heuristicLookup(
                    root.notification.desktopEntry
                )

            if (
                desktopEntry
                && desktopEntry.icon
                && desktopEntry.icon !== ""
            ) {
                iconName = desktopEntry.icon
            }
        }

        /*
         * Como último intento, buscamos usando el nombre
         * de la aplicación.
         */
        if (
            iconName === ""
            && root.notification.appName
            && root.notification.appName !== ""
        ) {
            const appEntry =
                DesktopEntries.heuristicLookup(
                    root.notification.appName
                )

            if (
                appEntry
                && appEntry.icon
                && appEntry.icon !== ""
            ) {
                iconName = appEntry.icon
            }
        }

        if (iconName === "")
            return ""

        /*
         * Si ya es una ruta, URL o fuente de imagen válida,
         * la devolvemos directamente.
         */
        if (
            iconName.startsWith("/")
            || iconName.startsWith("file:")
            || iconName.startsWith("image:")
            || iconName.startsWith("data:")
            || iconName.startsWith("http:")
            || iconName.startsWith("https:")
        ) {
            return iconName
        }

        /*
         * Resuelve nombres del tema de iconos.
         * El parámetro true hace que devuelva vacío si
         * no encuentra el icono.
         */
        const resolved =
            Quickshell.iconPath(iconName, true)

        return resolved || ""
    }

    function fallbackLetter() {
        if (
            root.notification
            && root.notification.appName
            && root.notification.appName.length > 0
        ) {
            return root.notification.appName
                .charAt(0)
                .toUpperCase()
        }

        return "?"
    }

    function dismissNotification() {
        if (!root.notification)
            return

        root.notification.dismiss()
        root.dismissed()
    }

    Behavior on color {
        ColorAnimation {
            duration: 140
        }
    }

    MouseArea {
        id: cardMouse

        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
    }

    ColumnLayout {
        id: contentColumn

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top

            leftMargin: 12
            rightMargin: 12
            topMargin: 12
        }

        spacing: 9

        // =====================================================
        // CABECERA
        // =====================================================

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Rectangle {
                Layout.preferredWidth: 38
                Layout.preferredHeight: 38

                radius: 11
                color: "#34362f"

                IconImage {
                    id: appIcon

                    anchors {
                        fill: parent
                        margins: 7
                    }

                    source: root.resolvedIcon

                    asynchronous: true
                    smooth: true
                    mipmap: true

                    visible:
                        root.resolvedIcon !== ""
                        && status === Image.Ready

                    onStatusChanged: {
                        if (
                            status === Image.Error
                            && source !== ""
                        ) {
                            console.log(
                                "Icono inválido:",
                                root.notification
                                    ? root.notification.appName
                                    : "",
                                root.notification
                                    ? root.notification.appIcon
                                    : "",
                                source
                            )
                        }
                    }
                }

                /*
                 * Si no encontramos icono, mostramos una letra.
                 * Así evitamos el cuadro negro y fucsia.
                 */
                Text {
                    anchors.centerIn: parent

                    visible: !appIcon.visible

                    text: root.fallbackLetter()

                    color: "#ece8dc"
                    font.pixelSize: 15
                    font.bold: true
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    Layout.fillWidth: true

                    text:
                        root.notification
                        && root.notification.appName
                            ? root.notification.appName
                            : "Aplicación"

                    color: "#aaa89d"
                    font.pixelSize: 11

                    elide: Text.ElideRight
                    maximumLineCount: 1
                }

                Text {
                    Layout.fillWidth: true

                    text:
                        root.notification
                        && root.notification.summary
                            ? root.notification.summary
                            : "Notificación"

                    color: "#ece8dc"

                    font.pixelSize: 13
                    font.bold: true

                    wrapMode: Text.Wrap
                    textFormat: Text.PlainText
                }
            }

            Rectangle {
                Layout.preferredWidth: 28
                Layout.preferredHeight: 28

                radius: 9

                color: closeMouse.containsMouse
                    ? "#4a3038"
                    : "transparent"

                Text {
                    anchors.centerIn: parent

                    text: "󰅖"

                    color: closeMouse.containsMouse
                        ? "#d66d68"
                        : "#aaa89d"

                    font.pixelSize: 14
                    font.family: "JetBrainsMono Nerd Font"
                }

                MouseArea {
                    id: closeMouse

                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton
                    cursorShape: Qt.PointingHandCursor

                    onClicked: function(mouse) {
                        root.dismissNotification()
                        mouse.accepted = true
                    }
                }
            }
        }

        // =====================================================
        // CUERPO
        // =====================================================

        Text {
            Layout.fillWidth: true

            visible:
                root.notification
                && root.notification.body
                && root.notification.body !== ""

            text:
                root.notification
                    ? root.notification.body
                    : ""

            color: "#cbd5e1"
            font.pixelSize: 12

            wrapMode: Text.Wrap
            textFormat: Text.PlainText

            maximumLineCount: 5
            elide: Text.ElideRight
        }

        // =====================================================
        // ACCIONES
        // =====================================================

        Flow {
            id: actionsFlow

            Layout.fillWidth: true

            visible:
                root.notification
                && root.notification.actions
                && root.notification.actions.length > 0

            spacing: 6

            Repeater {
                model:
                    root.notification
                        ? root.notification.actions
                        : []

                delegate: Rectangle {
                    required property var modelData

                    width: actionText.implicitWidth + 20
                    height: 28
                    radius: 9

                    color: actionMouse.containsMouse
                        ? "#4a4b42"
                        : "#171814"

                    border.width: 1

                    border.color: actionMouse.containsMouse
                        ? "#d5a84f"
                        : "#454c5b"

                    Text {
                        id: actionText

                        anchors.centerIn: parent

                        text: modelData.text
                        color: "#d7d3c7"

                        font.pixelSize: 11
                        font.weight: Font.Medium
                    }

                    MouseArea {
                        id: actionMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton
                        cursorShape: Qt.PointingHandCursor

                        onClicked: function(mouse) {
                            if (
                                modelData
                                && typeof modelData.invoke
                                    === "function"
                            ) {
                                modelData.invoke()
                            }

                            mouse.accepted = true
                        }
                    }
                }
            }
        }
    }
}
