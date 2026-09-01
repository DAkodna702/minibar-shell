import QtQuick

import Quickshell
import Quickshell.Io

Item {
    id: root

    property bool installed: false
    property bool daemonRunning: false
    property bool online: false
    property bool busy: false
    property string backendState: "Unknown"
    property string hostname: ""
    property string ipAddress: ""
    property string tailnet: ""
    property int peerCount: 0
    property int onlinePeerCount: 0
    property string statusMessage: ""
    property bool statusError: false

    readonly property string basePath:
        String(Qt.resolvedUrl(".")).replace(/^file:\/\//, "")
    readonly property string scriptPath:
        root.basePath + "/tailscale-control.sh"
    readonly property bool connected:
        root.backendState === "Running"
    readonly property string summary: {
        if (!root.installed)
            return "No instalado"
        if (!root.daemonRunning)
            return "Servicio detenido"
        if (root.busy)
            return "Cambiando…"
        if (root.backendState === "NeedsLogin")
            return "Requiere acceso"
        if (root.backendState === "Running" && !root.online)
            return "Conectando…"
        if (!root.connected)
            return "Desconectado"
        return root.ipAddress !== "" ? root.ipAddress : "Conectado"
    }

    function refresh() {
        if (!statusProcess.running)
            statusProcess.exec(["bash", root.scriptPath, "status"])
    }

    function parseStatus(text) {
        const parts = String(text || "").trim().split("\t")
        if (parts.length < 9)
            return

        root.installed = parts[0] === "1"
        root.daemonRunning = parts[1] === "1"
        root.backendState = parts[2] || "Unknown"
        root.online = parts[3] === "1"
        root.hostname = parts[4] || ""
        root.ipAddress = parts[5] || ""
        root.tailnet = parts[6] || ""
        root.peerCount = Number(parts[7]) || 0
        root.onlinePeerCount = Number(parts[8]) || 0
    }

    function openSetup(action) {
        Quickshell.execDetached([
            "kitty",
            "--title", "Configurar Tailscale",
            "--hold",
            "bash", root.scriptPath, action
        ])
    }

    function toggle() {
        if (root.busy)
            return

        if (!root.installed) {
            root.openSetup("install")
            root.statusMessage = "Completa la instalación en la terminal"
            root.statusError = false
            messageTimer.restart()
            return
        }

        if (!root.daemonRunning) {
            root.openSetup("repair")
            root.statusMessage = "Completa la activación en la terminal"
            root.statusError = false
            messageTimer.restart()
            return
        }

        root.busy = true
        root.statusError = false
        root.statusMessage = root.connected
            ? "Desconectando Tailscale…"
            : "Conectando Tailscale…"
        actionProcess.targetConnected = !root.connected
        actionProcess.exec(["bash", root.scriptPath, "toggle"])
    }

    Component.onCompleted: root.refresh()

    Timer {
        interval: root.busy || (root.connected && !root.online)
            ? 1000
            : root.connected
                ? 5000
                : 3000
        repeat: true
        running: true
        onTriggered: root.refresh()
    }

    Timer {
        id: postActionRefresh
        interval: 300
        onTriggered: root.refresh()
    }

    Timer {
        id: messageTimer
        interval: 5000
        onTriggered: root.statusMessage = ""
    }

    Process {
        id: statusProcess
        stdout: StdioCollector {
            onStreamFinished: root.parseStatus(text)
        }
    }

    Process {
        id: actionProcess
        property bool targetConnected: false
        stdout: StdioCollector { id: actionOutput }
        stderr: StdioCollector { id: actionError }

        onExited: function(exitCode) {
            root.busy = false
            const output = (
                actionOutput.text + "\n" + actionError.text
            ).trim()
            const urlMatch = output.match(/https:\/\/login\.tailscale\.com\/[^\s]+/)

            if (urlMatch) {
                Quickshell.execDetached(["xdg-open", urlMatch[0]])
                root.statusMessage = "Completa el acceso en el navegador"
                root.statusError = false
            } else if (exitCode === 0) {
                root.backendState = actionProcess.targetConnected
                    ? "Running"
                    : "Stopped"
                if (!actionProcess.targetConnected)
                    root.online = false
                root.statusMessage = actionProcess.targetConnected
                    ? "Tailscale conectado"
                    : "Tailscale desconectado"
                root.statusError = false
            } else {
                root.statusMessage = output !== ""
                    ? output.split("\n").slice(-1)[0]
                    : "No se pudo cambiar Tailscale"
                root.statusError = true
            }

            messageTimer.restart()
            postActionRefresh.restart()
        }
    }

    IpcHandler {
        target: "minibarTailscale"
        function toggle(): void { root.toggle() }
        function refresh(): void { root.refresh() }
        function setup(): void { root.openSetup(root.installed ? "repair" : "install") }
    }
}
