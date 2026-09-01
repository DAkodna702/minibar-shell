import QtQuick
import QtQuick.Layouts

import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Item {
    id: root
    property var targetScreen: null

    required property var service
    readonly property bool opened: sshWindow.visible

    property int activeTab: 0
    property string editorMode: ""
    property int keyTypeIndex: 0
    property int profileTypeIndex: 0
    property int keySelectionIndex: 0
    property int vpsSelectionIndex: 0
    property bool protectKey: false
    property string statusMessage: ""
    property bool statusError: false

    readonly property var typeValues: ["account", "vps", "other"]
    readonly property var typeLabels: ["Cuenta", "VPS", "Otro"]

    function open() {
        sshWindow.visible = true
    }

    function close() {
        root.editorMode = ""
        sshWindow.visible = false
    }

    function toggle() {
        root.opened ? root.close() : root.open()
    }

    function cycleKeyType() {
        root.keyTypeIndex = (root.keyTypeIndex + 1) % 3
    }

    function cycleProfileType() {
        root.profileTypeIndex = (root.profileTypeIndex + 1) % 3
        const type = root.typeValues[root.profileTypeIndex]

        if (type === "account") {
            profileUser.text = "git"
            profilePort.text = "22"
        }
    }

    function selectedKey() {
        if (root.service.keys.length === 0)
            return null

        root.keySelectionIndex = Math.max(
            0,
            Math.min(root.keySelectionIndex, root.service.keys.length - 1)
        )
        return root.service.keys[root.keySelectionIndex]
    }

    function selectedVps() {
        const profiles = root.service.vpsProfiles()

        if (profiles.length === 0)
            return null

        root.vpsSelectionIndex = Math.max(
            0,
            Math.min(root.vpsSelectionIndex, profiles.length - 1)
        )
        return profiles[root.vpsSelectionIndex]
    }

    function openKeyEditor(existing) {
        keyName.text = ""
        keyPath.text = "~/.ssh/"
        keyProvider.text = "github"
        keyPurpose.text = ""
        keyHint.text = ""
        root.keyTypeIndex = 0
        root.protectKey = false
        root.editorMode = existing ? "existing-key" : "new-key"
    }

    function openProfileEditor() {
        if (root.service.keys.length === 0) {
            root.service.message("Primero genera o agrega una llave", true)
            return
        }

        profileLabel.text = ""
        profileAlias.text = ""
        profileProvider.text = "github"
        profileHost.text = "github.com"
        profileUser.text = "git"
        profilePort.text = "22"
        profilePurpose.text = ""
        root.profileTypeIndex = 0
        root.keySelectionIndex = 0
        root.editorMode = "profile"
    }

    function applyProvider(provider) {
        profileProvider.text = provider
        profileHost.text = root.service.providerHost(provider)
        profileUser.text = "git"
        profilePort.text = "22"
    }

    function openTunnelEditor() {
        if (root.service.vpsProfiles().length === 0) {
            root.service.message("Primero crea un perfil de tipo VPS", true)
            return
        }

        tunnelName.text = ""
        tunnelLocalPort.text = "3306"
        tunnelRemoteHost.text = "127.0.0.1"
        tunnelRemotePort.text = "3306"
        root.vpsSelectionIndex = 0
        root.editorMode = "tunnel"
    }

    function submitEditor() {
        if (root.editorMode === "new-key") {
            root.service.generateKey({
                name: keyName.text,
                type: root.typeValues[root.keyTypeIndex],
                provider: keyProvider.text,
                purpose: keyPurpose.text,
                protected: root.protectKey,
                hint: keyHint.text
            })
            root.editorMode = ""
        } else if (root.editorMode === "existing-key") {
            root.service.addExistingKey({
                name: keyName.text,
                path: keyPath.text,
                type: root.typeValues[root.keyTypeIndex],
                provider: keyProvider.text,
                purpose: keyPurpose.text,
                protected: root.protectKey,
                hint: keyHint.text
            })
            root.editorMode = ""
        } else if (root.editorMode === "profile") {
            const key = root.selectedKey()

            if (root.service.saveProfile({
                type: root.typeValues[root.profileTypeIndex],
                provider: profileProvider.text,
                label: profileLabel.text,
                purpose: profilePurpose.text,
                alias: profileAlias.text,
                hostname: profileHost.text,
                user: profileUser.text,
                port: profilePort.text,
                keyId: key ? key.id : ""
            }, "")) {
                root.editorMode = ""
            }
        } else if (root.editorMode === "tunnel") {
            const profile = root.selectedVps()

            if (root.service.saveTunnel({
                name: tunnelName.text,
                profileId: profile ? profile.id : "",
                localPort: tunnelLocalPort.text,
                remoteHost: tunnelRemoteHost.text,
                remotePort: tunnelRemotePort.text
            })) {
                root.editorMode = ""
            }
        }
    }

    Connections {
        target: root.service

        function onMessage(text, isError) {
            root.statusMessage = text
            root.statusError = isError
            messageTimer.restart()
        }
    }

    Timer {
        id: messageTimer
        interval: 4000
        repeat: false
        onTriggered: root.statusMessage = ""
    }

    PanelWindow {
        id: sshWindow
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
        WlrLayershell.namespace: "minibar-ssh-panel"
        WlrLayershell.layer: WlrLayershell.Overlay
        WlrLayershell.exclusiveZone: -1
        WlrLayershell.keyboardFocus: root.opened
            ? WlrKeyboardFocus.Exclusive
            : WlrKeyboardFocus.None

        Rectangle {
            anchors.fill: parent
            color: "#66050605"

            MouseArea {
                anchors.fill: parent
                onClicked: root.close()
            }
        }

        Rectangle {
            id: panel
            anchors.centerIn: parent
            width: Math.min(900, sshWindow.width - 60)
            height: Math.min(700, sshWindow.height - 70)
            radius: 22
            color: "#f70b0c0a"
            border.width: 1
            border.color: "#4a4b42"

            MouseArea { anchors.fill: parent }

            ColumnLayout {
                anchors {
                    fill: parent
                    margins: 18
                }
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Rectangle {
                        Layout.preferredWidth: 40
                        Layout.preferredHeight: 40
                        radius: 13
                        color: "#22352f"

                        Text {
                            anchors.centerIn: parent
                            text: "󰌆"
                            color: "#9eb39d"
                            font.pixelSize: 21
                            font.family: "JetBrainsMono Nerd Font"
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        Text {
                            text: "Centro SSH"
                            color: "#ece8dc"
                            font.pixelSize: 19
                            font.bold: true
                        }

                        Text {
                            text: "Llaves, perfiles y túneles sin editar config a mano"
                            color: "#7f8ca1"
                            font.pixelSize: 10
                        }
                    }

                    Text {
                        visible: root.statusMessage !== ""
                        Layout.maximumWidth: 330
                        text: root.statusMessage
                        color: root.statusError ? "#d66d68" : "#9eb39d"
                        font.pixelSize: 10
                        elide: Text.ElideRight
                    }

                    ToolButton {
                        icon: "󰅖"
                        accent: "#ece8dc"
                        onActivated: root.close()
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 7

                    Repeater {
                        model: ["Llaves", "Perfiles", "Túneles"]

                        delegate: Rectangle {
                            required property string modelData
                            required property int index
                            Layout.preferredWidth: 116
                            Layout.preferredHeight: 34
                            radius: 11
                            color: root.activeTab === index
                                ? "#25251f"
                                : tabMouse.containsMouse
                                    ? "#202936"
                                    : "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: modelData
                                color: root.activeTab === index
                                    ? "#d5a84f"
                                    : "#a5b0c0"
                                font.pixelSize: 11
                                font.bold: root.activeTab === index
                            }

                            MouseArea {
                                id: tabMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.activeTab = index
                            }
                        }
                    }

                    Item { Layout.fillWidth: true }

                    ActionButton {
                        visible: root.activeTab === 0
                        label: "Agregar existente"
                        secondary: true
                        onActivated: root.openKeyEditor(true)
                    }

                    ActionButton {
                        label: root.activeTab === 0
                            ? "Generar llave"
                            : root.activeTab === 1
                                ? "Crear perfil"
                                : "Crear túnel"
                        onActivated: {
                            if (root.activeTab === 0)
                                root.openKeyEditor(false)
                            else if (root.activeTab === 1)
                                root.openProfileEditor()
                            else
                                root.openTunnelEditor()
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

                    EmptyState {
                        anchors.centerIn: parent
                        visible: root.activeTab === 0 && root.service.keys.length === 0
                        icon: "󰌆"
                        title: "Aún no hay llaves registradas"
                        subtitle: "Genera una nueva o agrega una que ya exista"
                    }

                    EmptyState {
                        anchors.centerIn: parent
                        visible: root.activeTab === 1 && root.service.profiles.length === 0
                        icon: "󰒍"
                        title: "Aún no hay perfiles"
                        subtitle: "Crea una cuenta de código, VPS u otro host"
                    }

                    EmptyState {
                        anchors.centerIn: parent
                        visible: root.activeTab === 2 && root.service.tunnels.length === 0
                        icon: "󰛳"
                        title: "Aún no hay túneles"
                        subtitle: "Los túneles solo pueden usar perfiles VPS"
                    }

                    ListView {
                        anchors.fill: parent
                        visible: root.activeTab === 0 && root.service.keys.length > 0
                        model: root.service.keys
                        spacing: 8
                        clip: true

                        delegate: KeyCard {
                            required property var modelData
                            width: ListView.view.width
                            keyData: modelData
                        }
                    }

                    ListView {
                        anchors.fill: parent
                        visible: root.activeTab === 1 && root.service.profiles.length > 0
                        model: root.service.profiles
                        spacing: 8
                        clip: true

                        delegate: ProfileCard {
                            required property var modelData
                            width: ListView.view.width
                            profile: modelData
                        }
                    }

                    ListView {
                        anchors.fill: parent
                        visible: root.activeTab === 2 && root.service.tunnels.length > 0
                        model: root.service.tunnels
                        spacing: 8
                        clip: true

                        delegate: TunnelCard {
                            required property var modelData
                            width: ListView.view.width
                            tunnel: modelData
                        }
                    }
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            visible: root.editorMode !== ""
            z: 20
            color: "#a0080b10"

            MouseArea { anchors.fill: parent }

            Rectangle {
                anchors.centerIn: parent
                width: 520
                height: Math.min(editorColumn.implicitHeight + 36, sshWindow.height - 50)
                radius: 20
                color: "#11120f"
                border.width: 1
                border.color: "#405066"

                Flickable {
                    anchors {
                        fill: parent
                        margins: 18
                    }
                    contentWidth: width
                    contentHeight: editorColumn.implicitHeight
                    clip: true

                    ColumnLayout {
                        id: editorColumn
                        width: parent.width
                        spacing: 10

                        RowLayout {
                            Layout.fillWidth: true

                            Text {
                                Layout.fillWidth: true
                                text: root.editorMode === "new-key"
                                    ? "Generar llave SSH"
                                    : root.editorMode === "existing-key"
                                        ? "Agregar llave existente"
                                        : root.editorMode === "profile"
                                            ? "Crear perfil SSH"
                                            : "Crear túnel SSH"
                                color: "#ece8dc"
                                font.pixelSize: 17
                                font.bold: true
                            }

                            ToolButton {
                                icon: "󰅖"
                                onActivated: root.editorMode = ""
                            }
                        }

                        ColumnLayout {
                            visible: root.editorMode === "new-key"
                                || root.editorMode === "existing-key"
                            Layout.fillWidth: true
                            spacing: 9

                            FormField {
                                id: keyName
                                Layout.fillWidth: true
                                label: "Nombre"
                                placeholder: "github_dakodna"
                            }

                            FormField {
                                id: keyPath
                                visible: root.editorMode === "existing-key"
                                Layout.fillWidth: true
                                label: "Ruta de la llave privada"
                                placeholder: "~/.ssh/id_crs_mayers"
                            }

                            SelectorField {
                                Layout.fillWidth: true
                                label: "Tipo"
                                value: root.typeLabels[root.keyTypeIndex]
                                onActivated: root.cycleKeyType()
                            }

                            FormField {
                                id: keyProvider
                                Layout.fillWidth: true
                                label: "Proveedor o categoría"
                                placeholder: "github, gitlab, contabo…"
                            }

                            FormField {
                                id: keyPurpose
                                Layout.fillWidth: true
                                label: "Razón o propósito"
                                placeholder: "Cuenta personal o acceso al VPS"
                            }

                            SelectorField {
                                Layout.fillWidth: true
                                label: "Protección"
                                value: root.protectKey
                                    ? "Con frase secreta"
                                    : "Sin frase secreta"
                                onActivated: root.protectKey = !root.protectKey
                            }

                            FormField {
                                id: keyHint
                                visible: root.protectKey
                                Layout.fillWidth: true
                                label: "Pista opcional (nunca escribas la frase)"
                                placeholder: "Una pista que solo tú entiendas"
                            }

                            Text {
                                visible: root.protectKey && root.editorMode === "new-key"
                                Layout.fillWidth: true
                                text: "La frase se solicitará en una terminal de ssh-keygen y no se guardará."
                                color: "#d5a84f"
                                font.pixelSize: 9
                                wrapMode: Text.Wrap
                            }
                        }

                        ColumnLayout {
                            visible: root.editorMode === "profile"
                            Layout.fillWidth: true
                            spacing: 9

                            SelectorField {
                                Layout.fillWidth: true
                                label: "Tipo de perfil"
                                value: root.typeLabels[root.profileTypeIndex]
                                onActivated: root.cycleProfileType()
                            }

                            RowLayout {
                                visible: root.typeValues[root.profileTypeIndex] === "account"
                                Layout.fillWidth: true
                                spacing: 6

                                ActionButton { label: "GitHub"; secondary: true; onActivated: root.applyProvider("github") }
                                ActionButton { label: "GitLab"; secondary: true; onActivated: root.applyProvider("gitlab") }
                                ActionButton { label: "Bitbucket"; secondary: true; onActivated: root.applyProvider("bitbucket") }
                            }

                            FormField { id: profileLabel; Layout.fillWidth: true; label: "Nombre descriptivo"; placeholder: "Cuenta GitHub personal" }
                            FormField { id: profileAlias; Layout.fillWidth: true; label: "Alias Host"; placeholder: "dakodna" }
                            FormField { id: profileProvider; Layout.fillWidth: true; label: "Proveedor o categoría"; placeholder: "github o contabo" }
                            FormField { id: profileHost; Layout.fillWidth: true; label: "HostName o IP"; placeholder: "github.com o 147.93.180.20" }
                            FormField { id: profileUser; Layout.fillWidth: true; label: "Usuario"; placeholder: "git, root o dbtunnel" }
                            FormField { id: profilePort; Layout.fillWidth: true; label: "Puerto SSH"; placeholder: "22" }
                            FormField { id: profilePurpose; Layout.fillWidth: true; label: "Razón o propósito"; placeholder: "Acceso de producción" }

                            SelectorField {
                                Layout.fillWidth: true
                                label: "Llave"
                                value: root.selectedKey()
                                    ? root.selectedKey().name + " · " + root.selectedKey().path
                                    : "Sin llaves"
                                onActivated: {
                                    if (root.service.keys.length > 0) {
                                        root.keySelectionIndex = (root.keySelectionIndex + 1)
                                            % root.service.keys.length
                                    }
                                }
                            }
                        }

                        ColumnLayout {
                            visible: root.editorMode === "tunnel"
                            Layout.fillWidth: true
                            spacing: 9

                            FormField { id: tunnelName; Layout.fillWidth: true; label: "Nombre"; placeholder: "MySQL CRS Mayers" }

                            SelectorField {
                                Layout.fillWidth: true
                                label: "VPS"
                                value: root.selectedVps()
                                    ? (root.selectedVps().label || root.selectedVps().alias)
                                    : "Sin perfiles VPS"
                                onActivated: {
                                    const profiles = root.service.vpsProfiles()
                                    if (profiles.length > 0)
                                        root.vpsSelectionIndex = (root.vpsSelectionIndex + 1) % profiles.length
                                }
                            }

                            FormField { id: tunnelLocalPort; Layout.fillWidth: true; label: "Puerto local"; placeholder: "3306" }
                            FormField { id: tunnelRemoteHost; Layout.fillWidth: true; label: "Host remoto"; placeholder: "127.0.0.1" }
                            FormField { id: tunnelRemotePort; Layout.fillWidth: true; label: "Puerto remoto"; placeholder: "3306" }

                            Text {
                                Layout.fillWidth: true
                                text: "El túnel se ejecutará en segundo plano. Podrás detenerlo desde esta pestaña."
                                color: "#7f8ca1"
                                font.pixelSize: 9
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.topMargin: 4
                            spacing: 8
                            Item { Layout.fillWidth: true }
                            ActionButton { label: "Cancelar"; secondary: true; onActivated: root.editorMode = "" }
                            ActionButton {
                                label: root.editorMode === "new-key"
                                    ? "Generar"
                                    : root.editorMode === "existing-key"
                                        ? "Agregar"
                                        : "Guardar"
                                onActivated: root.submitEditor()
                            }
                        }
                    }
                }
            }
        }

        Item {
            anchors.fill: parent
            focus: root.opened
            Keys.onEscapePressed: {
                if (root.editorMode !== "")
                    root.editorMode = ""
                else
                    root.close()
            }
        }
    }

    component KeyCard: Rectangle {
        required property var keyData
        height: 82
        radius: 14
        color: "#11120f"
        border.width: 1
        border.color: "#24251f"

        RowLayout {
            anchors { fill: parent; margins: 11 }
            spacing: 11

            Rectangle {
                Layout.preferredWidth: 42
                Layout.preferredHeight: 42
                radius: 13
                color: "#22352f"
                Text { anchors.centerIn: parent; text: "󰌆"; color: "#9eb39d"; font.pixelSize: 20; font.family: "JetBrainsMono Nerd Font" }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text { Layout.fillWidth: true; text: keyData.name; color: "#ece8dc"; font.pixelSize: 12; font.bold: true; elide: Text.ElideRight }
                Text { Layout.fillWidth: true; text: root.service.typeLabel(keyData.type) + " · " + keyData.path; color: "#8290a4"; font.pixelSize: 9; elide: Text.ElideMiddle }
                Text { Layout.fillWidth: true; visible: keyData.purpose || keyData.hint; text: keyData.purpose + (keyData.hint ? " · Pista: " + keyData.hint : ""); color: keyData.hint ? "#d5a84f" : "#77796f"; font.pixelSize: 9; elide: Text.ElideRight }
            }

            ActionButton { label: "Copiar .pub"; secondary: true; onActivated: root.service.copyPublicKey(keyData) }
            ToolButton { icon: "󰆴"; accent: "#d66d68"; onActivated: root.service.removeKeyRecord(keyData) }
        }
    }

    component ProfileCard: Rectangle {
        required property var profile
        height: 82
        radius: 14
        color: "#11120f"
        border.width: 1
        border.color: profile.type === "vps" ? "#34495c" : "#24251f"

        RowLayout {
            anchors { fill: parent; margins: 11 }
            spacing: 11
            Rectangle {
                Layout.preferredWidth: 42; Layout.preferredHeight: 42; radius: 13
                color: profile.type === "vps" ? "#25251f" : "#1d1e1a"
                Text { anchors.centerIn: parent; text: profile.type === "vps" ? "󰒋" : "󰊤"; color: profile.type === "vps" ? "#d5a84f" : "#9eb39d"; font.pixelSize: 20; font.family: "JetBrainsMono Nerd Font" }
            }
            ColumnLayout {
                Layout.fillWidth: true; spacing: 2
                Text { Layout.fillWidth: true; text: profile.label || profile.alias; color: "#ece8dc"; font.pixelSize: 12; font.bold: true; elide: Text.ElideRight }
                Text { Layout.fillWidth: true; text: profile.user + "@" + profile.hostname + (profile.port !== 22 ? ":" + profile.port : "") + " · Host " + profile.alias; color: "#8290a4"; font.pixelSize: 9; elide: Text.ElideMiddle }
                Text { Layout.fillWidth: true; visible: profile.purpose; text: profile.purpose; color: "#77796f"; font.pixelSize: 9; elide: Text.ElideRight }
            }
            ActionButton { visible: profile.type === "vps"; label: "Abrir terminal"; onActivated: root.service.openVpsTerminal(profile) }
            ToolButton { icon: "󰆴"; accent: "#d66d68"; onActivated: root.service.removeProfile(profile) }
        }
    }

    component TunnelCard: Rectangle {
        required property var tunnel
        readonly property var profile: root.service.profileById(tunnel.profileId)
        readonly property bool active: root.service.tunnelActive(tunnel)
        height: 82
        radius: 14
        color: active ? "#1c2b2c" : "#11120f"
        border.width: 1
        border.color: active ? "#345d55" : "#24251f"

        RowLayout {
            anchors { fill: parent; margins: 11 }
            spacing: 11
            Rectangle {
                Layout.preferredWidth: 42; Layout.preferredHeight: 42; radius: 13
                color: active ? "#28443e" : "#1d1e1a"
                Text { anchors.centerIn: parent; text: "󰛳"; color: active ? "#9eb39d" : "#d5a84f"; font.pixelSize: 20; font.family: "JetBrainsMono Nerd Font" }
            }
            ColumnLayout {
                Layout.fillWidth: true; spacing: 2
                Text { Layout.fillWidth: true; text: tunnel.name; color: "#ece8dc"; font.pixelSize: 12; font.bold: true; elide: Text.ElideRight }
                Text { Layout.fillWidth: true; text: "localhost:" + tunnel.localPort + "  →  " + tunnel.remoteHost + ":" + tunnel.remotePort; color: "#8290a4"; font.pixelSize: 9; elide: Text.ElideMiddle }
                Text { text: active ? "Activo" : root.service.portOccupied(tunnel.localPort) ? "Puerto ocupado" : (profile ? "VPS: " + (profile.label || profile.alias) : "Perfil no disponible"); color: active ? "#9eb39d" : root.service.portOccupied(tunnel.localPort) ? "#d5a84f" : "#77796f"; font.pixelSize: 9 }
            }
            ActionButton { label: active ? "Detener" : "Iniciar"; danger: active; enabled: active || !root.service.portOccupied(tunnel.localPort); onActivated: active ? root.service.stopTunnel(tunnel) : root.service.startTunnel(tunnel) }
            ToolButton { visible: !active; icon: "󰆴"; accent: "#d66d68"; onActivated: root.service.removeTunnel(tunnel) }
        }
    }

    component FormField: ColumnLayout {
        id: formField

        property alias text: fieldInput.text
        property string label: ""
        property string placeholder: ""
        spacing: 4

        Text {
            text: formField.label
            color: "#97a4b7"
            font.pixelSize: 9
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 39
            radius: 11
            color: "#1a222c"
            border.width: fieldInput.activeFocus ? 1 : 0
            border.color: "#d5a84f"

            Text {
                anchors {
                    left: parent.left
                    leftMargin: 12
                    verticalCenter: parent.verticalCenter
                }
                visible: fieldInput.text === ""
                text: formField.placeholder
                color: "#586579"
                font.pixelSize: 10
            }

            TextInput {
                id: fieldInput
                anchors {
                    fill: parent
                    leftMargin: 12
                    rightMargin: 12
                }
                verticalAlignment: TextInput.AlignVCenter
                color: "#d7d3c7"
                selectionColor: "#d5a84f"
                selectedTextColor: "#11120f"
                font.pixelSize: 11
                clip: true
            }
        }
    }

    component SelectorField: ColumnLayout {
        id: selectorField

        property string label: ""
        property string value: ""
        signal activated()
        spacing: 4

        Text {
            text: selectorField.label
            color: "#97a4b7"
            font.pixelSize: 9
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 39
            radius: 11
            color: selectorMouse.containsMouse ? "#1d1e1a" : "#1a222c"

            RowLayout {
                anchors {
                    fill: parent
                    leftMargin: 12
                    rightMargin: 12
                }

                Text {
                    Layout.fillWidth: true
                    text: selectorField.value
                    color: "#d7d3c7"
                    font.pixelSize: 11
                    elide: Text.ElideRight
                }

                Text {
                    text: "󰅀"
                    color: "#d5a84f"
                    font.family: "JetBrainsMono Nerd Font"
                }
            }

            MouseArea {
                id: selectorMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: selectorField.activated()
            }
        }
    }

    component ActionButton: Rectangle {
        property string label: ""
        property bool secondary: false
        property bool danger: false
        signal activated()
        implicitWidth: actionLabel.implicitWidth + 24
        implicitHeight: 32
        radius: 10
        opacity: enabled ? 1 : 0.45
        color: danger ? (actionMouse.containsMouse ? "#57333d" : "#3b2931") : secondary ? (actionMouse.containsMouse ? "#293442" : "#1b232d") : (actionMouse.containsMouse ? "#e1b75f" : "#d5a84f")
        Text { id: actionLabel; anchors.centerIn: parent; text: parent.label; color: parent.danger ? "#f3a9b8" : parent.secondary ? "#c5d0df" : "#11120f"; font.pixelSize: 10; font.bold: true }
        MouseArea { id: actionMouse; anchors.fill: parent; hoverEnabled: true; enabled: parent.enabled; cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor; onClicked: parent.activated() }
    }

    component ToolButton: Rectangle {
        property string icon: ""
        property color accent: "#ece8dc"
        signal activated()
        implicitWidth: 30; implicitHeight: 30; radius: 10
        color: toolMouse.containsMouse ? "#293442" : "transparent"
        Text { anchors.centerIn: parent; text: parent.icon; color: parent.accent; font.pixelSize: 14; font.family: "JetBrainsMono Nerd Font" }
        MouseArea { id: toolMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: parent.activated() }
    }

    component EmptyState: Column {
        property string icon: ""
        property string title: ""
        property string subtitle: ""
        spacing: 7
        Text { anchors.horizontalCenter: parent.horizontalCenter; text: parent.icon; color: "#506078"; font.pixelSize: 30; font.family: "JetBrainsMono Nerd Font" }
        Text { anchors.horizontalCenter: parent.horizontalCenter; text: parent.title; color: "#aab6c7"; font.pixelSize: 12; font.bold: true }
        Text { anchors.horizontalCenter: parent.horizontalCenter; text: parent.subtitle; color: "#657286"; font.pixelSize: 10 }
    }
}
