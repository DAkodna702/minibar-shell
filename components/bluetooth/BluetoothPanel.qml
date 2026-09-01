import QtQuick
import QtQuick.Layouts

import Quickshell
import Quickshell.Bluetooth
import Quickshell.Wayland

Item {
    id: root
    property var targetScreen: null

    required property var service

    readonly property bool opened: bluetoothWindow.visible

    property string statusMessage: ""
    property bool statusIsError: false

    function open() {
        bluetoothWindow.visible = true

        if (root.service.enabled)
            scanDelay.restart()
    }

    function close() {
        bluetoothWindow.visible = false
        root.service.stopScan()
    }

    function toggle() {
        bluetoothWindow.visible
            ? root.close()
            : root.open()
    }

    function showMessage(text, isError) {
        root.statusMessage = text
        root.statusIsError = isError
        messageTimer.restart()
    }

    Connections {
        target: root.service

        function onMessage(text, isError) {
            root.showMessage(text, isError)
        }

        function onEnabledChanged() {
            if (
                root.opened
                && root.service.enabled
                && !root.service.scanning
            ) {
                scanDelay.restart()
            }
        }
    }

    Timer {
        id: scanDelay
        interval: 250
        repeat: false

        onTriggered: {
            if (root.service.enabled && !root.service.scanning)
                root.service.setScanning(true)
        }
    }

    Timer {
        id: messageTimer
        interval: 3500
        repeat: false

        onTriggered: root.statusMessage = ""
    }

    PanelWindow {
        id: bluetoothWindow
        screen: root.targetScreen

        visible: false
        color: "transparent"

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        exclusionMode: ExclusionMode.Ignore

        WlrLayershell.namespace: "minibar-bluetooth-panel"
        WlrLayershell.layer: WlrLayershell.Overlay
        WlrLayershell.exclusiveZone: -1

        WlrLayershell.keyboardFocus:
            bluetoothWindow.visible
                ? WlrKeyboardFocus.OnDemand
                : WlrKeyboardFocus.None

        Rectangle {
            anchors.fill: parent
            color: "#59050605"

            MouseArea {
                anchors.fill: parent
                onClicked: root.close()
            }
        }

        Rectangle {
            id: panel

            anchors {
                top: parent.top
                right: parent.right
                topMargin: 48
                rightMargin: 8
            }

            width: Math.min(454, parent.width - 16)
            height: Math.min(650, parent.height - 56)

            radius: 20
            color: "#f70b0c0a"

            border.width: 1
            border.color: "#4a4b42"

            opacity: bluetoothWindow.visible ? 1 : 0

            transform: Translate {
                x: bluetoothWindow.visible ? 0 : 28

                Behavior on x {
                    NumberAnimation {
                        duration: 220
                        easing.type: Easing.OutCubic
                    }
                }
            }

            Behavior on opacity {
                NumberAnimation { duration: 160 }
            }

            MouseArea {
                anchors.fill: parent
            }

            ColumnLayout {
                anchors {
                    fill: parent
                    margins: 16
                }

                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Rectangle {
                        Layout.preferredWidth: 38
                        Layout.preferredHeight: 38
                        radius: 12
                        color: root.service.enabled
                            ? "#25251f"
                            : "#252b35"

                        Text {
                            anchors.centerIn: parent
                            text: root.service.connectedCount > 0
                                ? "󰂱"
                                : root.service.enabled
                                    ? "󰂯"
                                    : "󰂲"
                            color: root.service.connectedCount > 0
                                ? "#9eb39d"
                                : root.service.enabled
                                    ? "#d5a84f"
                                    : "#65675f"
                            font.pixelSize: 20
                            font.family: "JetBrainsMono Nerd Font"
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        Text {
                            Layout.fillWidth: true
                            text: "Bluetooth"
                            color: "#ece8dc"
                            font.pixelSize: 18
                            font.bold: true
                        }

                        Text {
                            Layout.fillWidth: true
                            text: {
                                if (!root.service.available)
                                    return "No se encontró un adaptador"
                                if (root.service.blocked)
                                    return "Bloqueado por rfkill"
                                if (!root.service.enabled)
                                    return "Desactivado"
                                if (root.service.connectedCount > 0) {
                                    return root.service.connectedCount
                                        + (root.service.connectedCount === 1
                                            ? " dispositivo conectado"
                                            : " dispositivos conectados")
                                }
                                return "Listo para conectar"
                            }
                            color: "#8792a6"
                            font.pixelSize: 10
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 30
                        Layout.preferredHeight: 30
                        radius: 10
                        color: closeMouse.containsMouse
                            ? "#1d1e1a"
                            : "transparent"

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
                    Layout.preferredHeight: 66
                    radius: 15
                    color: "#11120f"
                    border.width: 1
                    border.color: root.service.enabled
                        ? "#334b68"
                        : "#2c3542"

                    RowLayout {
                        anchors {
                            fill: parent
                            leftMargin: 14
                            rightMargin: 12
                        }
                        spacing: 12

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                text: "Conexión Bluetooth"
                                color: "#d7d3c7"
                                font.pixelSize: 12
                                font.bold: true
                            }

                            Text {
                                text: root.service.enabled
                                    ? "Visible para dispositivos emparejados"
                                    : "Actívalo para buscar tus audífonos"
                                color: "#77796f"
                                font.pixelSize: 9
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: 46
                            Layout.preferredHeight: 25
                            radius: 13
                            color: root.service.enabled
                                ? "#d5a84f"
                                : "#303846"

                            Rectangle {
                                width: 19
                                height: 19
                                radius: 10
                                anchors.verticalCenter: parent.verticalCenter
                                x: root.service.enabled
                                    ? parent.width - width - 3
                                    : 3
                                color: root.service.enabled
                                    ? "#11120f"
                                    : "#a2acba"

                                Behavior on x {
                                    NumberAnimation {
                                        duration: 170
                                        easing.type: Easing.OutCubic
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                enabled: root.service.available
                                    && !root.service.actionRunning
                                cursorShape: enabled
                                    ? Qt.PointingHandCursor
                                    : Qt.ArrowCursor
                                onClicked: root.service.togglePower()
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        Layout.fillWidth: true
                        text: root.service.enabled
                            ? "Dispositivos"
                            : "Dispositivos guardados"
                        color: "#ece8dc"
                        font.pixelSize: 12
                        font.bold: true
                    }

                    Text {
                        visible: root.statusMessage !== ""
                        Layout.maximumWidth: 190
                        text: root.statusMessage
                        color: root.statusIsError
                            ? "#d66d68"
                            : "#9eb39d"
                        font.pixelSize: 9
                        elide: Text.ElideRight
                    }

                    Rectangle {
                        Layout.preferredWidth: scanLabel.implicitWidth + 24
                        Layout.preferredHeight: 30
                        radius: 10
                        visible: root.service.enabled
                        color: root.service.scanning
                            ? "#25251f"
                            : scanMouse.containsMouse
                                ? "#1d1e1a"
                                : "#1b222c"
                        border.width: root.service.scanning ? 1 : 0
                        border.color: "#d5a84f"

                        Row {
                            anchors.centerIn: parent
                            spacing: 6

                            Text {
                                text: root.service.scanning ? "󰑐" : "󰑓"
                                color: "#d5a84f"
                                font.pixelSize: 13
                                font.family: "JetBrainsMono Nerd Font"

                                RotationAnimation on rotation {
                                    running: root.service.scanning
                                    from: 0
                                    to: 360
                                    duration: 1100
                                    loops: Animation.Infinite
                                }
                            }

                            Text {
                                id: scanLabel
                                text: root.service.scanning
                                    ? "Buscando"
                                    : "Buscar"
                                color: "#ece8dc"
                                font.pixelSize: 10
                                font.bold: true
                            }
                        }

                        MouseArea {
                            id: scanMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.service.toggleScan()
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: "#283341"
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Text {
                        anchors.centerIn: parent
                        width: parent.width - 40
                        visible: root.service.devices.length === 0
                        text: {
                            if (!root.service.available)
                                return "󰂲\nNo se encontró ningún adaptador Bluetooth"
                            if (!root.service.enabled)
                                return "󰂲\nActiva Bluetooth para buscar dispositivos"
                            if (root.service.scanning)
                                return "󰑐\nBuscando dispositivos cercanos…"
                            return "󰂯\nNo se encontraron dispositivos\nPulsa Buscar y activa el modo de emparejamiento de tus audífonos"
                        }
                        color: "#68758a"
                        font.pixelSize: 12
                        font.family: "JetBrainsMono Nerd Font"
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.Wrap
                        lineHeight: 1.25
                    }

                    ListView {
                        id: deviceList
                        anchors.fill: parent
                        visible: root.service.devices.length > 0
                        model: root.service.devices
                        spacing: 8
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        delegate: DeviceCard {
                            required property var modelData
                            width: deviceList.width
                            device: modelData
                        }
                    }
                }
            }
        }

        Item {
            anchors.fill: parent
            focus: bluetoothWindow.visible
            Keys.onEscapePressed: root.close()
        }
    }

    component DeviceCard: Rectangle {
        id: card

        required property var device

        height: 72
        radius: 14
        color: card.device.connected
            ? "#1c2b2c"
            : cardMouse.containsMouse
                ? "#202936"
                : "#11120f"
        border.width: 1
        border.color: card.device.connected
            ? "#345d55"
            : "#24251f"

        MouseArea {
            id: cardMouse
            anchors.fill: parent
            hoverEnabled: true
        }

        RowLayout {
            anchors {
                fill: parent
                leftMargin: 10
                rightMargin: 10
            }
            spacing: 10

            Rectangle {
                Layout.preferredWidth: 40
                Layout.preferredHeight: 40
                radius: 12
                color: card.device.connected
                    ? "#28443e"
                    : "#1d1e1a"

                Text {
                    anchors.centerIn: parent
                    text: root.service.deviceIcon(card.device)
                    color: card.device.connected
                        ? "#9eb39d"
                        : "#d5a84f"
                    font.pixelSize: 20
                    font.family: "JetBrainsMono Nerd Font"
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    Layout.fillWidth: true
                    text: root.service.deviceName(card.device)
                    color: "#ece8dc"
                    font.pixelSize: 12
                    font.bold: true
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    text: root.service.deviceStatus(card.device)
                    color: card.device.connected
                        ? "#9eb39d"
                        : card.device.pairing
                            ? "#d5a84f"
                            : "#77796f"
                    font.pixelSize: 9
                    elide: Text.ElideRight
                }
            }

            Rectangle {
                visible: card.device.paired && !card.device.connected
                Layout.preferredWidth: visible ? 27 : 0
                Layout.preferredHeight: 27
                radius: 9
                color: forgetMouse.containsMouse
                    ? "#3b2930"
                    : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "󰆴"
                    color: forgetMouse.containsMouse
                        ? "#d66d68"
                        : "#778296"
                    font.pixelSize: 13
                    font.family: "JetBrainsMono Nerd Font"
                }

                MouseArea {
                    id: forgetMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.service.forgetDevice(card.device)
                }
            }

            Rectangle {
                Layout.preferredWidth: actionText.implicitWidth + 22
                Layout.preferredHeight: 30
                radius: 10
                color: {
                    if (card.device.connected)
                        return actionMouse.containsMouse
                            ? "#443039"
                            : "#2f2932"

                    if (card.device.pairing)
                        return "#403b2d"

                    return actionMouse.containsMouse
                        ? "#e1b75f"
                        : "#d5a84f"
                }

                Text {
                    id: actionText
                    anchors.centerIn: parent
                    text: {
                        if (card.device.connected)
                            return "Desconectar"
                        if (card.device.pairing)
                            return "Cancelar"
                        if (
                            root.service.pendingAddress
                            === card.device.address
                        ) {
                            return "Conectando"
                        }
                        if (
                            card.device.state
                            === BluetoothDeviceState.Connecting
                        )
                            return "Conectando"
                        if (card.device.paired)
                            return "Conectar"
                        return "Emparejar"
                    }
                    color: card.device.connected
                        ? "#f3a9b8"
                        : card.device.pairing
                            ? "#d5a84f"
                            : "#11120f"
                    font.pixelSize: 9
                    font.bold: true
                }

                MouseArea {
                    id: actionMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: !root.service.actionRunning
                        || root.service.pendingAddress === card.device.address
                    cursorShape: enabled
                        ? Qt.PointingHandCursor
                        : Qt.ArrowCursor
                    onClicked: root.service.toggleDevice(card.device)
                }
            }
        }
    }
}
