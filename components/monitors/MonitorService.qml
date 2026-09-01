import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property var monitors: []
    property var brightness: ({})
    property var brightnessService: null
    property bool identifying: false
    property bool pendingConfirmation: false
    property int secondsRemaining: 0
    property string statusMessage: ""
    property bool statusError: false
    property bool loading: false
    property bool pollingEnabled: true
    property string topologySignature: ""

    readonly property string basePath: String(Qt.resolvedUrl(".")).replace(/^file:\/\//, "")
    readonly property int count: monitors.length

    signal changed()
    signal topologyChanged()

    function cleanMode(mode) {
        return String(mode || "").replace("Hz", "")
    }

    function modesForResolution(monitor, resolution) {
        const candidates = []
        for (let i = 0; i < monitor.availableModes.length; i++) {
            const mode = root.cleanMode(monitor.availableModes[i])
            if (mode.startsWith(resolution + "@"))
                candidates.push(mode)
        }
        candidates.sort(function(a, b) {
            return Number(b.split("@")[1]) - Number(a.split("@")[1])
        })
        const seen = {}
        const result = []
        for (let j = 0; j < candidates.length; j++) {
            const roundedRate = String(Math.round(Number(candidates[j].split("@")[1])))
            if (seen[roundedRate])
                continue
            seen[roundedRate] = true
            result.push(candidates[j])
        }
        return result
    }

    function resolutionsFor(monitor) {
        if (!monitor || !monitor.availableModes)
            return []

        const seen = {}
        const result = []
        for (let i = 0; i < monitor.availableModes.length; i++) {
            const resolution = root.cleanMode(
                monitor.availableModes[i]
            ).split("@")[0]
            if (!resolution || seen[resolution])
                continue
            seen[resolution] = true
            result.push(resolution)
        }

        result.sort(function(a, b) {
            const aParts = a.split("x")
            const bParts = b.split("x")
            const aPixels = Number(aParts[0]) * Number(aParts[1])
            const bPixels = Number(bParts[0]) * Number(bParts[1])
            return bPixels - aPixels || Number(bParts[0]) - Number(aParts[0])
        })
        return result
    }

    function nativeResolution(monitor) {
        if (!monitor || !monitor.availableModes || monitor.availableModes.length === 0)
            return root.rawResolution(monitor)
        return root.cleanMode(monitor.availableModes[0]).split("@")[0]
    }

    function rawResolution(monitor) {
        // hyprctl reports width/height as the configured mode's raw resolution;
        // it is not swapped for the active transform/rotation.
        return monitor.width + "x" + monitor.height
    }

    function modesForSelection(monitor) {
        if (!monitor)
            return []
        return root.modesForResolution(
            monitor,
            monitor.selectedResolution || root.rawResolution(monitor)
        )
    }

    function friendlyName(monitor) {
        if (!monitor)
            return "Pantalla"
        if (String(monitor.name).startsWith("eDP"))
            return "Laptop · " + (monitor.make || monitor.model || monitor.name)
        if (String(monitor.model).indexOf("TE-3410G") >= 0)
            return "Ultrawide · TES TE-3410G"
        if (String(monitor.model).indexOf("W2409SH") >= 0)
            return "KTC W2409SH"
        return (monitor.make + " " + monitor.model).trim() || monitor.name
    }

    function parseMonitors(text) {
        let data = []
        try { data = JSON.parse(text) } catch (error) {
            root.statusMessage = "No se pudieron leer las pantallas"
            root.statusError = true
            return
        }
        data.sort(function(a, b) { return a.x - b.x })
        const topology = data.map(function(monitor) { return monitor.name }).sort().join("|")
        if (topology !== root.topologySignature) {
            root.topologySignature = topology
            root.topologyChanged()
            hotplugProcess.exec(["bash", root.basePath + "/monitor-hotplug.sh"])
        }
        const result = []
        const newBrightness = Object.assign({}, root.brightness)
        for (let i = 0; i < data.length; i++) {
            const source = data[i]
            const rotation = Number(source.transform) || 0
            const item = {
                name: source.name,
                description: source.description,
                make: source.make || "",
                model: source.model || "",
                width: source.width,
                height: source.height,
                refreshRate: Number(source.refreshRate),
                scale: Number(source.scale) || 1,
                x: source.x,
                y: source.y,
                availableModes: source.availableModes || [],
                rotation: rotation,
                selectedRotation: rotation,
                selectedScale: Number(source.scale) || 1,
                selectedResolution: source.width + "x" + source.height,
                internal: String(source.name).startsWith("eDP") || String(source.name).startsWith("LVDS")
            }
            const current = root.rawResolution(item) + "@" + Number(source.refreshRate).toFixed(2)
            item.selectedMode = current
            const modes = root.modesForSelection(item)
            if (modes.indexOf(current) < 0 && modes.length > 0) {
                let nearest = modes[0]
                let distance = 9999
                for (let j = 0; j < modes.length; j++) {
                    const delta = Math.abs(Number(modes[j].split("@")[1]) - item.refreshRate)
                    if (delta < distance) { distance = delta; nearest = modes[j] }
                }
                item.selectedMode = nearest
            }
            if (item.internal && root.brightnessService && root.brightnessService.available)
                newBrightness[item.name] = root.brightnessService.primaryBrightness
            else if (newBrightness[item.name] === undefined)
                newBrightness[item.name] = 100
            result.push(item)
        }
        root.brightness = newBrightness
        root.monitors = result
        root.loading = false
        root.changed()
    }

    function refresh() {
        if (readProcess.running)
            return
        root.loading = true
        readProcess.exec(["hyprctl", "monitors", "-j"])
    }

    function move(index, delta) {
        const target = index + delta
        if (index < 0 || target < 0 || index >= monitors.length || target >= monitors.length)
            return
        const result = monitors.slice()
        const value = result[index]
        result[index] = result[target]
        result[target] = value
        root.monitors = result
    }

    function chooseMode(name, mode) {
        const result = []
        for (let i = 0; i < monitors.length; i++) {
            const copy = Object.assign({}, monitors[i])
            if (copy.name === name)
                copy.selectedMode = root.cleanMode(mode)
            result.push(copy)
        }
        root.monitors = result
    }

    function chooseResolution(name, resolution) {
        const result = []
        for (let i = 0; i < monitors.length; i++) {
            const copy = Object.assign({}, monitors[i])
            if (copy.name === name) {
                copy.selectedResolution = String(resolution)
                const modes = root.modesForResolution(copy, copy.selectedResolution)
                if (modes.length > 0)
                    copy.selectedMode = modes[0]
            }
            result.push(copy)
        }
        root.monitors = result
    }

    function chooseScale(name, scale) {
        const result = []
        for (let i = 0; i < monitors.length; i++) {
            const copy = Object.assign({}, monitors[i])
            if (copy.name === name)
                copy.selectedScale = Number(scale)
            result.push(copy)
        }
        root.monitors = result
    }

    function chooseRotation(name, rotation) {
        const result = []
        for (let i = 0; i < monitors.length; i++) {
            const copy = Object.assign({}, monitors[i])
            if (copy.name === name)
                copy.selectedRotation = Number(rotation)
            result.push(copy)
        }
        root.monitors = result
    }

    function brightnessFor(name) {
        return brightness[name] === undefined ? 100 : Number(brightness[name])
    }

    function setBrightness(name, value) {
        const percent = Math.max(10, Math.min(100, Math.round(value)))
        const next = Object.assign({}, brightness)
        next[name] = percent
        root.brightness = next
        brightnessState.setText(JSON.stringify(next))
        if (String(name).startsWith("eDP")) {
            if (root.brightnessService && root.brightnessService.internalDisplays.length > 0)
                root.brightnessService.setDisplayBrightness(root.brightnessService.internalDisplays[0], percent)
            else
                internalBrightnessProcess.exec(["brightnessctl", "set", percent + "%"])
        }
    }

    function indexForName(name) {
        for (let i = 0; i < monitors.length; i++)
            if (monitors[i].name === name) return i
        return -1
    }

    function apply() {
        if (monitors.length === 0 || applyProcess.running)
            return
        const args = ["bash", root.basePath + "/monitor-layout.sh", "apply"]
        for (let i = 0; i < monitors.length; i++)
            args.push(
                monitors[i].name,
                root.cleanMode(monitors[i].selectedMode),
                String(monitors[i].selectedScale),
                String(monitors[i].selectedRotation)
            )
        root.statusMessage = "Aplicando; confirma si todas las pantallas se ven"
        root.statusError = false
        applyProcess.exec(args)
    }

    function confirm() {
        confirmProcess.exec(["bash", root.basePath + "/monitor-layout.sh", "confirm"])
        root.pendingConfirmation = false
        root.secondsRemaining = 0
        root.statusMessage = "Distribución guardada"
    }

    function revert() {
        revertProcess.exec(["bash", root.basePath + "/monitor-layout.sh", "revert"])
        root.pendingConfirmation = false
        root.secondsRemaining = 0
        root.statusMessage = "Se restauró la distribución anterior"
    }

    Component.onCompleted: root.refresh()

    IpcHandler {
        target: "minibarMonitors"
        function identify(): void { root.identifying = !root.identifying }
        function refresh(): void { root.refresh() }
        function confirm(): void { root.confirm() }
        function revert(): void { root.revert() }
    }

    FileView {
        id: brightnessState
        path: Quickshell.env("HOME") + "/.local/state/minibar/monitor-brightness.json"
        printErrors: false
        onLoaded: {
            try { root.brightness = JSON.parse(brightnessState.text() || "{}") }
            catch (error) { root.brightness = ({}) }
        }
    }

    Timer { interval: 5000; repeat: true; running: root.pollingEnabled; onTriggered: root.refresh() }
    Timer {
        interval: 1000; repeat: true; running: root.pendingConfirmation
        onTriggered: {
            root.secondsRemaining--
            if (root.secondsRemaining <= 0) {
                root.pendingConfirmation = false
                root.statusMessage = "Tiempo agotado: se restauró la configuración anterior"
                refreshDelay.restart()
            }
        }
    }
    Timer { id: refreshDelay; interval: 900; onTriggered: root.refresh() }

    Process { id: readProcess; stdout: StdioCollector { onStreamFinished: root.parseMonitors(text) } }
    Process { id: internalBrightnessProcess }
    Process { id: hotplugProcess; onExited: refreshDelay.restart() }
    Process {
        id: applyProcess
        stderr: StdioCollector { id: applyError }
        onExited: function(code) {
            if (code === 0) {
                root.pendingConfirmation = true
                root.secondsRemaining = 15
                refreshDelay.restart()
            } else {
                root.statusError = true
                root.statusMessage = applyError.text.trim() || "No se pudo aplicar la distribución"
            }
        }
    }
    Process { id: confirmProcess }
    Process { id: revertProcess; onExited: refreshDelay.restart() }
}
