import QtQuick

import Quickshell
import Quickshell.Io

Item {
    id: root

    property bool pollingEnabled: false
    property int cpuUsage: 0
    property int gpuUsage: 0
    property int ramUsage: 0
    property string cpuName: "Procesador"
    property string gpuName: "Gráfica"
    property var processGroups: []
    property int processCount: 0
    property var wallpapers: []
    property string selectedWallpaper: ""
    property string statusMessage: ""
    property bool statusError: false

    readonly property string basePath:
        String(Qt.resolvedUrl(".")).replace(/^file:\/\//, "")
    readonly property string wallpaperDirectory:
        Quickshell.env("HOME") + "/wallparpers"

    function refreshStats() {
        if (!statsProcess.running)
            statsProcess.exec(["bash", root.basePath + "system-stats.sh"])
    }

    function refreshProcesses() {
        if (!processProcess.running)
            processProcess.exec(["bash", root.basePath + "process-list.sh"])
    }

    function refreshWallpapers() {
        if (!wallpaperListProcess.running) {
            wallpaperListProcess.exec([
                "find",
                root.wallpaperDirectory,
                "-maxdepth", "1",
                "-type", "f",
                "(",
                "-iname", "*.jpg", "-o",
                "-iname", "*.jpeg", "-o",
                "-iname", "*.png", "-o",
                "-iname", "*.webp", "-o",
                "-iname", "*.jxl",
                ")"
            ])
        }
    }

    function applyWallpaper(path) {
        if (!path)
            return

        root.selectedWallpaper = path
        wallpaperState.setText(path + "\n")
        root.statusMessage = "Aplicando fondo…"
        root.statusError = false

        wallpaperProcess.exec([
            "hyprctl", "hyprpaper", "wallpaper",
            "," + path + ",cover"
        ])
    }

    function restoreWallpaper() {
        if (!root.selectedWallpaper || wallpaperProcess.running)
            return

        wallpaperProcess.exec([
            "hyprctl", "hyprpaper", "wallpaper",
            "," + root.selectedWallpaper + ",cover"
        ])
    }

    function terminateProcess(pid, name) {
        const numericPid = Number(pid)

        if (!Number.isInteger(numericPid) || numericPid <= 1)
            return

        if (name === "quickshell" || name === "qs" || name === "Hyprland") {
            root.statusMessage = "Proceso protegido: " + name
            root.statusError = true
            return
        }

        killProcess.exec(["kill", "-TERM", String(numericPid)])
    }

    function parseStats(text) {
        const parts = text.trim().split("\t")
        if (parts.length < 3)
            return

        root.cpuUsage = Number(parts[0]) || 0
        root.gpuUsage = Number(parts[1]) || 0
        root.ramUsage = Number(parts[2]) || 0
        root.cpuName = parts[3] || "Procesador"
        root.gpuName = parts[4] || "Gráfica"
    }

    function parseProcesses(text) {
        const groupsByKey = {}
        const lines = text.trim().split("\n")
        let totalProcesses = 0

        for (let i = 0; i < lines.length; i++) {
            const parts = lines[i].split("\t")
            if (parts.length < 10)
                continue

            const key = parts[0]
            if (!groupsByKey[key]) {
                groupsByKey[key] = {
                    key: key,
                    name: parts[1],
                    rootPid: Number(parts[2]),
                    cpu: 0,
                    memory: 0,
                    memoryBytes: 0,
                    count: 0,
                    processes: []
                }
            }

            const group = groupsByKey[key]
            const process = {
                pid: Number(parts[3]),
                ppid: Number(parts[4]),
                name: parts[5],
                cpu: Number(parts[6]) || 0,
                memory: Number(parts[7]) || 0,
                memoryBytes: (Number(parts[8]) || 0) * 1024,
                detail: parts[9]
            }

            group.cpu += process.cpu
            group.memory += process.memory
            group.memoryBytes += process.memoryBytes
            group.count++
            group.processes.push(process)
            totalProcesses++
        }

        const groups = Object.keys(groupsByKey).map(function(key) {
            const group = groupsByKey[key]
            group.processes.sort(function(a, b) {
                return b.memoryBytes - a.memoryBytes || b.cpu - a.cpu
            })
            return group
        })

        groups.sort(function(a, b) {
            return b.memoryBytes - a.memoryBytes || b.cpu - a.cpu
        })

        root.processCount = totalProcesses
        root.processGroups = groups
    }

    onPollingEnabledChanged: {
        if (root.pollingEnabled) {
            root.refreshStats()
            root.refreshProcesses()
            root.refreshWallpapers()
        }
    }

    Component.onCompleted: root.refreshWallpapers()

    FileView {
        id: wallpaperState
        path: Quickshell.env("HOME") + "/.local/state/minibar/wallpaper"
        watchChanges: true
        printErrors: false
        onLoaded: {
            root.selectedWallpaper = wallpaperState.text().trim()
            if (root.selectedWallpaper !== "")
                restoreTimer.restart()
        }
        onFileChanged: wallpaperState.reload()
    }

    Timer {
        id: restoreTimer
        interval: 900
        onTriggered: root.restoreWallpaper()
    }

    Timer {
        interval: 2200
        repeat: true
        running: root.pollingEnabled
        onTriggered: root.refreshStats()
    }

    Timer {
        interval: 4000
        repeat: true
        running: root.pollingEnabled
        onTriggered: root.refreshProcesses()
    }

    Process {
        id: statsProcess
        stdout: StdioCollector { onStreamFinished: root.parseStats(text) }
    }

    Process {
        id: processProcess
        stdout: StdioCollector { onStreamFinished: root.parseProcesses(text) }
    }

    Process {
        id: wallpaperListProcess
        stdout: StdioCollector {
            onStreamFinished: {
                root.wallpapers = text.trim() === ""
                    ? []
                    : text.trim().split("\n").sort()
            }
        }
    }

    Process {
        id: wallpaperProcess
        stdout: StdioCollector { id: wallpaperOutput }
        stderr: StdioCollector { id: wallpaperError }
        onExited: function(exitCode) {
            root.statusError = exitCode !== 0
            root.statusMessage = exitCode === 0
                ? "Fondo aplicado"
                : (wallpaperError.text.trim() || "No se pudo aplicar el fondo")
        }
    }

    Process {
        id: killProcess
        stderr: StdioCollector { id: killError }
        onExited: function(exitCode) {
            root.statusError = exitCode !== 0
            root.statusMessage = exitCode === 0
                ? "Proceso finalizado con SIGTERM"
                : (killError.text.trim() || "No se pudo cerrar el proceso")
            root.refreshProcesses()
        }
    }
}
