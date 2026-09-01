import QtQuick

import Quickshell
import Quickshell.Io

Item {
    id: root

    readonly property string homeDirectory: Quickshell.env("HOME")
    readonly property string sshDirectory: root.homeDirectory + "/.ssh"
    readonly property string configPath: root.sshDirectory + "/config"
    readonly property string dataDirectory: Quickshell.dataPath("ssh-manager")
    readonly property string registryPath: root.dataDirectory + "/registry.json"
    readonly property string runtimeDirectory:
        Quickshell.env("XDG_RUNTIME_DIR") !== ""
            ? Quickshell.env("XDG_RUNTIME_DIR") + "/minibar-ssh"
            : "/tmp/minibar-ssh-" + Quickshell.env("USER")
    readonly property string beginMarker: "# >>> MINIBAR-SSH MANAGED"
    readonly property string endMarker: "# <<< MINIBAR-SSH MANAGED"

    property var keys: []
    property var profiles: []
    property var tunnels: []
    property var occupiedPorts: []
    property var activeTunnelIds: []
    property bool loading: true
    property bool operationRunning: false
    property string pendingConfigText: ""

    signal message(string text, bool isError)

    function newId(prefix) {
        return prefix + "-" + Date.now() + "-"
            + Math.floor(Math.random() * 100000)
    }

    function cleanLine(value) {
        return String(value || "")
            .replace(/[\r\n]+/g, " ")
            .trim()
    }

    function expandPath(path) {
        const value = String(path || "").trim()

        if (value === "~")
            return root.homeDirectory

        if (value.startsWith("~/"))
            return root.homeDirectory + value.substring(1)

        return value
    }

    function displayPath(path) {
        const value = String(path || "")

        if (value.startsWith(root.homeDirectory + "/"))
            return "~" + value.substring(root.homeDirectory.length)

        return value
    }

    function typeLabel(type) {
        switch (type) {
        case "account": return "Cuenta de código"
        case "vps": return "VPS"
        default: return "Otro"
        }
    }

    function providerHost(provider) {
        switch (String(provider || "").toLowerCase()) {
        case "github": return "github.com"
        case "gitlab": return "gitlab.com"
        case "bitbucket": return "bitbucket.org"
        default: return ""
        }
    }

    function saveRegistry() {
        registryFile.setText(JSON.stringify({
            version: 1,
            keys: root.keys,
            profiles: root.profiles,
            tunnels: root.tunnels
        }, null, 2) + "\n")
    }

    function loadRegistry() {
        if (!registryFile.loaded)
            return

        try {
            const contents = registryFile.text().trim()
            const parsed = contents === "" ? {} : JSON.parse(contents)

            root.keys = Array.isArray(parsed.keys) ? parsed.keys : []
            root.profiles = Array.isArray(parsed.profiles) ? parsed.profiles : []
            root.tunnels = Array.isArray(parsed.tunnels) ? parsed.tunnels : []
        } catch (error) {
            root.keys = []
            root.profiles = []
            root.tunnels = []
            root.message("No se pudo leer el registro SSH", true)
        }

        root.loading = false
    }

    function keyById(id) {
        for (let i = 0; i < root.keys.length; i++) {
            if (root.keys[i].id === id)
                return root.keys[i]
        }

        return null
    }

    function profileById(id) {
        for (let i = 0; i < root.profiles.length; i++) {
            if (root.profiles[i].id === id)
                return root.profiles[i]
        }

        return null
    }

    function vpsProfiles() {
        return root.profiles.filter(function(profile) {
            return profile.type === "vps"
        })
    }

    function validateKeyConfig(config, existing) {
        const name = root.cleanLine(config.name)
        const path = root.expandPath(config.path)

        if (name === "")
            return "Escribe un nombre para la llave"

        if (!existing && !/^[a-zA-Z0-9_.-]+$/.test(name))
            return "El nombre solo puede usar letras, números, punto, guion y guion bajo"

        if (path === "")
            return "Indica la ruta de la llave"

        for (let i = 0; i < root.keys.length; i++) {
            if (root.expandPath(root.keys[i].path) === path)
                return "Esa llave ya está agregada"
        }

        return ""
    }

    function generateKey(config) {
        if (root.operationRunning)
            return

        const normalized = {
            id: root.newId("key"),
            name: root.cleanLine(config.name),
            path: "~/.ssh/" + root.cleanLine(config.name),
            type: config.type || "account",
            provider: root.cleanLine(config.provider),
            purpose: root.cleanLine(config.purpose),
            protected: Boolean(config.protected),
            hint: config.protected ? root.cleanLine(config.hint) : "",
            createdAt: Date.now(),
            existing: false
        }

        const error = root.validateKeyConfig(normalized, false)

        if (error !== "") {
            root.message(error, true)
            return
        }

        generationProcess.pendingKey = normalized
        root.operationRunning = true

        const command = [
            "ssh-keygen",
            "-q",
            "-t", "ed25519",
            "-f", root.expandPath(normalized.path),
            "-C", normalized.name
        ]

        if (normalized.protected) {
            generationProcess.exec([
                "kitty",
                "--title", "Generar llave SSH · " + normalized.name,
                "--hold",
                "ssh-keygen",
                "-q",
                "-t", "ed25519",
                "-f", root.expandPath(normalized.path),
                "-C", normalized.name
            ])
        } else {
            command.push("-N", "")
            generationProcess.exec(command)
        }
    }

    function addExistingKey(config) {
        if (root.operationRunning)
            return

        const normalized = {
            id: root.newId("key"),
            name: root.cleanLine(config.name),
            path: root.displayPath(root.expandPath(config.path)),
            type: config.type || "account",
            provider: root.cleanLine(config.provider),
            purpose: root.cleanLine(config.purpose),
            protected: Boolean(config.protected),
            hint: config.protected ? root.cleanLine(config.hint) : "",
            createdAt: Date.now(),
            existing: true
        }

        const error = root.validateKeyConfig(normalized, true)

        if (error !== "") {
            root.message(error, true)
            return
        }

        existingKeyProcess.pendingKey = normalized
        root.operationRunning = true
        existingKeyProcess.exec([
            "test",
            "-f",
            root.expandPath(normalized.path)
        ])
    }

    function removeKeyRecord(key) {
        if (!key)
            return

        for (let i = 0; i < root.profiles.length; i++) {
            if (root.profiles[i].keyId === key.id) {
                root.message("La llave está siendo usada por un perfil", true)
                return
            }
        }

        root.keys = root.keys.filter(function(item) {
            return item.id !== key.id
        })
        root.saveRegistry()
        root.message("Registro eliminado; la llave física se conservó", false)
    }

    function copyPublicKey(key) {
        if (!key || copyProcess.running)
            return

        copyProcess.pendingName = key.name
        copyProcess.exec([
            "sh", "-c",
            "if [ -f \"$1.pub\" ]; then wl-copy < \"$1.pub\"; else exit 2; fi",
            "minibar-copy-public-key",
            root.expandPath(key.path)
        ])
    }

    function manualConfigText() {
        if (!configFile.loaded)
            return ""

        const contents = configFile.text()
        const begin = contents.indexOf(root.beginMarker)
        const end = contents.indexOf(root.endMarker)

        if (begin < 0 || end < begin)
            return contents

        return contents.substring(0, begin)
            + contents.substring(end + root.endMarker.length)
    }

    function manualAliasExists(alias) {
        const lines = root.manualConfigText().split("\n")

        for (let i = 0; i < lines.length; i++) {
            const match = lines[i].match(/^\s*Host\s+([^\s#]+)/i)

            if (match && match[1] === alias)
                return true
        }

        return false
    }

    function validateProfile(config, editingId) {
        const alias = root.cleanLine(config.alias)
        const hostname = root.cleanLine(config.hostname)
        const user = root.cleanLine(config.user)
        const port = Number(config.port)

        if (!/^[a-zA-Z0-9_.-]+$/.test(alias))
            return "El alias SSH no es válido"

        if (hostname === "" || /\s/.test(hostname))
            return "El host o IP no es válido"

        if (user === "" || /\s/.test(user))
            return "El usuario SSH no es válido"

        if (!port || port < 1 || port > 65535)
            return "El puerto SSH debe estar entre 1 y 65535"

        if (!root.keyById(config.keyId))
            return "Selecciona una llave"

        if (root.manualAliasExists(alias))
            return "Ese alias ya existe en una entrada manual de ~/.ssh/config"

        for (let i = 0; i < root.profiles.length; i++) {
            if (
                root.profiles[i].alias === alias
                && root.profiles[i].id !== editingId
            ) {
                return "Ese alias ya está registrado"
            }
        }

        return ""
    }

    function saveProfile(config, editingId) {
        const profile = {
            id: editingId || root.newId("profile"),
            type: config.type || "account",
            provider: root.cleanLine(config.provider),
            label: root.cleanLine(config.label),
            purpose: root.cleanLine(config.purpose),
            alias: root.cleanLine(config.alias),
            hostname: root.cleanLine(config.hostname),
            user: root.cleanLine(config.user),
            port: Number(config.port) || 22,
            keyId: config.keyId
        }

        const error = root.validateProfile(profile, editingId || "")

        if (error !== "") {
            root.message(error, true)
            return false
        }

        const result = []
        let replaced = false

        for (let i = 0; i < root.profiles.length; i++) {
            if (root.profiles[i].id === profile.id) {
                result.push(profile)
                replaced = true
            } else {
                result.push(root.profiles[i])
            }
        }

        if (!replaced)
            result.push(profile)

        root.profiles = result
        root.saveRegistry()
        root.syncConfig()
        return true
    }

    function removeProfile(profile) {
        if (!profile)
            return

        root.profiles = root.profiles.filter(function(item) {
            return item.id !== profile.id
        })

        root.tunnels = root.tunnels.filter(function(tunnel) {
            return tunnel.profileId !== profile.id
        })

        root.saveRegistry()
        root.syncConfig()
    }

    function renderManagedBlock() {
        const lines = [root.beginMarker]

        for (let i = 0; i < root.profiles.length; i++) {
            const profile = root.profiles[i]
            const key = root.keyById(profile.keyId)

            if (!key)
                continue

            lines.push("")
            lines.push("# " + root.typeLabel(profile.type)
                + (profile.provider ? " · " + profile.provider : ""))

            if (profile.label)
                lines.push("# Nombre: " + root.cleanLine(profile.label))

            if (profile.purpose)
                lines.push("# Propósito: " + root.cleanLine(profile.purpose))

            lines.push("Host " + profile.alias)
            lines.push("    HostName " + profile.hostname)
            lines.push("    User " + profile.user)
            lines.push("    IdentityFile " + key.path)
            lines.push("    IdentitiesOnly yes")

            if (profile.port !== 22)
                lines.push("    Port " + profile.port)
        }

        lines.push("")
        lines.push(root.endMarker)
        return lines.join("\n")
    }

    function syncConfig() {
        if (!configFile.loaded || backupProcess.running)
            return

        let base = root.manualConfigText().replace(/\s+$/, "")
        root.pendingConfigText = (base === "" ? "" : base + "\n\n")
            + root.renderManagedBlock() + "\n"

        backupProcess.exec([
            "cp",
            "--preserve=mode",
            root.configPath,
            root.configPath + ".minibar-backup"
        ])
    }

    function validateTunnel(config) {
        const profile = root.profileById(config.profileId)
        const localPort = Number(config.localPort)
        const remotePort = Number(config.remotePort)

        if (!profile || profile.type !== "vps")
            return "Selecciona un perfil VPS"

        if (root.cleanLine(config.name) === "")
            return "Escribe un nombre para el túnel"

        if (!localPort || localPort < 1 || localPort > 65535)
            return "El puerto local no es válido"

        if (!remotePort || remotePort < 1 || remotePort > 65535)
            return "El puerto remoto no es válido"

        if (root.cleanLine(config.remoteHost) === "")
            return "Escribe el host remoto"

        return ""
    }

    function saveTunnel(config) {
        const tunnel = {
            id: root.newId("tunnel"),
            name: root.cleanLine(config.name),
            profileId: config.profileId,
            localPort: Number(config.localPort),
            remoteHost: root.cleanLine(config.remoteHost),
            remotePort: Number(config.remotePort)
        }

        const error = root.validateTunnel(tunnel)

        if (error !== "") {
            root.message(error, true)
            return false
        }

        root.tunnels = root.tunnels.concat([tunnel])
        root.saveRegistry()
        return true
    }

    function removeTunnel(tunnel) {
        if (!tunnel)
            return

        root.tunnels = root.tunnels.filter(function(item) {
            return item.id !== tunnel.id
        })
        root.saveRegistry()
    }

    function portOccupied(port) {
        return root.occupiedPorts.indexOf(Number(port)) >= 0
    }

    function tunnelSocket(tunnel) {
        return root.runtimeDirectory + "/" + tunnel.id + ".sock"
    }

    function tunnelActive(tunnel) {
        return tunnel
            && root.activeTunnelIds.indexOf(tunnel.id) >= 0
    }

    function openVpsTerminal(profile) {
        if (!profile || profile.type !== "vps") {
            root.message("La terminal SSH solo está disponible para VPS", true)
            return
        }

        Quickshell.execDetached([
            "kitty",
            "--title", "SSH · " + (profile.label || profile.alias),
            "ssh",
            profile.alias
        ])
    }

    function startTunnel(tunnel) {
        const profile = tunnel ? root.profileById(tunnel.profileId) : null

        if (!profile || profile.type !== "vps") {
            root.message("El túnel necesita un perfil VPS", true)
            return
        }

        if (root.portOccupied(tunnel.localPort)) {
            root.message("El puerto local " + tunnel.localPort + " está ocupado", true)
            return
        }

        cleanupSocketProcess.pendingTunnel = tunnel
        cleanupSocketProcess.exec([
            "rm", "-f", root.tunnelSocket(tunnel)
        ])
    }

    function launchTunnel(tunnel) {
        const profile = root.profileById(tunnel.profileId)

        if (!profile)
            return

        startTunnelProcess.pendingTunnel = tunnel
        startTunnelProcess.exec([
            "ssh",
            "-f",
            "-M",
            "-S", root.tunnelSocket(tunnel),
            "-N",
            "-o", "BatchMode=yes",
            "-o", "ExitOnForwardFailure=yes",
            "-o", "ServerAliveInterval=30",
            "-L", tunnel.localPort + ":" + tunnel.remoteHost + ":" + tunnel.remotePort,
            profile.alias
        ])
    }

    function stopTunnel(tunnel) {
        const profile = tunnel ? root.profileById(tunnel.profileId) : null

        if (!profile || !root.tunnelActive(tunnel))
            return

        controlProcess.pendingTunnel = tunnel
        controlProcess.exec([
            "ssh",
            "-S", root.tunnelSocket(tunnel),
            "-O", "exit",
            profile.alias
        ])
    }

    FileView {
        id: registryFile
        path: root.registryPath
        blockLoading: true
        atomicWrites: true
        watchChanges: true
        printErrors: false
        onLoaded: root.loadRegistry()
        onFileChanged: reload()
        onSaveFailed: root.message("No se pudo guardar el registro SSH", true)
    }

    FileView {
        id: configFile
        path: root.configPath
        blockLoading: true
        atomicWrites: true
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onSaveFailed: root.message("No se pudo actualizar ~/.ssh/config", true)
    }

    Process {
        id: initializeProcess
        onExited: {
            registryFile.reload()
            configFile.reload()
            portProcess.exec(["ss", "-H", "-ltn"])
        }
    }

    Process {
        id: generationProcess
        property var pendingKey: null
        stderr: StdioCollector { id: generationError }

        onExited: function(exitCode, exitStatus) {
            root.operationRunning = false

            if (exitCode === 0 && pendingKey) {
                root.keys = root.keys.concat([pendingKey])
                root.saveRegistry()
                root.message("Llave creada: " + pendingKey.name, false)
            } else {
                root.message(
                    generationError.text.trim() || "No se pudo crear la llave",
                    true
                )
            }

            pendingKey = null
        }
    }

    Process {
        id: existingKeyProcess
        property var pendingKey: null

        onExited: function(exitCode, exitStatus) {
            root.operationRunning = false

            if (exitCode === 0 && pendingKey) {
                root.keys = root.keys.concat([pendingKey])
                root.saveRegistry()
                root.message("Llave existente agregada", false)
            } else {
                root.message("No se encontró la llave indicada", true)
            }

            pendingKey = null
        }
    }

    Process {
        id: copyProcess
        property string pendingName: ""

        onExited: function(exitCode, exitStatus) {
            root.message(
                exitCode === 0
                    ? "Llave pública copiada"
                    : "No se encontró el archivo .pub",
                exitCode !== 0
            )
            pendingName = ""
        }
    }

    Process {
        id: backupProcess

        onExited: function(exitCode, exitStatus) {
            if (exitCode !== 0) {
                root.message("No se pudo crear la copia de seguridad de config", true)
                return
            }

            configFile.setText(root.pendingConfigText)
            root.message("Configuración SSH actualizada", false)
        }
    }

    Process {
        id: portProcess

        stdout: StdioCollector {
            onStreamFinished: {
                const ports = []
                const lines = text.split("\n")

                for (let i = 0; i < lines.length; i++) {
                    const parts = lines[i].trim().split(/\s+/)

                    if (parts.length < 4)
                        continue

                    const match = parts[3].match(/:([0-9]+)$/)

                    if (match)
                        ports.push(Number(match[1]))
                }

                root.occupiedPorts = ports
            }
        }
    }

    Process {
        id: socketProcess

        stdout: StdioCollector {
            onStreamFinished: {
                root.activeTunnelIds = text.trim() === ""
                    ? []
                    : text.trim().split("\n")
            }
        }
    }

    Process {
        id: cleanupSocketProcess
        property var pendingTunnel: null

        onExited: {
            if (pendingTunnel)
                root.launchTunnel(pendingTunnel)
            pendingTunnel = null
        }
    }

    Process {
        id: startTunnelProcess
        property var pendingTunnel: null
        stderr: StdioCollector { id: startTunnelError }

        onExited: function(exitCode, exitStatus) {
            root.message(
                exitCode === 0 && pendingTunnel
                    ? "Túnel activo: " + pendingTunnel.name
                    : startTunnelError.text.trim()
                        || "No se pudo iniciar el túnel. Si la llave tiene frase, cárgala primero en ssh-agent",
                exitCode !== 0
            )
            pendingTunnel = null
            tunnelRefresh.restart()
        }
    }

    Process {
        id: controlProcess
        property var pendingTunnel: null
        stderr: StdioCollector { id: controlError }

        onExited: function(exitCode, exitStatus) {
            root.message(
                exitCode === 0
                    ? "Túnel detenido"
                    : controlError.text.trim() || "No se pudo detener el túnel",
                exitCode !== 0
            )
            pendingTunnel = null
            tunnelRefresh.restart()
        }
    }

    Timer {
        interval: 2500
        running: true
        repeat: true
        onTriggered: {
            if (!portProcess.running)
                portProcess.exec(["ss", "-H", "-ltn"])

            if (!socketProcess.running) {
                socketProcess.exec([
                    "sh", "-c",
                    "for socket in \"$1\"/tunnel-*.sock; do "
                        + "[ -S \"$socket\" ] || continue; "
                        + "name=${socket##*/}; printf '%s\\n' \"${name%.sock}\"; "
                        + "done",
                    "minibar-ssh-sockets",
                    root.runtimeDirectory
                ])
            }
        }
    }

    Timer {
        id: tunnelRefresh
        interval: 900
        repeat: false
        onTriggered: {
            if (!portProcess.running)
                portProcess.exec(["ss", "-H", "-ltn"])

            if (!socketProcess.running) {
                socketProcess.exec([
                    "sh", "-c",
                    "for socket in \"$1\"/tunnel-*.sock; do "
                        + "[ -S \"$socket\" ] || continue; "
                        + "name=${socket##*/}; printf '%s\\n' \"${name%.sock}\"; "
                        + "done",
                    "minibar-ssh-sockets",
                    root.runtimeDirectory
                ])
            }
        }
    }

    Component.onCompleted: {
        initializeProcess.exec([
            "sh", "-c",
            "mkdir -p \"$1\" \"$2\" \"$5\"; "
                + "chmod 700 \"$2\"; "
                + "chmod 700 \"$5\"; "
                + "[ -f \"$3\" ] || printf '{\"version\":1,\"keys\":[],\"profiles\":[],\"tunnels\":[]}\\n' > \"$3\"; "
                + "chmod 600 \"$3\"; "
                + "[ -f \"$4\" ] || : > \"$4\"; "
                + "chmod 600 \"$4\"",
            "minibar-ssh-init",
            root.dataDirectory,
            root.sshDirectory,
            root.registryPath,
            root.configPath,
            root.runtimeDirectory
        ])
    }
}
