import QtQuick

import Quickshell
import Quickshell.Io

Item {
    id: root

    // Keep a slow status refresh for the bar; use faster polling only while a
    // network-related panel is visible.
    property bool detailedPollingEnabled: false
    property bool loading: false
    property bool connecting: false
    property bool wifiEnabled: false

    property string connectionType: "none"
    property string connectionName: ""
    property string activeInterface: ""
    property string wifiInterface: ""
    property string ethernetInterface: ""
    property string ipAddress: ""

    property real downloadBytesPerSecond: 0
    property real uploadBytesPerSecond: 0

    property real previousRxBytes: 0
    property real previousTxBytes: 0
    property double previousSampleTime: 0

    property var networks: []

    property string statusMessage: ""
    property string errorMessage: ""

    signal passwordRequested(var network)
    signal connectionSucceeded(string name)
    signal connectionFailed(string message)

    // =========================================================
    // TEXTO Y FORMATO
    // =========================================================

    function clean(value) {
        if (!value)
            return ""

        return String(value).trim()
    }

    function formatSpeed(bytesPerSecond) {
        const value = Number(bytesPerSecond) || 0

        if (value < 1024)
            return Math.round(value) + " B/s"

        if (value < 1024 * 1024)
            return (value / 1024).toFixed(1) + " KB/s"

        if (value < 1024 * 1024 * 1024)
            return (value / 1024 / 1024).toFixed(1) + " MB/s"

        return (
            value
            / 1024
            / 1024
            / 1024
        ).toFixed(1) + " GB/s"
    }

    function securityIsOpen(security) {
        const value = clean(security).toLowerCase()

        return value === ""
            || value === "--"
            || value === "none"
            || value === "open"
    }

    function securityLabel(security) {
        if (securityIsOpen(security))
            return "Abierta"

        return security
    }

    function signalIcon(signal) {
        const strength = Number(signal) || 0

        if (strength >= 75)
            return "󰤨"

        if (strength >= 50)
            return "󰤥"

        if (strength >= 25)
            return "󰤢"

        return "󰤟"
    }

    function mainIcon() {
        if (connectionType === "ethernet")
            return "󰈀"

        if (connectionType === "wifi")
            return signalIcon(
                currentWifiSignal()
            )

        if (!wifiEnabled)
            return "󰤭"

        return "󰤯"
    }

    function currentWifiSignal() {
        for (let i = 0; i < networks.length; i++) {
            if (networks[i].active)
                return networks[i].signal
        }

        return 0
    }

    // =========================================================
    // ESTADO GENERAL
    // =========================================================

    function refreshAll() {
        if (!statusProcess.running)
            statusProcess.exec([
                "nmcli",
                "-t",
                "-f",
                "DEVICE,TYPE,STATE,CONNECTION",
                "device",
                "status"
            ])

        if (!radioProcess.running)
            radioProcess.exec([
                "nmcli",
                "-t",
                "-f",
                "WIFI",
                "radio"
            ])

        refreshNetworks()
    }

    function refreshNetworks() {
        if (wifiListProcess.running)
            return

        root.loading = true

        wifiListProcess.exec([
            "nmcli",
            "-t",
            "--escape",
            "no",
            "-f",
            "IN-USE,SSID,SIGNAL,SECURITY",
            "device",
            "wifi",
            "list",
            "--rescan",
            "auto"
        ])
    }

    function parseDeviceStatus(text) {
        const lines = text.split("\n")

        let foundActive = false
        let foundWifi = ""
        let foundEthernet = ""

        let activeType = "none"
        let activeName = ""
        let activeDevice = ""

        for (let i = 0; i < lines.length; i++) {
            const line = lines[i].trim()

            if (line === "")
                continue

            const parts = line.split(":")

            if (parts.length < 4)
                continue

            const device = parts.shift()
            const type = parts.shift()
            const state = parts.shift()
            const connection = parts.join(":")

            if (type === "wifi" && foundWifi === "")
                foundWifi = device

            if (type === "ethernet" && foundEthernet === "")
                foundEthernet = device

            // Ignore loopback, Docker bridges, VPN helper devices, etc. If
            // Ethernet and Wi-Fi are both connected, display Ethernet because
            // it normally owns the preferred/default route.
            const supportedActiveType =
                type === "wifi"
                || type === "ethernet"

            const shouldSelect =
                state === "connected"
                && supportedActiveType
                && (
                    !foundActive
                    || (
                        type === "ethernet"
                        && activeType !== "ethernet"
                    )
                )

            if (shouldSelect) {
                foundActive = true
                activeType = type
                activeName = connection
                activeDevice = device
            }
        }

        root.wifiInterface = foundWifi
        root.ethernetInterface = foundEthernet

        root.connectionType =
            activeType === "wifi"
                ? "wifi"
                : activeType === "ethernet"
                    ? "ethernet"
                    : "none"

        root.connectionName =
            activeName === "--"
                ? ""
                : activeName

        root.activeInterface = activeDevice

        if (root.activeInterface !== "")
            ipProcess.exec([
                "sh",
                "-c",
                "ip -4 -o addr show dev \"$1\" scope global "
                    + "| awk '{print $4}' "
                    + "| cut -d/ -f1 "
                    + "| head -n1",
                "network-ip",
                root.activeInterface
            ])
        else
            root.ipAddress = ""

        resetSpeedSample()
    }

    function parseNetworks(text) {
        const result = []
        const grouped = {}

        const lines = text.split("\n")

        for (let i = 0; i < lines.length; i++) {
            const line = lines[i]

            if (!line || line.trim() === "")
                continue

            /*
             * Formato:
             * IN-USE:SSID:SIGNAL:SECURITY
             *
             * SECURITY no suele contener ":".
             * SSID puede contenerlo, por eso extraemos
             * desde los extremos.
             */
            const parts = line.split(":")

            if (parts.length < 4)
                continue

            const activeMark = parts.shift()
            const security = parts.pop()
            const signal = parts.pop()
            const ssid = parts.join(":").trim()

            if (ssid === "")
                continue

            const isActive =
                activeMark === "*"
                || ssid === root.connectionName

            const key = ssid

            /*
             * Un mismo SSID puede aparecer varias veces por
             * distintos puntos de acceso. Conservamos el de
             * mayor intensidad.
             */
            if (
                !grouped[key]
                || Number(signal)
                    > Number(grouped[key].signal)
            ) {
                grouped[key] = {
                    key: "wifi-" + ssid,
                    ssid: ssid,
                    signal: Number(signal) || 0,
                    security: security,
                    active: isActive,
                    open: securityIsOpen(security)
                }
            } else if (isActive) {
                grouped[key].active = true
            }
        }

        for (const key in grouped)
            result.push(grouped[key])

        result.sort(function(a, b) {
            if (a.active && !b.active)
                return -1

            if (!a.active && b.active)
                return 1

            return b.signal - a.signal
        })

        root.networks = result
        root.loading = false
    }

    // =========================================================
    // WI-FI
    // =========================================================

    function setWifiEnabled(enabled) {
        if (
            wifiRadioProcess.running
            || connectProcess.running
            || ethernetProcess.running
        ) {
            return
        }

        root.errorMessage = ""
        wifiRadioProcess.requestedState = enabled

        wifiRadioProcess.exec([
            "nmcli",
            "radio",
            "wifi",
            enabled ? "on" : "off"
        ])
    }

    function selectNetwork(network) {
        if (!network || !network.ssid)
            return

        root.errorMessage = ""
        root.statusMessage = ""

        if (network.active)
            return

        if (network.open) {
            connectOpenNetwork(network)
            return
        }

        root.passwordRequested(network)
    }

    function connectOpenNetwork(network) {
        if (
            !network
            || !network.ssid
            || connectProcess.running
            || ethernetProcess.running
        ) {
            return
        }

        root.connecting = true
        root.errorMessage = ""
        root.statusMessage =
            "Conectando a " + network.ssid + "…"

        connectProcess.pendingSsid = network.ssid

        const command = [
            "nmcli",
            "--wait",
            "20",
            "device",
            "wifi",
            "connect",
            network.ssid
        ]

        if (root.wifiInterface !== "") {
            command.push("ifname")
            command.push(root.wifiInterface)
        }

        connectProcess.exec(command)
    }

    function connectProtectedNetwork(network, password) {
        if (
            !network
            || !network.ssid
            || connectProcess.running
            || ethernetProcess.running
        ) {
            return
        }

        if (!password || password.length === 0) {
            root.connectionFailed(
                "Escribe la contraseña"
            )
            return
        }

        root.connecting = true
        root.errorMessage = ""
        root.statusMessage =
            "Conectando a " + network.ssid + "…"

        connectProcess.pendingSsid = network.ssid

        const command = [
            "nmcli",
            "--wait",
            "25",
            "device",
            "wifi",
            "connect",
            network.ssid,
            "password",
            password
        ]

        if (root.wifiInterface !== "") {
            command.push("ifname")
            command.push(root.wifiInterface)
        }

        connectProcess.exec(command)
    }

    function disconnectWifi() {
        if (
            root.wifiInterface === ""
            || disconnectProcess.running
            || root.connecting
        ) {
            return
        }

        disconnectProcess.exec([
            "nmcli",
            "device",
            "disconnect",
            root.wifiInterface
        ])
    }

    // =========================================================
    // ETHERNET
    // =========================================================

    function useEthernet() {
        if (
            ethernetProcess.running
            || connectProcess.running
        ) {
            return
        }

        if (root.ethernetInterface === "") {
            root.connectionFailed(
                "No se detectó una interfaz Ethernet"
            )
            return
        }

        root.connecting = true
        root.errorMessage = ""
        root.statusMessage =
            "Activando conexión por cable…"

        ethernetProcess.exec([
            "nmcli",
            "--wait",
            "20",
            "device",
            "connect",
            root.ethernetInterface
        ])
    }

    // =========================================================
    // VELOCIDAD DE RED
    // =========================================================

    function resetSpeedSample() {
        root.previousRxBytes = 0
        root.previousTxBytes = 0
        root.previousSampleTime = 0

        root.downloadBytesPerSecond = 0
        root.uploadBytesPerSecond = 0
    }

    function sampleSpeed() {
        if (
            root.activeInterface === ""
            || speedProcess.running
        ) {
            return
        }

        speedProcess.exec([
            "sh",
            "-c",
            "cat /sys/class/net/\"$1\"/statistics/rx_bytes; "
                + "cat /sys/class/net/\"$1\"/statistics/tx_bytes",
            "network-speed",
            root.activeInterface
        ])
    }

    function processSpeedSample(text) {
        const lines = text
            .trim()
            .split("\n")

        if (lines.length < 2)
            return

        const rx = Number(lines[0]) || 0
        const tx = Number(lines[1]) || 0
        const now = Date.now()

        if (
            root.previousSampleTime > 0
            && now > root.previousSampleTime
        ) {
            const seconds =
                (now - root.previousSampleTime) / 1000

            root.downloadBytesPerSecond =
                Math.max(
                    0,
                    (rx - root.previousRxBytes)
                    / seconds
                )

            root.uploadBytesPerSecond =
                Math.max(
                    0,
                    (tx - root.previousTxBytes)
                    / seconds
                )
        }

        root.previousRxBytes = rx
        root.previousTxBytes = tx
        root.previousSampleTime = now
    }

    // =========================================================
    // PROCESOS
    // =========================================================

    Process {
        id: statusProcess

        stdout: StdioCollector {
            onStreamFinished: {
                root.parseDeviceStatus(text)
            }
        }
    }

    Process {
        id: radioProcess

        stdout: StdioCollector {
            onStreamFinished: {
                const value = text
                    .trim()
                    .toLowerCase()

                root.wifiEnabled =
                    value === "enabled"
                    || value === "yes"
                    || value === "on"
            }
        }
    }

    Process {
        id: wifiListProcess

        stdout: StdioCollector {
            onStreamFinished: {
                root.parseNetworks(text)
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim() !== "")
                    console.log(
                        "Error escaneando Wi-Fi:",
                        text
                    )
            }
        }

        onExited: function(exitCode, exitStatus) {
            root.loading = false
        }
    }

    Process {
        id: ipProcess

        stdout: StdioCollector {
            onStreamFinished: {
                root.ipAddress = text.trim()
            }
        }
    }

    Process {
        id: speedProcess

        stdout: StdioCollector {
            onStreamFinished: {
                root.processSpeedSample(text)
            }
        }
    }

    Process {
        id: wifiRadioProcess

        property bool requestedState: false

        onExited: function(exitCode, exitStatus) {
            if (exitCode === 0) {
                root.wifiEnabled =
                    wifiRadioProcess.requestedState

                refreshTimer.restart()
            } else {
                root.connectionFailed(
                    "No se pudo cambiar el estado del Wi-Fi"
                )
            }
        }
    }

    Process {
        id: connectProcess

        property string pendingSsid: ""

        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim() !== "")
                    console.log(
                        "nmcli connect:",
                        text
                    )
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim() !== "")
                    root.errorMessage = text.trim()
            }
        }

        onExited: function(exitCode, exitStatus) {
            root.connecting = false

            if (exitCode === 0) {
                root.statusMessage =
                    "Conectado a "
                    + connectProcess.pendingSsid

                root.connectionSucceeded(
                    connectProcess.pendingSsid
                )
            } else {
                const message =
                    root.errorMessage !== ""
                        ? root.errorMessage
                        : "No se pudo conectar a la red"

                root.statusMessage = ""
                root.connectionFailed(message)
            }

            connectProcess.pendingSsid = ""
            delayedRefresh.restart()
        }
    }

    Process {
        id: ethernetProcess

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim() !== "")
                    root.errorMessage = text.trim()
            }
        }

        onExited: function(exitCode, exitStatus) {
            root.connecting = false

            if (exitCode === 0) {
                root.statusMessage =
                    "Conexión por cable activada"

                root.connectionSucceeded(
                    "Ethernet"
                )
            } else {
                root.connectionFailed(
                    root.errorMessage !== ""
                        ? root.errorMessage
                        : "No se pudo activar Ethernet"
                )
            }

            delayedRefresh.restart()
        }
    }

    Process {
        id: disconnectProcess

        onExited: function(exitCode, exitStatus) {
            delayedRefresh.restart()
        }
    }

    // =========================================================
    // TEMPORIZADORES
    // =========================================================

    Timer {
        id: refreshTimer

        interval: 250
        repeat: false

        onTriggered: root.refreshAll()
    }

    Timer {
        id: delayedRefresh

        interval: 1200
        repeat: false

        onTriggered: root.refreshAll()
    }

    Timer {
        interval: root.detailedPollingEnabled ? 5000 : 15000
        running: true
        repeat: true

        onTriggered: root.refreshAll()
    }

    Timer {
        interval: 1000
        running: root.detailedPollingEnabled
        repeat: true

        onTriggered: root.sampleSpeed()
    }

    Component.onCompleted: {
        root.refreshAll()
    }

    onDetailedPollingEnabledChanged: {
        if (root.detailedPollingEnabled)
            root.refreshAll()
    }
}
