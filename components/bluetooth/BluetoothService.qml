import QtQuick

import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io

Item {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool available:
        root.adapter !== null
        && root.adapter !== undefined
    readonly property bool enabled:
        root.available && root.adapter.enabled
    readonly property bool blocked:
        root.available
        && root.adapter.state === BluetoothAdapterState.Blocked
    readonly property bool scanning:
        root.available && root.adapter.discovering

    property bool actionRunning: false
    property string pendingAddress: ""
    property bool connectIssued: false
    property double actionStartedAt: 0
    property int enableAttempts: 0

    readonly property int connectedCount: {
        let count = 0
        const source = root.deviceSource()

        for (let i = 0; i < source.length; i++) {
            if (source[i] && source[i].connected)
                count += 1
        }

        return count
    }

    readonly property int pairedCount: {
        let count = 0
        const source = root.deviceSource()

        for (let i = 0; i < source.length; i++) {
            if (source[i] && source[i].paired)
                count += 1
        }

        return count
    }

    readonly property var devices: {
        // Estos marcadores fuerzan a reordenar cuando cambia el estado.
        const stateMarker = root.connectedCount + root.pairedCount
        const result = root.deviceSource()

        result.sort(function(a, b) {
            function priority(device) {
                if (device.connected)
                    return 0
                if (device.pairing)
                    return 1
                if (device.paired)
                    return 2
                return 3
            }

            const difference = priority(a) - priority(b)

            if (difference !== 0)
                return difference

            return root.deviceName(a).localeCompare(
                root.deviceName(b)
            )
        })

        return result
    }

    signal message(string text, bool isError)

    function deviceSource() {
        if (
            !root.adapter
            || !root.adapter.devices
            || !root.adapter.devices.values
        ) {
            return []
        }

        return Array.from(root.adapter.devices.values)
    }

    function deviceName(device) {
        if (!device)
            return "Dispositivo desconocido"

        return device.name
            || device.deviceName
            || device.address
            || "Dispositivo desconocido"
    }

    function deviceIcon(device) {
        const icon = device && device.icon
            ? String(device.icon).toLowerCase()
            : ""

        if (
            icon.includes("headset")
            || icon.includes("headphones")
            || icon.includes("audio")
        ) {
            return "󰋋"
        }

        if (icon.includes("mouse"))
            return "󰍽"

        if (icon.includes("keyboard"))
            return "󰌌"

        if (icon.includes("phone"))
            return "󰄜"

        if (icon.includes("computer"))
            return "󰟀"

        return "󰂯"
    }

    function deviceStatus(device) {
        if (!device)
            return "No disponible"

        if (root.pendingAddress === device.address) {
            if (device.pairing)
                return "Emparejando…"

            return "Conectando…"
        }

        if (device.connected) {
            if (device.batteryAvailable) {
                return "Conectado · "
                    + Math.round(device.battery * 100)
                    + "%"
            }

            return "Conectado"
        }

        if (device.state === BluetoothDeviceState.Connecting)
            return "Conectando…"

        if (device.state === BluetoothDeviceState.Disconnecting)
            return "Desconectando…"

        if (device.pairing)
            return "Emparejando…"

        if (device.paired)
            return "Emparejado"

        return "Disponible"
    }

    function findDevice(address) {
        const source = root.deviceSource()

        for (let i = 0; i < source.length; i++) {
            if (source[i].address === address)
                return source[i]
        }

        return null
    }

    function togglePower() {
        if (!root.available || root.actionRunning)
            return

        if (root.enabled) {
            root.stopScan()
            root.pendingAddress = ""
            root.connectIssued = false
            root.adapter.enabled = false
            root.message("Bluetooth desactivado", false)
            return
        }

        root.enableAttempts = 0

        if (root.blocked) {
            root.actionRunning = true
            unblockProcess.exec([
                "rfkill",
                "unblock",
                "bluetooth"
            ])
        } else {
            root.adapter.enabled = true
            root.message("Activando Bluetooth…", false)
        }
    }

    function setScanning(value) {
        if (!root.available || !root.enabled)
            return

        root.adapter.discovering = value

        if (value) {
            scanTimeout.restart()
            root.message("Buscando dispositivos cercanos…", false)
        } else {
            scanTimeout.stop()
        }
    }

    function toggleScan() {
        root.setScanning(!root.scanning)
    }

    function stopScan() {
        if (root.available && root.adapter.discovering)
            root.adapter.discovering = false

        scanTimeout.stop()
    }

    function toggleDevice(device) {
        if (!device || !root.enabled)
            return

        if (device.connected) {
            device.disconnect()
            root.message(
                "Desconectando " + root.deviceName(device) + "…",
                false
            )
            return
        }

        if (root.pendingAddress !== "") {
            if (
                root.pendingAddress === device.address
                && device.pairing
            ) {
                device.cancelPair()
                root.pendingAddress = ""
                root.connectIssued = false
                root.actionRunning = false
                root.message("Emparejamiento cancelado", false)
            }

            return
        }

        root.stopScan()
        root.pendingAddress = device.address
        root.connectIssued = false
        root.actionStartedAt = Date.now()
        root.actionRunning = true

        if (device.paired) {
            root.issueConnect(device)
            root.message(
                "Conectando " + root.deviceName(device) + "…",
                false
            )
        } else {
            device.pair()
            root.message(
                "Emparejando " + root.deviceName(device) + "…",
                false
            )
        }
    }

    function issueConnect(device) {
        if (!device || root.connectIssued)
            return

        root.connectIssued = true
        device.trusted = true
        device.connect()
    }

    function forgetDevice(device) {
        if (
            !device
            || device.connected
            || root.pendingAddress !== ""
        ) {
            return
        }

        const name = root.deviceName(device)
        device.forget()
        root.message("Se olvidó " + name, false)
    }

    Process {
        id: unblockProcess

        stderr: StdioCollector {
            id: unblockError
        }

        onExited: function(exitCode, exitStatus) {
            if (exitCode !== 0) {
                root.actionRunning = false
                root.message(
                    unblockError.text.trim() !== ""
                        ? unblockError.text.trim()
                        : "No se pudo desbloquear Bluetooth con rfkill",
                    true
                )
                return
            }

            root.enableAttempts = 0
            enableTimer.restart()
        }
    }

    Timer {
        id: enableTimer

        interval: 250
        repeat: false

        onTriggered: {
            if (!root.adapter)
                return

            root.enableAttempts += 1

            if (root.blocked && root.enableAttempts < 12) {
                enableTimer.restart()
                return
            }

            if (root.blocked) {
                root.actionRunning = false
                root.message(
                    "Bluetooth continúa bloqueado por rfkill",
                    true
                )
                return
            }

            root.adapter.enabled = true
            root.actionRunning = false
            root.message("Bluetooth activado", false)
        }
    }

    Timer {
        id: scanTimeout

        interval: 20000
        repeat: false
        onTriggered: root.stopScan()
    }

    Timer {
        interval: 300
        running: root.pendingAddress !== ""
        repeat: true

        onTriggered: {
            const device = root.findDevice(root.pendingAddress)

            if (!device) {
                root.pendingAddress = ""
                root.connectIssued = false
                root.actionRunning = false
                root.message("El dispositivo dejó de estar disponible", true)
                return
            }

            if (device.connected) {
                device.trusted = true
                root.message(
                    root.deviceName(device) + " conectado",
                    false
                )
                root.pendingAddress = ""
                root.connectIssued = false
                root.actionRunning = false
                return
            }

            if (
                device.paired
                && device.state === BluetoothDeviceState.Disconnected
                && !root.connectIssued
            ) {
                root.issueConnect(device)
            }

            if (Date.now() - root.actionStartedAt > 18000) {
                if (device.pairing)
                    device.cancelPair()

                root.pendingAddress = ""
                root.connectIssued = false
                root.actionRunning = false
                root.message(
                    root.deviceName(device)
                        + " no respondió. Activa su modo de emparejamiento e inténtalo otra vez",
                    true
                )
            }
        }
    }
}
