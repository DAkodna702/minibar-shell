import QtQuick

import Quickshell
import Quickshell.Io

Item {
    id: root

    property string dockerBinary: "docker"
    property bool pollingEnabled: false

    property bool dockerAvailable: false
    property bool loading: false
    property bool actionRunning: false

    property var containers: []
    property int runningCount: 0

    property string statusMessage: ""
    property string errorMessage: ""

    signal refreshed()
    signal actionSucceeded(string message)
    signal actionFailed(string message)

    readonly property var runningContainers:
        containers.filter(function(container) {
            return container.isRunning
        })

    function refresh() {
        if (checkProcess.running || inspectProcess.running)
            return

        root.loading = true
        root.errorMessage = ""

        checkProcess.exec([
            root.dockerBinary,
            "info",
            "--format",
            "{{json .ServerVersion}}"
        ])
    }

    function fetchContainers() {
        if (inspectProcess.running)
            return

        inspectProcess.exec([
            "sh",
            "-c",
            `
ids="$("$1" container ls -aq 2>/dev/null)"

if [ -z "$ids" ]; then
    printf '[]'
    exit 0
fi

"$1" container inspect $ids
`,
            "docker-inspect",
            root.dockerBinary
        ])
    }

    function parseContainers(output) {
        if (!output || output.trim() === "") {
            root.containers = []
            root.runningCount = 0
            return
        }

        try {
            const parsed = JSON.parse(output)
            const result = []

            for (let i = 0; i < parsed.length; i++) {
                const item = parsed[i]

                if (!item)
                    continue

                const state = item.State || {}
                const config = item.Config || {}
                const networkSettings =
                    item.NetworkSettings || {}

                const portBindings =
                    networkSettings.Ports || {}

                const ports = []

                for (const containerPort in portBindings) {
                    const bindings =
                        portBindings[containerPort]

                    if (!bindings)
                        continue

                    for (
                        let bindingIndex = 0;
                        bindingIndex < bindings.length;
                        bindingIndex++
                    ) {
                        const binding = bindings[bindingIndex]

                        ports.push({
                            key:
                                containerPort
                                + "-"
                                + binding.HostPort
                                + "-"
                                + bindingIndex,

                            containerPort:
                                containerPort,

                            hostIp:
                                binding.HostIp
                                || "0.0.0.0",

                            hostPort:
                                binding.HostPort
                                || ""
                        })
                    }
                }

                const labels = config.Labels || {}

                const container = {
                    key: item.Id,
                    id: item.Id || "",
                    shortId:
                        item.Id
                            ? item.Id.substring(0, 12)
                            : "",

                    name:
                        item.Name
                            ? item.Name.replace(/^\//, "")
                            : "Sin nombre",

                    image:
                        config.Image
                        || item.Image
                        || "",

                    status:
                        state.Status || "unknown",

                    isRunning:
                        Boolean(state.Running),

                    isPaused:
                        Boolean(state.Paused),

                    isRestarting:
                        Boolean(state.Restarting),

                    exitCode:
                        Number(state.ExitCode || 0),

                    created:
                        item.Created || "",

                    startedAt:
                        state.StartedAt || "",

                    finishedAt:
                        state.FinishedAt || "",

                    restartCount:
                        Number(item.RestartCount || 0),

                    ports: ports,

                    composeProject:
                        labels[
                            "com.docker.compose.project"
                        ] || "",

                    composeService:
                        labels[
                            "com.docker.compose.service"
                        ] || ""
                }

                result.push(container)
            }

            result.sort(function(a, b) {
                function priority(container) {
                    if (container.isRunning)
                        return 0

                    if (container.isPaused)
                        return 1

                    if (container.isRestarting)
                        return 2

                    return 3
                }

                const difference =
                    priority(a) - priority(b)

                if (difference !== 0)
                    return difference

                return a.name.localeCompare(b.name)
            })

            root.containers = result

            root.runningCount =
                result.filter(function(container) {
                    return container.isRunning
                }).length

            root.refreshed()
        } catch (error) {
            console.log(
                "Error interpretando docker inspect:",
                error
            )

            root.containers = []
            root.runningCount = 0

            root.actionFailed(
                "No se pudo interpretar la respuesta de Docker"
            )
        }
    }

    function statusColor(container) {
        if (!container)
            return "#65675f"

        if (container.isPaused)
            return "#d5a84f"

        if (container.isRunning)
            return "#9eb39d"

        if (container.isRestarting)
            return "#d5a84f"

        return "#d66d68"
    }

    function statusLabel(container) {
        if (!container)
            return "Desconocido"

        if (container.isPaused)
            return "Pausado"

        if (container.isRestarting)
            return "Reiniciando"

        if (container.isRunning)
            return "Ejecutándose"

        if (container.status === "exited")
            return "Detenido"

        return container.status || "Desconocido"
    }

    function executeAction(container, action) {
        if (!container || !container.id)
            return

        if (actionProcess.running)
            return

        const commands = {
            start: [
                root.dockerBinary,
                "container",
                "start",
                container.id
            ],

            stop: [
                root.dockerBinary,
                "container",
                "stop",
                container.id
            ],

            restart: [
                root.dockerBinary,
                "container",
                "restart",
                container.id
            ],

            pause: [
                root.dockerBinary,
                "container",
                "pause",
                container.id
            ],

            unpause: [
                root.dockerBinary,
                "container",
                "unpause",
                container.id
            ],

            remove: [
                root.dockerBinary,
                "container",
                "rm",
                container.id
            ],

            forceRemove: [
                root.dockerBinary,
                "container",
                "rm",
                "--force",
                container.id
            ]
        }

        if (!commands[action])
            return

        root.actionRunning = true
        root.errorMessage = ""

        actionProcess.pendingAction = action
        actionProcess.pendingName = container.name

        actionProcess.exec(commands[action])
    }

    function runConsoleCommand(
        container,
        commandText
    ) {
        if (
            !container
            || !container.id
            || !container.isRunning
            || !commandText
            || commandText.trim() === ""
        ) {
            return
        }

        if (consoleProcess.running)
            consoleProcess.running = false

        consoleProcess.currentContainer =
            container

        consoleProcess.currentCommand =
            commandText

        consoleProcess.exec([
            root.dockerBinary,
            "container",
            "exec",
            container.id,
            "/bin/sh",
            "-lc",
            commandText
        ])
    }

    function startLogs(container) {
        if (!container || !container.id)
            return

        stopLogs()

        logsProcess.currentContainer = container

        logsProcess.exec([
            root.dockerBinary,
            "container",
            "logs",
            "--tail",
            "300",
            "--timestamps",
            "--follow",
            container.id
        ])
    }

    function stopLogs() {
        if (logsProcess.running)
            logsProcess.running = false

        logsProcess.currentContainer = null
    }

    property alias logsProcess: logsProcess
    property alias consoleProcess: consoleProcess

    Process {
        id: checkProcess

        stdout: StdioCollector {
            onStreamFinished: {
                root.dockerAvailable =
                    text.trim() !== ""
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim() !== "")
                    root.errorMessage = text.trim()
            }
        }

        onExited: function(exitCode, exitStatus) {
            if (exitCode === 0) {
                root.dockerAvailable = true
                root.fetchContainers()
            } else {
                root.dockerAvailable = false
                root.loading = false
                root.containers = []
                root.runningCount = 0

                root.actionFailed(
                    root.errorMessage !== ""
                        ? root.errorMessage
                        : "Docker no está disponible"
                )
            }
        }
    }

    Process {
        id: inspectProcess

        stdout: StdioCollector {
            onStreamFinished: {
                root.parseContainers(text)
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim() !== "")
                    root.errorMessage = text.trim()
            }
        }

        onExited: function(exitCode, exitStatus) {
            root.loading = false

            if (exitCode !== 0) {
                root.actionFailed(
                    root.errorMessage !== ""
                        ? root.errorMessage
                        : "No se pudieron obtener los contenedores"
                )
            }
        }
    }

    Process {
        id: actionProcess

        property string pendingAction: ""
        property string pendingName: ""

        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim() !== "")
                    root.statusMessage = text.trim()
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim() !== "")
                    root.errorMessage = text.trim()
            }
        }

        onExited: function(exitCode, exitStatus) {
            root.actionRunning = false

            if (exitCode === 0) {
                root.actionSucceeded(
                    "Acción completada en "
                    + actionProcess.pendingName
                )
            } else {
                root.actionFailed(
                    root.errorMessage !== ""
                        ? root.errorMessage
                        : "La acción de Docker falló"
                )
            }

            actionProcess.pendingAction = ""
            actionProcess.pendingName = ""

            delayedRefresh.restart()
        }
    }

    Process {
        id: logsProcess

        property var currentContainer: null

        stdout: SplitParser {
            onRead: function(data) {
                root.logsLineReceived(data)
            }
        }

        stderr: SplitParser {
            onRead: function(data) {
                root.logsLineReceived(data)
            }
        }
    }

    signal logsLineReceived(string line)

    Process {
        id: consoleProcess

        property var currentContainer: null
        property string currentCommand: ""

        property alias stdoutCollector:
            consoleStdout

        property alias stderrCollector:
            consoleStderr

        stdout: StdioCollector {
            id: consoleStdout
        }

        stderr: StdioCollector {
            id: consoleStderr
        }
    }

    Timer {
        id: delayedRefresh

        interval: 600
        repeat: false

        onTriggered: root.refresh()
    }

    Timer {
        interval: 5000
        running: root.pollingEnabled
        repeat: true

        onTriggered: {
            if (!root.loading && !root.actionRunning)
                root.refresh()
        }
    }

    Component.onCompleted: {
        root.refresh()
    }

    onPollingEnabledChanged: {
        if (root.pollingEnabled)
            root.refresh()
    }
}
