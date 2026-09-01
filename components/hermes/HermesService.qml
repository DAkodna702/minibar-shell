import QtQuick

import Quickshell
import Quickshell.Io

Item {
    id: root

    property bool active: false
    property bool busy: false
    property string statusMessage: ""
    property bool statusError: false

    readonly property string basePath:
        String(Qt.resolvedUrl(".")).replace(/^file:\/\//, "")
    readonly property string scriptPath: root.basePath + "/hermes-control.sh"
    readonly property string summary: root.busy
        ? "Cambiando…"
        : root.active
            ? "Agent activo"
            : "Agent apagado"

    function refresh() {
        if (!statusProcess.running)
            statusProcess.exec(["bash", root.scriptPath, "status"])
    }

    function start() {
        if (root.busy)
            return
        root.busy = true
        root.statusError = false
        root.statusMessage = "Iniciando Hermes Agent…"
        actionProcess.exec(["bash", root.scriptPath, "start"])
    }

    function stop() {
        if (root.busy)
            return
        root.busy = true
        root.statusError = false
        root.statusMessage = "Deteniendo Hermes Agent…"
        actionProcess.exec(["bash", root.scriptPath, "stop"])
    }

    function toggle() {
        root.active ? root.stop() : root.start()
    }

    Component.onCompleted: root.refresh()

    Timer {
        interval: 3000
        repeat: true
        running: root.active
        onTriggered: root.refresh()
    }

    Timer {
        id: messageTimer
        interval: 3500
        onTriggered: root.statusMessage = ""
    }

    Process {
        id: statusProcess
        stdout: StdioCollector {
            onStreamFinished: root.active = text.trim() === "running"
        }
    }

    Process {
        id: actionProcess
        stdout: StdioCollector { id: actionOutput }
        stderr: StdioCollector { id: actionError }
        onExited: function(exitCode) {
            root.busy = false
            root.statusError = exitCode !== 0
            if (exitCode === 0) {
                root.active = actionOutput.text.trim() === "running"
                root.statusMessage = root.active
                    ? "Hermes Agent iniciado"
                    : "Hermes Agent detenido"
            } else {
                const detail = actionError.text.trim()
                root.statusMessage = detail || "No se pudo cambiar el estado de Hermes"
            }
            messageTimer.restart()
            root.refresh()
        }
    }

    IpcHandler {
        target: "hermesAgent"
        function start(): void { root.start() }
        function stop(): void { root.stop() }
        function toggle(): void { root.toggle() }
        function refresh(): void { root.refresh() }
    }
}
