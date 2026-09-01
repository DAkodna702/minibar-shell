import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property string dockerBinary: "docker"
    property bool pollingEnabled: false
    property bool loading: false
    property bool creating: false
    property var databases: []
    property string errorMessage: ""

    signal refreshed()
    signal creationSucceeded(string name)
    signal creationFailed(string message)
    signal passwordLoaded(string containerId, string password)
    signal copySucceeded(string label)

    function engineDefaults(engine) {
        switch (engine) {
        case "postgres":
            return {
                image: "postgres:17",
                internalPort: 5432,
                hostPort: 5432,
                user: "postgres",
                database: "appdb",
                volumeTarget: "/var/lib/postgresql/data"
            }
        case "mysql":
            return {
                image: "mysql:8.4",
                internalPort: 3306,
                hostPort: 3306,
                user: "appuser",
                database: "appdb",
                volumeTarget: "/var/lib/mysql"
            }
        case "mongo":
            return {
                image: "mongo:8",
                internalPort: 27017,
                hostPort: 27017,
                user: "admin",
                database: "admin",
                volumeTarget: "/data/db"
            }
        case "redis":
            return {
                image: "redis:8-alpine",
                internalPort: 6379,
                hostPort: 6379,
                user: "default",
                database: "0",
                volumeTarget: "/data"
            }
        case "mssql":
            return {
                image: "mcr.microsoft.com/mssql/server:2022-latest",
                internalPort: 1433,
                hostPort: 1433,
                user: "sa",
                database: "master",
                volumeTarget: "/var/opt/mssql"
            }
        case "oracle":
            return {
                image: "gvenzl/oracle-free:23-slim-faststart",
                internalPort: 1521,
                hostPort: 1521,
                user: "system",
                database: "FREEPDB1",
                volumeTarget: "/opt/oracle/oradata"
            }
        default:
            return {
                image: "",
                internalPort: 0,
                hostPort: 0,
                user: "",
                database: "",
                volumeTarget: ""
            }
        }
    }

    function refresh() {
        if (listProcess.running)
            return

        root.loading = true
        root.errorMessage = ""

        listProcess.exec([
            "sh",
            "-c",
            "ids=\"$($1 ps -aq --filter label=minibar.kind=database 2>/dev/null)\"; " +
            "if [ -z \"$ids\" ]; then printf '[]'; else $1 inspect $ids; fi",
            "minibar-db-list",
            root.dockerBinary
        ])
    }

    function parseDatabases(output) {
        try {
            const raw = output && output.trim() !== ""
                ? JSON.parse(output)
                : []

            const result = []

            for (let i = 0; i < raw.length; i++) {
                const item = raw[i]
                const labels = item.Config && item.Config.Labels
                    ? item.Config.Labels
                    : {}
                const state = item.State || {}
                const ports = item.NetworkSettings && item.NetworkSettings.Ports
                    ? item.NetworkSettings.Ports
                    : {}

                const internalPort = Number(
                    labels["minibar.database.internalPort"] || 0
                )

                let hostPort = labels["minibar.database.port"] || ""

                if (hostPort === "" && internalPort > 0) {
                    const bindings = ports[String(internalPort) + "/tcp"]
                    if (bindings && bindings.length > 0)
                        hostPort = bindings[0].HostPort || ""
                }

                result.push({
                    key: item.Id,
                    id: item.Id || "",
                    shortId: item.Id ? item.Id.substring(0, 12) : "",
                    name: item.Name ? item.Name.replace(/^\//, "") : "",
                    engine: labels["minibar.database.engine"] || "unknown",
                    user: labels["minibar.database.user"] || "",
                    database: labels["minibar.database.name"] || "",
                    host: labels["minibar.database.host"] || "127.0.0.1",
                    port: hostPort,
                    internalPort: internalPort,
                    volume: labels["minibar.database.volume"] || "",
                    image: item.Config ? item.Config.Image || "" : "",
                    status: state.Status || "unknown",
                    isRunning: Boolean(state.Running),
                    isPaused: Boolean(state.Paused),
                    created: item.Created || ""
                })
            }

            result.sort(function(a, b) {
                if (a.isRunning !== b.isRunning)
                    return a.isRunning ? -1 : 1
                return a.name.localeCompare(b.name)
            })

            root.databases = result
            root.refreshed()
        } catch (error) {
            root.databases = []
            root.creationFailed(
                "No se pudo interpretar la lista de bases: " + error
            )
        }
    }

    function validateName(value) {
        return /^[a-zA-Z0-9][a-zA-Z0-9_.-]*$/.test(String(value || ""))
    }

    function createDatabase(config) {
        if (root.creating)
            return

        if (!config || !config.engine) {
            root.creationFailed("Selecciona un motor de base de datos")
            return
        }

        if (!root.validateName(config.containerName)) {
            root.creationFailed(
                "El nombre del contenedor solo puede usar letras, números, punto, guion y guion bajo"
            )
            return
        }

        const hostPort = Number(config.hostPort)
        if (!hostPort || hostPort < 1 || hostPort > 65535) {
            root.creationFailed("El puerto debe estar entre 1 y 65535")
            return
        }

        if (!config.password || config.password.length < 1) {
            root.creationFailed("Escribe una contraseña")
            return
        }

        if (config.engine === "mssql" && config.password.length < 8) {
            root.creationFailed(
                "SQL Server exige una contraseña de al menos 8 caracteres y suficientemente compleja"
            )
            return
        }

        const defaults = root.engineDefaults(config.engine)
        const image = config.image && config.image.trim() !== ""
            ? config.image.trim()
            : defaults.image
        const volumeName = config.volumeName && config.volumeName.trim() !== ""
            ? config.volumeName.trim()
            : config.containerName + "-data"
        const user = config.user || defaults.user
        const database = config.database || defaults.database
        const internalPort = defaults.internalPort

        const args = [
            root.dockerBinary,
            "run",
            "-d",
            "--name", config.containerName,
            "--restart", "unless-stopped",
            "--label", "minibar.managed=true",
            "--label", "minibar.kind=database",
            "--label", "minibar.database.engine=" + config.engine,
            "--label", "minibar.database.user=" + user,
            "--label", "minibar.database.name=" + database,
            "--label", "minibar.database.host=127.0.0.1",
            "--label", "minibar.database.port=" + hostPort,
            "--label", "minibar.database.internalPort=" + internalPort,
            "--label", "minibar.database.volume=" + volumeName,
            "-p", hostPort + ":" + internalPort,
            "-v", volumeName + ":" + defaults.volumeTarget
        ]

        if (config.network && config.network.trim() !== "")
            args.push("--network", config.network.trim())

        switch (config.engine) {
        case "postgres":
            args.push(
                "-e", "POSTGRES_USER=" + user,
                "-e", "POSTGRES_PASSWORD=" + config.password,
                "-e", "POSTGRES_DB=" + database
            )
            break

        case "mysql":
            args.push(
                "-e", "MYSQL_ROOT_PASSWORD=" + config.password,
                "-e", "MYSQL_DATABASE=" + database,
                "-e", "MYSQL_USER=" + user,
                "-e", "MYSQL_PASSWORD=" + config.password
            )
            break

        case "mongo":
            args.push(
                "-e", "MONGO_INITDB_ROOT_USERNAME=" + user,
                "-e", "MONGO_INITDB_ROOT_PASSWORD=" + config.password,
                "-e", "MONGO_INITDB_DATABASE=" + database
            )
            break

        case "mssql":
            args.push(
                "-e", "ACCEPT_EULA=Y",
                "-e", "MSSQL_SA_PASSWORD=" + config.password,
                "-e", "MSSQL_PID=Developer"
            )
            break

        case "oracle":
            args.push(
                "-e", "ORACLE_PASSWORD=" + config.password,
                "-e", "APP_USER=" + user,
                "-e", "APP_USER_PASSWORD=" + config.password
            )
            break
        }

        args.push(image)

        if (config.engine === "redis") {
            args.push(
                "redis-server",
                "--appendonly", "yes",
                "--requirepass", config.password
            )
        }

        root.creating = true
        createProcess.pendingName = config.containerName
        createProcess.pendingPassword = config.password
        createProcess.exec(args)
    }

    function performAction(database, action) {
        if (!database || !database.id || actionProcess.running)
            return

        const commands = {
            start: [root.dockerBinary, "start", database.id],
            stop: [root.dockerBinary, "stop", database.id],
            restart: [root.dockerBinary, "restart", database.id],
            remove: [root.dockerBinary, "rm", "-f", database.id]
        }

        if (!commands[action])
            return

        actionProcess.pendingAction = action
        actionProcess.pendingId = database.id
        actionProcess.exec(commands[action])
    }

    function requestPassword(database) {
        if (
            !database
            || !database.id
            || passwordLookupProcess.running
        ) {
            return
        }

        passwordLookupProcess.pendingId = database.id
        passwordLookupProcess.exec([
            "secret-tool",
            "lookup",
            "service", "minibar-docker-database",
            "container-id", database.id
        ])
    }

    function copyText(text, label) {
        if (copyProcess.running)
            return

        copyProcess.pendingLabel = label || "Dato"
        copyProcess.exec([
            "sh",
            "-c",
            "printf '%s' \"$1\" | wl-copy",
            "minibar-copy",
            String(text || "")
        ])
    }

    Process {
        id: listProcess

        stdout: StdioCollector {
            onStreamFinished: root.parseDatabases(text)
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim() !== "")
                    root.errorMessage = text.trim()
            }
        }

        onExited: function(exitCode, exitStatus) {
            root.loading = false
            if (exitCode !== 0)
                root.creationFailed(
                    root.errorMessage !== ""
                        ? root.errorMessage
                        : "No se pudo listar las bases de datos"
                )
        }
    }

    Process {
        id: createProcess

        property string pendingName: ""
        property string pendingPassword: ""

        stdout: StdioCollector {
            id: createStdout
        }

        stderr: StdioCollector {
            id: createStderr
        }

        onExited: function(exitCode, exitStatus) {
            root.creating = false

            if (exitCode !== 0) {
                root.creationFailed(
                    createStderr.text.trim() !== ""
                        ? createStderr.text.trim()
                        : "No se pudo crear la base de datos"
                )
                pendingName = ""
                pendingPassword = ""
                return
            }

            const containerId = createStdout.text.trim()

            if (containerId !== "" && pendingPassword !== "") {
                storeSecretProcess.pendingContainerId = containerId
                storeSecretProcess.pendingName = pendingName
                storeSecretProcess.exec([
                    "sh",
                    "-c",
                    "printf '%s' \"$1\" | secret-tool store " +
                    "--label=\"$2\" service minibar-docker-database container-id \"$3\"",
                    "minibar-store-secret",
                    pendingPassword,
                    "Minibar Docker DB: " + pendingName,
                    containerId
                ])
            } else {
                root.creationSucceeded(pendingName)
                delayedRefresh.restart()
            }

            pendingName = ""
            pendingPassword = ""
        }
    }

    Process {
        id: storeSecretProcess

        property string pendingContainerId: ""
        property string pendingName: ""

        onExited: function(exitCode, exitStatus) {
            root.creationSucceeded(pendingName)
            pendingContainerId = ""
            pendingName = ""
            delayedRefresh.restart()
        }
    }

    Process {
        id: actionProcess

        property string pendingAction: ""
        property string pendingId: ""

        stderr: StdioCollector {
            id: actionStderr
        }

        onExited: function(exitCode, exitStatus) {
            if (exitCode !== 0) {
                root.creationFailed(
                    actionStderr.text.trim() !== ""
                        ? actionStderr.text.trim()
                        : "La acción de Docker falló"
                )
            } else if (pendingAction === "remove") {
                secretClearProcess.exec([
                    "secret-tool",
                    "clear",
                    "service", "minibar-docker-database",
                    "container-id", pendingId
                ])
            }

            pendingAction = ""
            pendingId = ""
            delayedRefresh.restart()
        }
    }

    Process {
        id: passwordLookupProcess

        property string pendingId: ""

        stdout: StdioCollector {
            id: passwordStdout
        }

        onExited: function(exitCode, exitStatus) {
            root.passwordLoaded(
                pendingId,
                exitCode === 0 ? passwordStdout.text.trim() : ""
            )
            pendingId = ""
        }
    }

    Process {
        id: secretClearProcess
    }

    Process {
        id: copyProcess

        property string pendingLabel: "Dato"

        onExited: function(exitCode, exitStatus) {
            if (exitCode === 0)
                root.copySucceeded(pendingLabel)
        }
    }

    Timer {
        id: delayedRefresh
        interval: 700
        repeat: false
        onTriggered: root.refresh()
    }

    Timer {
        interval: 5000
        running: root.pollingEnabled
        repeat: true
        onTriggered: {
            if (!root.loading && !root.creating)
                root.refresh()
        }
    }

    Component.onCompleted: root.refresh()

    onPollingEnabledChanged: {
        if (root.pollingEnabled)
            root.refresh()
    }
}
