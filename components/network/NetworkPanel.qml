import QtQuick
import QtQuick.Layouts

import Quickshell
import Quickshell.Wayland

Item {
    id: root
    property var targetScreen: null

    required property var service

    readonly property bool opened:
        networkWindow.visible

    property var selectedNetwork: null
    property bool passwordDialogVisible: false
    property bool passwordVisible: false
    property string panelMessage: ""

    function open() {
        networkWindow.visible = true
        root.service.refreshAll()
    }

    function close() {
        networkWindow.visible = false
        closePasswordDialog()
    }

    function toggle() {
        networkWindow.visible
            ? close()
            : open()
    }

    function openPasswordDialog(network) {
        root.selectedNetwork = network
        root.passwordVisible = false
        root.passwordDialogVisible = true

        passwordInput.text = ""
        passwordFocusTimer.restart()
    }

    function closePasswordDialog() {
        root.passwordDialogVisible = false
        root.passwordVisible = false
        root.selectedNetwork = null
        passwordInput.text = ""
    }

    Connections {
        target: root.service

        function onPasswordRequested(network) {
            root.openPasswordDialog(network)
        }

        function onConnectionSucceeded(name) {
            root.panelMessage =
                "Conectado correctamente"

            root.closePasswordDialog()
            messageTimer.restart()
        }

        function onConnectionFailed(message) {
            root.panelMessage = message
            messageTimer.restart()
        }
    }

    Timer {
        id: passwordFocusTimer

        interval: 80
        repeat: false

        onTriggered: {
            passwordInput.forceActiveFocus()
        }
    }

    Timer {
        id: messageTimer

        interval: 3500
        repeat: false

        onTriggered: {
            root.panelMessage = ""
        }
    }

    PanelWindow {
        id: networkWindow
        screen: root.targetScreen

        visible: false
        color: "transparent"

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        WlrLayershell.namespace:
            "minibar-network-panel"

        WlrLayershell.layer:
            WlrLayershell.Overlay

        WlrLayershell.exclusiveZone: -1

        WlrLayershell.keyboardFocus:
            networkWindow.visible
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
            anchors.fill: parent
            color: "transparent"

            Rectangle {
                id: panel

                anchors {
                    top: parent.top
                    right: parent.right
                    topMargin: 48
                    rightMargin: 8
                    bottomMargin: 8
                }

                width: Math.min(454, parent.width - 16)
                height: Math.min(634, parent.height - 56)

                radius: 20
                color: "#f70b0c0a"

                border.width: 1
                border.color: "#4a4b42"

                MouseArea {
                    anchors.fill: parent
                }

                ColumnLayout {
                    anchors {
                        fill: parent
                        margins: 16
                    }

                    spacing: 12

                    // =========================================
                    // CABECERA
                    // =========================================

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            Layout.fillWidth: true

                            text: "Red"

                            color: "#ece8dc"
                            font.pixelSize: 19
                            font.bold: true
                        }

                        Rectangle {
                            Layout.preferredWidth: 30
                            Layout.preferredHeight: 30

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
                                    root.service.refreshAll()
                                }
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: 30
                            Layout.preferredHeight: 30

                            radius: 10

                            color:
                                closeMouse.containsMouse
                                    ? "#292a24"
                                    : "#171814"

                            Text {
                                anchors.centerIn: parent

                                text: "󰅖"
                                color: "#ece8dc"

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

                                onClicked: root.close()
                            }
                        }
                    }

                    // =========================================
                    // CONEXIÓN ACTUAL
                    // =========================================

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight:
                            currentColumn.implicitHeight + 24

                        radius: 16

                        color: "#151612"

                        border.width: 1
                        border.color:
                            root.service.connectionType
                                !== "none"
                                ? "#d5a84f"
                                : "#34362f"

                        ColumnLayout {
                            id: currentColumn

                            anchors {
                                left: parent.left
                                right: parent.right
                                top: parent.top

                                leftMargin: 12
                                rightMargin: 12
                                topMargin: 12
                            }

                            spacing: 10

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10

                                Rectangle {
                                    Layout.preferredWidth: 42
                                    Layout.preferredHeight: 42

                                    radius: 12
                                    color: "#25251f"

                                    Text {
                                        anchors.centerIn: parent

                                        text:
                                            root.service.mainIcon()

                                        color: "#d5a84f"

                                        font.pixelSize: 21
                                        font.family:
                                            "JetBrainsMono Nerd Font"
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    Text {
                                        Layout.fillWidth: true

                                        text: {
                                            if (
                                                root.service.connectionType
                                                === "wifi"
                                            ) {
                                                return root.service
                                                    .connectionName
                                                    || "Wi-Fi"
                                            }

                                            if (
                                                root.service.connectionType
                                                === "ethernet"
                                            ) {
                                                return root.service
                                                    .connectionName
                                                    || "Ethernet"
                                            }

                                            return "Sin conexión"
                                        }

                                        color: "#ece8dc"
                                        font.pixelSize: 14
                                        font.bold: true

                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        Layout.fillWidth: true

                                        text: {
                                            if (
                                                root.service.connectionType
                                                === "wifi"
                                            ) {
                                                return "Conectado por Wi-Fi"
                                            }

                                            if (
                                                root.service.connectionType
                                                === "ethernet"
                                            ) {
                                                return "Conectado por cable"
                                            }

                                            return "No hay una red activa"
                                        }

                                        color: "#aaa89d"
                                        font.pixelSize: 10
                                    }

                                    Text {
                                        visible:
                                            root.service.ipAddress !== ""

                                        text:
                                            "IP: "
                                            + root.service.ipAddress

                                        color: "#65675f"
                                        font.pixelSize: 9
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 1
                                color: "#34362f"
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10

                                SpeedCard {
                                    Layout.fillWidth: true

                                    icon: "󰇚"
                                    title: "Descarga"

                                    value:
                                        root.service.formatSpeed(
                                            root.service
                                                .downloadBytesPerSecond
                                        )

                                    accent: "#d5a84f"
                                }

                                SpeedCard {
                                    Layout.fillWidth: true

                                    icon: "󰕒"
                                    title: "Subida"

                                    value:
                                        root.service.formatSpeed(
                                            root.service
                                                .uploadBytesPerSecond
                                        )

                                    accent: "#9eb39d"
                                }
                            }
                        }
                    }

                    // =========================================
                    // SELECTOR WI-FI / ETHERNET
                    // =========================================

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 42

                            radius: 12

                            color:
                                root.service.wifiEnabled
                                    ? "#25251f"
                                    : "#151612"

                            border.width:
                                root.service.connectionType
                                === "wifi"
                                    ? 2
                                    : 1

                            border.color:
                                root.service.connectionType
                                === "wifi"
                                    ? "#d5a84f"
                                    : "#3a3b34"

                            Row {
                                anchors.centerIn: parent
                                spacing: 7

                                Text {
                                    text: root.service.wifiEnabled
                                        ? "󰤨"
                                        : "󰤭"

                                    color: root.service.wifiEnabled
                                        ? "#d5a84f"
                                        : "#65675f"

                                    font.pixelSize: 16
                                    font.family:
                                        "JetBrainsMono Nerd Font"
                                }

                                Text {
                                    text:
                                        root.service.wifiEnabled
                                            ? "Wi-Fi activado"
                                            : "Wi-Fi desactivado"

                                    color: "#d7d3c7"
                                    font.pixelSize: 11
                                }
                            }

                            MouseArea {
                                anchors.fill: parent

                                cursorShape:
                                    Qt.PointingHandCursor

                                onClicked: {
                                    root.service.setWifiEnabled(
                                        !root.service.wifiEnabled
                                    )
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 42

                            radius: 12

                            color:
                                root.service.connectionType
                                === "ethernet"
                                    ? "#25251f"
                                    : "#151612"

                            border.width:
                                root.service.connectionType
                                === "ethernet"
                                    ? 2
                                    : 1

                            border.color:
                                root.service.connectionType
                                === "ethernet"
                                    ? "#d5a84f"
                                    : "#3a3b34"

                            opacity:
                                root.service.ethernetInterface
                                !== ""
                                    ? 1
                                    : 0.45

                            Row {
                                anchors.centerIn: parent
                                spacing: 7

                                Text {
                                    text: "󰈀"
                                    color: "#d5a84f"

                                    font.pixelSize: 16
                                    font.family:
                                        "JetBrainsMono Nerd Font"
                                }

                                Text {
                                    text:
                                        root.service.connectionType
                                        === "ethernet"
                                            ? "Cable activo"
                                            : "Usar cable"

                                    color: "#d7d3c7"
                                    font.pixelSize: 11
                                }
                            }

                            MouseArea {
                                anchors.fill: parent

                                enabled:
                                    root.service.ethernetInterface
                                    !== ""

                                cursorShape:
                                    enabled
                                        ? Qt.PointingHandCursor
                                        : Qt.ArrowCursor

                                onClicked: {
                                    root.service.useEthernet()
                                }
                            }
                        }
                    }

                    // =========================================
                    // MENSAJE
                    // =========================================

                    Text {
                        Layout.fillWidth: true

                        visible:
                            root.panelMessage !== ""
                            || root.service.connecting

                        text:
                            root.service.connecting
                                ? root.service.statusMessage
                                : root.panelMessage

                        color:
                            root.service.connecting
                                ? "#d5a84f"
                                : "#d5a84f"

                        font.pixelSize: 10

                        horizontalAlignment:
                            Text.AlignHCenter

                        wrapMode: Text.Wrap
                    }

                    // =========================================
                    // LISTA DE REDES
                    // =========================================

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            Layout.fillWidth: true

                            text: "Redes Wi-Fi disponibles"

                            color: "#ece8dc"
                            font.pixelSize: 13
                            font.bold: true
                        }

                        Text {
                            visible: root.service.loading

                            text: "Buscando…"

                            color: "#d5a84f"
                            font.pixelSize: 10
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        Text {
                            anchors.centerIn: parent

                            visible:
                                !root.service.wifiEnabled

                            text:
                                "󰤭\nEl Wi-Fi está desactivado"

                            horizontalAlignment:
                                Text.AlignHCenter

                            color: "#65675f"

                            font.pixelSize: 13
                            font.family:
                                "JetBrainsMono Nerd Font"
                        }

                        ListView {
                            id: networkList

                            anchors.fill: parent

                            visible:
                                root.service.wifiEnabled

                            model: root.service.networks

                            spacing: 7
                            clip: true

                            boundsBehavior:
                                Flickable.StopAtBounds

                            delegate: NetworkItem {
                                required property var modelData

                                width: networkList.width
                                network: modelData

                                onSelected: {
                                    root.service.selectNetwork(
                                        network
                                    )
                                }
                            }
                        }
                    }
                }
            }

            // =============================================
            // DIÁLOGO DE CONTRASEÑA
            // =============================================

            Rectangle {
                anchors.fill: parent

                visible:
                    root.passwordDialogVisible

                color: "#99000000"

                MouseArea {
                    anchors.fill: parent

                    onClicked: {
                        root.closePasswordDialog()
                    }
                }

                Rectangle {
                    id: passwordDialog

                    anchors.centerIn: parent

                    width: 380
                    height:
                        passwordColumn.implicitHeight + 32

                    radius: 20

                    color: "#f217191f"

                    border.width: 1
                    border.color: "#d5a84f"

                    MouseArea {
                        anchors.fill: parent
                    }

                    ColumnLayout {
                        id: passwordColumn

                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top

                            leftMargin: 16
                            rightMargin: 16
                            topMargin: 16
                        }

                        spacing: 12

                        Text {
                            Layout.fillWidth: true

                            text: "Conectarse a la red"

                            color: "#ece8dc"

                            font.pixelSize: 16
                            font.bold: true
                        }

                        Text {
                            Layout.fillWidth: true

                            text:
                                root.selectedNetwork
                                    ? root.selectedNetwork.ssid
                                    : ""

                            color: "#d5a84f"

                            font.pixelSize: 13
                            font.bold: true

                            elide: Text.ElideRight
                        }

                        Text {
                            Layout.fillWidth: true

                            text:
                                root.selectedNetwork
                                    ? "Seguridad: "
                                        + root.service.securityLabel(
                                            root.selectedNetwork.security
                                        )
                                    : ""

                            color: "#aaa89d"
                            font.pixelSize: 10
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 44

                            radius: 12
                            color: "#151612"

                            border.width:
                                passwordInput.activeFocus
                                    ? 1
                                    : 0

                            border.color: "#d5a84f"

                            Row {
                                anchors {
                                    fill: parent
                                    leftMargin: 12
                                    rightMargin: 6
                                }

                                spacing: 6

                                Item {
                                    width:
                                        parent.width - 42

                                    height: parent.height

                                    Text {
                                        anchors.verticalCenter:
                                            parent.verticalCenter

                                        visible:
                                            passwordInput.text === ""

                                        text: "Contraseña"

                                        color: "#65675f"
                                        font.pixelSize: 12
                                    }

                                    TextInput {
                                        id: passwordInput

                                        anchors.fill: parent

                                        verticalAlignment:
                                            TextInput.AlignVCenter

                                        color: "#d7d3c7"
                                        font.pixelSize: 12

                                        echoMode:
                                            root.passwordVisible
                                                ? TextInput.Normal
                                                : TextInput.Password

                                        passwordCharacter: "●"

                                        selectionColor: "#d5a84f"
                                        selectedTextColor: "#11120f"

                                        clip: true

                                        Keys.onReturnPressed: {
                                            connectPasswordButton
                                                .connect()
                                        }

                                        Keys.onEnterPressed: {
                                            connectPasswordButton
                                                .connect()
                                        }

                                        Keys.onEscapePressed: {
                                            root.closePasswordDialog()
                                        }
                                    }
                                }

                                Rectangle {
                                    width: 36
                                    height: 36

                                    anchors.verticalCenter:
                                        parent.verticalCenter

                                    radius: 10

                                    color:
                                        eyeMouse.containsMouse
                                            ? "#292a24"
                                            : "transparent"

                                    Text {
                                        anchors.centerIn: parent

                                        text:
                                            root.passwordVisible
                                                ? "󰈈"
                                                : "󰈉"

                                        color: "#ece8dc"

                                        font.pixelSize: 16
                                        font.family:
                                            "JetBrainsMono Nerd Font"
                                    }

                                    MouseArea {
                                        id: eyeMouse

                                        anchors.fill: parent
                                        hoverEnabled: true

                                        cursorShape:
                                            Qt.PointingHandCursor

                                        onClicked: {
                                            root.passwordVisible =
                                                !root.passwordVisible

                                            passwordInput
                                                .forceActiveFocus()
                                        }
                                    }
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 38

                                radius: 12
                                color: "#171814"

                                Text {
                                    anchors.centerIn: parent

                                    text: "Cancelar"
                                    color: "#ece8dc"

                                    font.pixelSize: 11
                                }

                                MouseArea {
                                    anchors.fill: parent

                                    cursorShape:
                                        Qt.PointingHandCursor

                                    onClicked: {
                                        root.closePasswordDialog()
                                    }
                                }
                            }

                            Rectangle {
                                id: connectPasswordButton

                                Layout.fillWidth: true
                                Layout.preferredHeight: 38

                                radius: 12

                                color:
                                    connectMouse.containsMouse
                                        ? "#e1b75f"
                                        : "#d5a84f"

                                function connect() {
                                    if (
                                        !root.selectedNetwork
                                        || passwordInput.text.length
                                            === 0
                                    ) {
                                        root.panelMessage =
                                            "Escribe la contraseña"

                                        messageTimer.restart()
                                        return
                                    }

                                    root.service
                                        .connectProtectedNetwork(
                                            root.selectedNetwork,
                                            passwordInput.text
                                        )
                                }

                                Text {
                                    anchors.centerIn: parent

                                    text: "Conectar"
                                    color: "#11120f"

                                    font.pixelSize: 11
                                    font.bold: true
                                }

                                MouseArea {
                                    id: connectMouse

                                    anchors.fill: parent
                                    hoverEnabled: true

                                    cursorShape:
                                        Qt.PointingHandCursor

                                    onClicked: {
                                        connectPasswordButton.connect()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Item {
            anchors.fill: parent

            focus: networkWindow.visible

            Keys.onEscapePressed: {
                if (root.passwordDialogVisible)
                    root.closePasswordDialog()
                else
                    root.close()
            }
        }
    }

    // =========================================================
    // COMPONENTE VELOCIDAD
    // =========================================================

    component SpeedCard: Rectangle {
        id: speedCard

        property string icon: ""
        property string title: ""
        property string value: ""
        property color accent: "#d5a84f"

        implicitHeight: 58

        radius: 12
        color: "#151612"

        Row {
            anchors {
                fill: parent
                margins: 10
            }

            spacing: 8

            Text {
                anchors.verticalCenter:
                    parent.verticalCenter

                text: speedCard.icon
                color: speedCard.accent

                font.pixelSize: 17
                font.family:
                    "JetBrainsMono Nerd Font"
            }

            Column {
                anchors.verticalCenter:
                    parent.verticalCenter

                spacing: 2

                Text {
                    text: speedCard.title

                    color: "#65675f"
                    font.pixelSize: 9
                }

                Text {
                    text: speedCard.value

                    color: "#d7d3c7"
                    font.pixelSize: 11
                    font.bold: true
                }
            }
        }
    }

    // =========================================================
    // ELEMENTO DE RED
    // =========================================================

    component NetworkItem: Rectangle {
        id: networkItem

        required property var network

        signal selected()

        height: 58
        radius: 14

        color:
            networkMouse.containsMouse
                ? "#171814"
                : "#151612"

        border.width:
            network.active ? 2 : 1

        border.color:
            network.active
                ? "#d5a84f"
                : "#34362f"

        RowLayout {
            anchors {
                fill: parent
                margins: 10
            }

            spacing: 10

            Rectangle {
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36

                radius: 11

                color:
                    network.active
                        ? "#25251f"
                        : "#34362f"

                Text {
                    anchors.centerIn: parent

                    text:
                        root.service.signalIcon(
                            network.signal
                        )

                    color:
                        network.active
                            ? "#d5a84f"
                            : "#ece8dc"

                    font.pixelSize: 18
                    font.family:
                        "JetBrainsMono Nerd Font"
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    Layout.fillWidth: true

                    text: network.ssid

                    color: "#ece8dc"

                    font.pixelSize: 12
                    font.bold:
                        network.active

                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true

                    text:
                        root.service.securityLabel(
                            network.security
                        )
                        + "  ·  "
                        + network.signal
                        + "%"

                    color: "#65675f"
                    font.pixelSize: 9
                }
            }

            Text {
                visible:
                    !network.open

                text: "󰌾"

                color: "#aaa89d"

                font.pixelSize: 14
                font.family:
                    "JetBrainsMono Nerd Font"
            }

            Text {
                visible:
                    network.active

                text: "Conectada"

                color: "#9eb39d"

                font.pixelSize: 10
                font.bold: true
            }
        }

        MouseArea {
            id: networkMouse

            anchors.fill: parent
            hoverEnabled: true

            enabled:
                !network.active
                && !root.service.connecting

            cursorShape:
                enabled
                    ? Qt.PointingHandCursor
                    : Qt.ArrowCursor

            onClicked: {
                networkItem.selected()
            }
        }
    }
}
