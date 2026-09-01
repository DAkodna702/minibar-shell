import QtQuick

import Quickshell
import Quickshell.Io

Item {
    id: root

    property bool loading: false
    property bool externalScanEnabled: true

    property var internalDisplays: []
    property var externalDisplays: []

    // Conserva el último valor elegido mientras el hardware confirma el cambio.
    property var internalPendingValues: ({})
    property var externalPendingValues: ({})
    property var internalWriteQueue: []
    property var externalWriteQueue: []

    readonly property var displays:
        internalDisplays.concat(externalDisplays)

    readonly property int primaryBrightness:
        internalDisplays.length > 0
            ? internalDisplays[0].percent
            : (
                externalDisplays.length > 0
                    ? externalDisplays[0].percent
                    : 0
            )

    readonly property bool available:
        displays.length > 0

    signal refreshed()
    signal errorOccurred(string message)

    // =========================================================
    // UTILIDADES
    // =========================================================

    function clamp(value, minimum, maximum) {
        return Math.max(
            minimum,
            Math.min(maximum, value)
        )
    }

    function brightnessIcon(percent) {
        const value = Number(percent) || 0

        if (value <= 10)
            return "󰃞"

        if (value <= 35)
            return "󰃟"

        if (value <= 70)
            return "󰃠"

        return "󰃝"
    }

    function displayName(deviceName) {
        if (!deviceName)
            return "Pantalla interna"

        const value = String(deviceName)

        if (value.includes("intel"))
            return "Pantalla interna Intel"

        if (
            value.includes("amdgpu")
            || value.includes("radeon")
        ) {
            return "Pantalla interna AMD"
        }

        if (value.includes("nvidia"))
            return "Pantalla interna NVIDIA"

        return "Pantalla interna"
    }

    function findInternalDevice(deviceName) {
        for (
            let i = 0;
            i < root.internalDisplays.length;
            i++
        ) {
            if (
                root.internalDisplays[i].device
                === deviceName
            ) {
                return root.internalDisplays[i]
            }
        }

        return null
    }

    function findExternalDisplay(displayNumber) {
        for (
            let i = 0;
            i < root.externalDisplays.length;
            i++
        ) {
            if (
                root.externalDisplays[i].displayNumber
                === displayNumber
            ) {
                return root.externalDisplays[i]
            }
        }

        return null
    }

    function withPendingValue(source, key, value) {
        const result = {}

        for (const existingKey in source)
            result[existingKey] = source[existingKey]

        result[String(key)] = {
            value: value,
            requestedAt: Date.now()
        }

        return result
    }

    function withoutPendingValue(source, key) {
        const result = {}

        for (const existingKey in source) {
            if (existingKey !== String(key))
                result[existingKey] = source[existingKey]
        }

        return result
    }

    function reconciledValue(source, key, actualValue) {
        const pending = source[String(key)]

        if (!pending)
            return actualValue

        if (Math.abs(actualValue - pending.value) <= 1)
            return actualValue

        // Evita que una lectura iniciada antes de escribir haga saltar el UI.
        if (Date.now() - pending.requestedAt < 4000)
            return pending.value

        return actualValue
    }

    function enqueueWrite(queue, keyName, key, value) {
        const result = []

        for (let i = 0; i < queue.length; i++) {
            if (String(queue[i][keyName]) !== String(key))
                result.push(queue[i])
        }

        const entry = { percent: value }
        entry[keyName] = key
        result.push(entry)

        return result
    }

    // =========================================================
    // ACTUALIZAR
    // =========================================================

    function refresh() {
        if (internalListProcess.running)
            return

        root.loading = true

        internalListProcess.exec([
            "sh",
            "-c",
            "brightnessctl -m -c backlight 2>/dev/null || true"
        ])

        if (
            root.externalScanEnabled
            && !externalListProcess.running
        ) {
            externalListProcess.exec([
                "sh",
                "-c",
                `
if ! command -v ddcutil >/dev/null 2>&1; then
    exit 0
fi

displays="$(
    ddcutil detect --brief 2>/dev/null |
    sed -n 's/^Display[[:space:]]\\+\\([0-9]\\+\\).*/\\1/p'
)"

for display in $displays; do
    value="$(
        ddcutil --display "$display" getvcp 10 --brief 2>/dev/null |
        awk '
        {
            for (i = 1; i <= NF; i++) {
                if ($i == "C" && (i + 2) <= NF) {
                    print $(i + 1), $(i + 2)
                    exit
                }
            }
        }'
    )"

    current="$(printf '%s\\n' "$value" | awk '{print $1}')"
    maximum="$(printf '%s\\n' "$value" | awk '{print $2}')"

    if [ -n "$current" ] && [ -n "$maximum" ] && [ "$maximum" -gt 0 ] 2>/dev/null; then
        percent=$((current * 100 / maximum))
        printf '%s\\t%s\\t%s\\t%s\\n' \
            "$display" "$current" "$maximum" "$percent"
    fi
done
`
            ])
        }
    }

    // =========================================================
    // PANTALLAS INTERNAS
    // =========================================================

    function parseInternalDisplays(output) {
        const result = []

        if (!output || output.trim() === "") {
            root.internalDisplays = []
            finishRefresh()
            return
        }

        const lines = output.trim().split("\n")

        for (let i = 0; i < lines.length; i++) {
            const line = lines[i].trim()

            if (line === "")
                continue

            /*
             * brightnessctl -m:
             *
             * device,class,current,percent,max
             */
            const parts = line.split(",")

            if (parts.length < 5)
                continue

            const device = parts[0]
            const current = Number(parts[2]) || 0
            const maximum = Number(parts[4]) || 0

            let percent = parseInt(
                String(parts[3]).replace("%", "")
            )

            if (isNaN(percent) && maximum > 0) {
                percent = Math.round(
                    current / maximum * 100
                )
            }

            const reconciledPercent =
                root.reconciledValue(
                    root.internalPendingValues,
                    device,
                    root.clamp(percent || 0, 0, 100)
                )

            if (Math.abs(reconciledPercent - (percent || 0)) <= 1) {
                root.internalPendingValues =
                    root.withoutPendingValue(
                        root.internalPendingValues,
                        device
                    )
            }

            result.push({
                key: "internal-" + device,
                type: "internal",
                device: device,
                name: root.displayName(device),
                current: current,
                maximum: maximum,
                percent: reconciledPercent
            })
        }

        root.internalDisplays = result
        finishRefresh()
    }

    function setInternalBrightness(device, percent) {
        if (!device)
            return

        const value = root.clamp(
            Math.round(percent),
            1,
            100
        )

        root.internalPendingValues =
            root.withPendingValue(
                root.internalPendingValues,
                device,
                value
            )

        root.internalWriteQueue =
            root.enqueueWrite(
                root.internalWriteQueue,
                "device",
                device,
                value
            )

        updateInternalLocally(device, value)
        internalWriteTimer.restart()
    }

    function changePrimaryBrightness(delta) {
        if (root.internalDisplays.length > 0) {
            const display = root.internalDisplays[0]

            root.setInternalBrightness(
                display.device,
                display.percent + delta
            )

            return
        }

        if (root.externalDisplays.length > 0) {
            const display = root.externalDisplays[0]

            root.setExternalBrightness(
                display.displayNumber,
                display.percent + delta
            )
        }
    }

    function updateInternalLocally(device, percent) {
        const result = []

        for (
            let i = 0;
            i < root.internalDisplays.length;
            i++
        ) {
            const item = root.internalDisplays[i]

            if (item.device === device) {
                result.push({
                    key: item.key,
                    type: item.type,
                    device: item.device,
                    name: item.name,
                    current: item.current,
                    maximum: item.maximum,
                    percent: percent
                })
            } else {
                result.push(item)
            }
        }

        root.internalDisplays = result
    }

    // =========================================================
    // MONITORES EXTERNOS
    // =========================================================

    function parseExternalDisplays(output) {
        const result = []

        if (!output || output.trim() === "") {
            root.externalDisplays = []
            finishRefresh()
            return
        }

        const lines = output.trim().split("\n")

        for (let i = 0; i < lines.length; i++) {
            const line = lines[i].trim()

            if (line === "")
                continue

            const parts = line.split("\t")

            if (parts.length < 4)
                continue

            const displayNumber =
                Number(parts[0]) || 0

            const current =
                Number(parts[1]) || 0

            const maximum =
                Number(parts[2]) || 100

            const actualPercent =
                root.clamp(
                    Number(parts[3]) || 0,
                    0,
                    100
                )

            const percent =
                root.reconciledValue(
                    root.externalPendingValues,
                    displayNumber,
                    actualPercent
                )

            if (Math.abs(percent - actualPercent) <= 1) {
                root.externalPendingValues =
                    root.withoutPendingValue(
                        root.externalPendingValues,
                        displayNumber
                    )
            }

            result.push({
                key:
                    "external-"
                    + displayNumber,

                type: "external",
                displayNumber: displayNumber,

                name:
                    "Monitor externo "
                    + displayNumber,

                current: current,
                maximum: maximum,
                percent: percent
            })
        }

        root.externalDisplays = result
        finishRefresh()
    }

    function setExternalBrightness(
        displayNumber,
        percent
    ) {
        if (!displayNumber)
            return

        const value = root.clamp(
            Math.round(percent),
            0,
            100
        )

        root.externalPendingValues =
            root.withPendingValue(
                root.externalPendingValues,
                displayNumber,
                value
            )

        root.externalWriteQueue =
            root.enqueueWrite(
                root.externalWriteQueue,
                "displayNumber",
                displayNumber,
                value
            )

        updateExternalLocally(
            displayNumber,
            value
        )

        externalWriteTimer.restart()
    }

    function flushInternalWrite() {
        if (
            internalSetProcess.running
            || root.internalWriteQueue.length === 0
        ) {
            return
        }

        const entry = root.internalWriteQueue[0]
        root.internalWriteQueue = root.internalWriteQueue.slice(1)

        internalSetProcess.pendingDevice = entry.device
        internalSetProcess.pendingPercent = entry.percent
        internalSetProcess.exec([
            "brightnessctl",
            "-d",
            entry.device,
            "set",
            entry.percent + "%"
        ])
    }

    function flushExternalWrite() {
        if (
            externalSetProcess.running
            || root.externalWriteQueue.length === 0
        ) {
            return
        }

        const entry = root.externalWriteQueue[0]
        root.externalWriteQueue = root.externalWriteQueue.slice(1)

        externalSetProcess.pendingDisplay = entry.displayNumber
        externalSetProcess.pendingPercent = entry.percent
        externalSetProcess.exec([
            "ddcutil",
            "--display",
            String(entry.displayNumber),
            "setvcp",
            "10",
            String(entry.percent),
            "--noverify"
        ])
    }

    function updateExternalLocally(
        displayNumber,
        percent
    ) {
        const result = []

        for (
            let i = 0;
            i < root.externalDisplays.length;
            i++
        ) {
            const item = root.externalDisplays[i]

            if (
                item.displayNumber
                === displayNumber
            ) {
                result.push({
                    key: item.key,
                    type: item.type,
                    displayNumber:
                        item.displayNumber,

                    name: item.name,
                    current: item.current,
                    maximum: item.maximum,
                    percent: percent
                })
            } else {
                result.push(item)
            }
        }

        root.externalDisplays = result
    }

    function setDisplayBrightness(display, value) {
        if (!display)
            return

        if (display.type === "internal") {
            root.setInternalBrightness(
                display.device,
                value
            )
        } else if (display.type === "external") {
            root.setExternalBrightness(
                display.displayNumber,
                value
            )
        }
    }

    function finishRefresh() {
        if (
            !internalListProcess.running
            && !externalListProcess.running
        ) {
            root.loading = false
            root.refreshed()
        }
    }

    // =========================================================
    // PROCESOS
    // =========================================================

    Process {
        id: internalListProcess

        stdout: StdioCollector {
            onStreamFinished: {
                root.parseInternalDisplays(text)
            }
        }

        onExited: function(exitCode, exitStatus) {
            root.finishRefresh()
        }
    }

    Process {
        id: externalListProcess

        stdout: StdioCollector {
            onStreamFinished: {
                root.parseExternalDisplays(text)
            }
        }

        onExited: function(exitCode, exitStatus) {
            root.finishRefresh()
        }
    }

    Process {
        id: internalSetProcess

        property string pendingDevice: ""
        property int pendingPercent: 0

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim() !== "") {
                    console.log(
                        "Error ajustando brillo interno:",
                        text
                    )
                }
            }
        }

        onExited: function(exitCode, exitStatus) {
            if (exitCode !== 0) {
                root.internalPendingValues =
                    root.withoutPendingValue(
                        root.internalPendingValues,
                        internalSetProcess.pendingDevice
                    )

                root.errorOccurred(
                    "No se pudo cambiar el brillo interno"
                )
            }

            if (root.internalWriteQueue.length > 0)
                internalWriteTimer.restart()
            else
                delayedRefresh.restart()
        }
    }

    Process {
        id: externalSetProcess

        property int pendingDisplay: 0
        property int pendingPercent: 0

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim() !== "") {
                    console.log(
                        "Error ajustando monitor externo:",
                        text
                    )
                }
            }
        }

        onExited: function(exitCode, exitStatus) {
            if (exitCode !== 0) {
                root.externalPendingValues =
                    root.withoutPendingValue(
                        root.externalPendingValues,
                        externalSetProcess.pendingDisplay
                    )

                root.errorOccurred(
                    "El monitor externo no permitió cambiar el brillo"
                )
            }

            if (root.externalWriteQueue.length > 0)
                externalWriteTimer.restart()
            else
                delayedRefresh.restart()
        }
    }

    Timer {
        id: internalWriteTimer

        interval: 140
        repeat: false
        onTriggered: root.flushInternalWrite()
    }

    Timer {
        id: externalWriteTimer

        interval: 180
        repeat: false
        onTriggered: root.flushExternalWrite()
    }

    Timer {
        id: delayedRefresh

        interval: 900
        repeat: false

        onTriggered: root.refresh()
    }

    Timer {
        interval: 15000
        running: true
        repeat: true

        onTriggered: root.refresh()
    }

    Component.onCompleted: {
        root.refresh()
    }
}
