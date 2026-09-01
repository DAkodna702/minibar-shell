import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property string dockerBinary: "docker"

    property bool loading: false
    property bool actionRunning: false

    property var volumes: []
    property var networks: []
    property var images: []

    signal refreshed()
    signal actionSucceeded(string message)
    signal actionFailed(string message)

    // =========================================================
    // REFRESH GENERAL
    // =========================================================

    function refresh() {
        if (refreshProcess.running)
            return

        root.loading = true

        refreshProcess.exec([
            "sh",
            "-c",

            "$1 volume ls --format '{{json .}}'; " +
            "printf '\\n__MINIBAR_NETWORKS__\\n'; " +

            "$1 network ls --format '{{json .}}'; " +
            "printf '\\n__MINIBAR_IMAGES__\\n'; " +

            "$1 image ls --format '{{json .}}'",

            "minibar-docker-infra",
            root.dockerBinary
        ])
    }

    function parseJsonLines(text) {
        const result = []

        const lines =
            String(text || "").split("\n")

        for (let i = 0; i < lines.length; i++) {
            const line = lines[i].trim()

            if (line === "")
                continue

            try {
                result.push(
                    JSON.parse(line)
                )
            } catch (error) {
                console.log(
                    "DockerInfraService JSON error:",
                    error,
                    line
                )
            }
        }

        return result
    }

    function parseOutput(text) {
        const networkSplit =
            String(text || "")
                .split("__MINIBAR_NETWORKS__")

        const volumeText =
            networkSplit.length > 0
                ? networkSplit[0]
                : ""

        const remaining =
            networkSplit.length > 1
                ? networkSplit[1]
                : ""

        const imageSplit =
            remaining.split(
                "__MINIBAR_IMAGES__"
            )

        const networkText =
            imageSplit.length > 0
                ? imageSplit[0]
                : ""

        const imageText =
            imageSplit.length > 1
                ? imageSplit[1]
                : ""

        root.volumes =
            root.parseJsonLines(volumeText)

        root.networks =
            root.parseJsonLines(networkText)

        root.images =
            root.parseJsonLines(imageText)

        root.refreshed()
    }

    // =========================================================
    // VALIDACIÓN
    // =========================================================

    function validName(name) {
        return /^[a-zA-Z0-9][a-zA-Z0-9_.-]*$/
            .test(String(name || ""))
    }

    // =========================================================
    // VOLUMES
    // =========================================================

    function createVolume(name) {
        name =
            String(name || "").trim()

        if (!root.validName(name)) {
            root.actionFailed(
                "Nombre de volumen inválido"
            )

            return
        }

        root.runAction(
            [
                root.dockerBinary,
                "volume",
                "create",
                name
            ],
            "Volumen creado: " + name
        )
    }

    function removeVolume(name) {
        if (!name)
            return

        root.runAction(
            [
                root.dockerBinary,
                "volume",
                "rm",
                name
            ],
            "Volumen eliminado: " + name
        )
    }

    // =========================================================
    // NETWORKS
    // =========================================================

    function createNetwork(name, driver) {
        name =
            String(name || "").trim()

        if (!root.validName(name)) {
            root.actionFailed(
                "Nombre de red inválido"
            )

            return
        }

        if (!driver || driver === "")
            driver = "bridge"

        root.runAction(
            [
                root.dockerBinary,
                "network",
                "create",
                "--driver",
                driver,
                name
            ],
            "Red creada: " + name
        )
    }

    function removeNetwork(id, name) {
        if (!id)
            return

        if (
            name === "bridge"
            || name === "host"
            || name === "none"
        ) {
            root.actionFailed(
                "No puedes eliminar la red "
                + "predeterminada " + name
            )

            return
        }

        root.runAction(
            [
                root.dockerBinary,
                "network",
                "rm",
                id
            ],
            "Red eliminada: " + name
        )
    }

    // =========================================================
    // IMAGES
    // =========================================================

    function pullImage(image) {
        image =
            String(image || "").trim()

        if (image === "") {
            root.actionFailed(
                "Escribe una imagen. "
                + "Ejemplo: postgres:17"
            )

            return
        }

        root.runAction(
            [
                root.dockerBinary,
                "pull",
                image
            ],
            "Imagen descargada: " + image
        )
    }

    function removeImage(id) {
        if (!id)
            return

        root.runAction(
            [
                root.dockerBinary,
                "image",
                "rm",
                id
            ],
            "Imagen eliminada"
        )
    }

    function pruneImages() {
        root.runAction(
            [
                root.dockerBinary,
                "image",
                "prune",
                "-f"
            ],
            "Imágenes sin uso eliminadas"
        )
    }

    // =========================================================
    // EJECUTOR
    // =========================================================

    function runAction(command, message) {
        if (actionProcess.running) {
            root.actionFailed(
                "Ya hay una operación Docker "
                + "ejecutándose"
            )

            return
        }

        actionProcess.successMessage =
            message

        root.actionRunning = true

        actionProcess.exec(command)
    }

    // =========================================================
    // PROCESO REFRESH
    // =========================================================

    Process {
        id: refreshProcess

        stdout: StdioCollector {
            id: refreshOutput
        }

        stderr: StdioCollector {
            id: refreshError
        }

        onExited:
            function(exitCode, exitStatus) {
                root.loading = false

                if (exitCode === 0) {
                    root.parseOutput(
                        refreshOutput.text
                    )

                    return
                }

                root.actionFailed(
                    refreshError.text.trim()
                    !== ""
                        ? refreshError.text.trim()
                        : "No se pudo consultar Docker"
                )
            }
    }

    // =========================================================
    // PROCESO ACTION
    // =========================================================

    Process {
        id: actionProcess

        property string successMessage: ""

        stdout: StdioCollector {
            id: actionOutput
        }

        stderr: StdioCollector {
            id: actionError
        }

        onExited:
            function(exitCode, exitStatus) {
                root.actionRunning = false

                if (exitCode === 0) {
                    root.actionSucceeded(
                        successMessage
                    )

                    refreshDelay.restart()

                    return
                }

                root.actionFailed(
                    actionError.text.trim()
                    !== ""
                        ? actionError.text.trim()
                        : "La operación Docker falló"
                )
            }
    }

    Timer {
        id: refreshDelay

        interval: 500
        repeat: false

        onTriggered:
            root.refresh()
    }

    Component.onCompleted:
        root.refresh()
}
