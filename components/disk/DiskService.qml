import QtQuick

import Quickshell
import Quickshell.Io

Item {
    id: root

    property int refreshInterval: 30
    property int warningThreshold: 80
    property int criticalThreshold: 95

    property bool loading: false
    property var partitions: []
    property int primaryUsagePercent: 0

    signal refreshed()
    signal errorOccurred(string message)

    function usageColor(percent) {
        if (percent >= root.criticalThreshold)
            return "#d66d68"

        if (percent >= root.warningThreshold)
            return "#d5a84f"

        return "#d5a84f"
    }

    function refresh() {
        if (dfProcess.running)
            return

        root.loading = true

        /*
         * -h: tamaños legibles
         * -T: muestra el sistema de archivos
         * -P: una partición por línea
         *
         * No usamos --output porque es incompatible con -P.
         */
        dfProcess.exec([
            "sh",
            "-c",
            "LC_ALL=C df -hT -P "
                + "-x tmpfs "
                + "-x devtmpfs "
                + "-x efivarfs "
                + "-x overlay "
                + "-x squashfs "
                + "-x fuse.portal "
                + "2>&1 | tail -n +2"
        ])
    }

    function mountPriority(mountPoint) {
        switch (mountPoint) {
        case "/":
            return 1
        case "/home":
            return 2
        case "/var":
            return 3
        case "/boot":
            return 4
        case "/boot/efi":
            return 5
        case "/opt":
            return 6
        case "/srv":
            return 7
        case "/mnt":
            return 8
        default:
            return 100
        }
    }

    function shouldInclude(entry) {
        if (!entry)
            return false

        const mountPoint = entry.mount || ""
        const filesystemType = entry.fstype || ""

        if (mountPoint.startsWith("/run/user/"))
            return false

        if (mountPoint.startsWith("/snap/"))
            return false

        if (mountPoint.startsWith("/var/lib/docker/"))
            return false

        if (mountPoint.startsWith("/var/lib/containers/"))
            return false

        if (
            filesystemType === "tmpfs"
            || filesystemType === "devtmpfs"
            || filesystemType === "overlay"
            || filesystemType === "squashfs"
            || filesystemType === "efivarfs"
        ) {
            return false
        }

        return true
    }

    function parseDf(output) {
        const result = []

        if (!output || output.trim() === "") {
            root.partitions = []
            root.primaryUsagePercent = 0
            root.errorOccurred(
                "El comando df no devolvió información"
            )
            return
        }

        const lines = output.trim().split("\n")

        for (let i = 0; i < lines.length; i++) {
            const line = lines[i].trim()

            if (line === "")
                continue

            /*
             * Evita interpretar mensajes de error como particiones.
             */
            if (
                line.startsWith("df:")
                || line.startsWith("Filesystem")
            ) {
                console.log("df:", line)
                continue
            }

            /*
             * Salida de:
             *
             * df -hT -P
             *
             * Filesystem Type Size Used Avail Use% Mounted-on
             */
            const parts = line.split(/\s+/)

            if (parts.length < 7) {
                console.log(
                    "Línea de df no reconocida:",
                    line
                )
                continue
            }

            const percentText = parts[5]

            if (!percentText.endsWith("%"))
                continue

            const entry = {
                key:
                    "disk-"
                    + i
                    + "-"
                    + parts[0]
                    + "-"
                    + parts.slice(6).join("_"),

                device: parts[0],
                fstype: parts[1],
                size: parts[2],
                used: parts[3],
                available: parts[4],

                percent:
                    parseInt(
                        percentText.replace("%", "")
                    ) || 0,

                mount: parts.slice(6).join(" ")
            }

            if (root.shouldInclude(entry))
                result.push(entry)
        }

        result.sort(function(a, b) {
            const difference =
                root.mountPriority(a.mount)
                - root.mountPriority(b.mount)

            if (difference !== 0)
                return difference

            return a.mount.localeCompare(b.mount)
        })

        root.partitions = result

        /*
         * El porcentaje principal corresponde a "/".
         * Si no aparece, usamos la primera partición.
         */
        let mainPartition = null

        for (let j = 0; j < result.length; j++) {
            if (result[j].mount === "/") {
                mainPartition = result[j]
                break
            }
        }

        if (mainPartition) {
            root.primaryUsagePercent =
                mainPartition.percent
        } else if (result.length > 0) {
            root.primaryUsagePercent =
                result[0].percent
        } else {
            root.primaryUsagePercent = 0
        }

        root.refreshed()
    }

    Process {
        id: dfProcess

        stdout: StdioCollector {
            onStreamFinished: {
                root.parseDf(text)
            }
        }

        onExited: function(exitCode, exitStatus) {
            root.loading = false

            if (exitCode !== 0) {
                root.errorOccurred(
                    "df terminó con código "
                    + exitCode
                )
            }
        }
    }

    Timer {
        interval:
            Math.max(
                5,
                root.refreshInterval
            ) * 1000

        running: true
        repeat: true

        onTriggered: root.refresh()
    }

    Component.onCompleted: {
        root.refresh()
    }
}
