import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property bool laptopEnabled: true
    property bool externalEnabled: false
    property bool mouseKeyboardEnabled: false
    property string capsMode: "normal"
    property bool laptopPresent: false
    property bool externalPresent: false
    property bool mouseKeyboardPresent: false
    property bool loading: false
    property string statusMessage: ""
    property bool statusError: false
    property bool lightingPollingEnabled: false
    property bool laptopLightingAvailable: false
    property string laptopLightingDevice: ""
    property int laptopLightingCurrent: 0
    property int laptopLightingMaximum: 0
    property bool externalLightingConnected: false
    property bool externalLightingSoftwareSupport: false

    readonly property string basePath: String(Qt.resolvedUrl(".")).replace(/^file:\/\//, "")
    readonly property int activePhysicalCount: (laptopEnabled ? 1 : 0) + (externalEnabled ? 1 : 0)
    readonly property string summary: activePhysicalCount === 1 ? "1 teclado activo" : activePhysicalCount + " teclados activos"
    readonly property bool laptopLightingOn: laptopLightingCurrent > 0

    signal changed()

    function boolText(value) { return value ? "true" : "false" }

    function refresh() {
        if (!statusProcess.running)
            statusProcess.exec(["bash", root.basePath + "/keyboard-manager.sh", "status"])
        if (!detectProcess.running)
            detectProcess.exec(["hyprctl", "devices", "-j"])
        refreshLighting()
    }

    function refreshLighting() {
        if (!lightingStatusProcess.running)
            lightingStatusProcess.exec(["bash", root.basePath + "/keyboard-lighting.sh", "status"])
    }

    function parseLighting(text) {
        try {
            const data = JSON.parse(text)
            root.laptopLightingAvailable = data.laptopAvailable === true
            root.laptopLightingDevice = data.laptopDevice || ""
            root.laptopLightingCurrent = Number(data.laptopCurrent) || 0
            root.laptopLightingMaximum = Number(data.laptopMax) || 0
            root.externalLightingConnected = data.externalConnected === true
            root.externalLightingSoftwareSupport = data.externalSoftwareSupport === true
        } catch (error) {
            root.laptopLightingAvailable = false
        }
    }

    function toggleLaptopLighting() {
        if (!root.laptopLightingAvailable) {
            root.statusError = true
            root.statusMessage = "El kernel actual no expone el control de luz del teclado HP"
            return
        }
        laptopLightingProcess.exec(["bash", root.basePath + "/keyboard-lighting.sh", "toggle-laptop"])
    }

    function parseStatus(text) {
        try {
            const state = JSON.parse(text)
            root.laptopEnabled = state.laptop !== false
            root.externalEnabled = state.external === true
            root.mouseKeyboardEnabled = state.mouseKeyboard === true
            root.capsMode = state.capsMode === "disabled" ? "disabled" : "normal"
        } catch (error) {
            root.statusError = true
            root.statusMessage = "No se pudo leer el estado de los teclados"
        }
        root.changed()
    }

    function parseDevices(text) {
        try {
            const data = JSON.parse(text)
            const keyboards = data.keyboards || []
            let laptop = false
            let external = false
            let mouseKeyboard = false
            for (let i = 0; i < keyboards.length; i++) {
                const name = String(keyboards[i].name || "")
                if (name === "at-translated-set-2-keyboard") laptop = true
                if (name.startsWith("by-tech-gaming-keyboard")) external = true
                if (name === "instant-usb-gaming-mouse--keyboard") mouseKeyboard = true
            }
            root.laptopPresent = laptop
            root.externalPresent = external
            root.mouseKeyboardPresent = mouseKeyboard
        } catch (error) {
            root.statusError = true
            root.statusMessage = "No se pudieron detectar los teclados"
        }
    }

    function applyState(laptop, external, mouseKeyboard, newCapsMode) {
        if (!laptop && !external) {
            root.statusError = true
            root.statusMessage = "Debe quedar al menos un teclado físico activo"
            return
        }
        if (applyProcess.running)
            return
        root.laptopEnabled = laptop
        root.externalEnabled = external
        root.mouseKeyboardEnabled = mouseKeyboard
        root.capsMode = newCapsMode
        root.loading = true
        root.statusError = false
        root.statusMessage = "Aplicando configuración…"
        applyProcess.exec([
            "bash", root.basePath + "/keyboard-manager.sh", "apply",
            root.boolText(laptop), root.boolText(external), root.boolText(mouseKeyboard), newCapsMode
        ])
    }

    function setEnabled(group, enabled) {
        if (group === "laptop")
            applyState(enabled, root.externalEnabled, root.mouseKeyboardEnabled, root.capsMode)
        else if (group === "external")
            applyState(root.laptopEnabled, enabled, root.mouseKeyboardEnabled, root.capsMode)
        else if (group === "mouse")
            applyState(root.laptopEnabled, root.externalEnabled, enabled, root.capsMode)
    }

    function only(group) {
        if (group === "laptop")
            applyState(true, false, false, root.capsMode)
        else if (group === "external")
            applyState(false, true, false, root.capsMode)
    }

    function setCapsMode(mode) {
        applyState(root.laptopEnabled, root.externalEnabled, root.mouseKeyboardEnabled, mode)
    }

    Component.onCompleted: root.refresh()

    Process { id: statusProcess; stdout: StdioCollector { onStreamFinished: root.parseStatus(text) } }
    Process { id: detectProcess; stdout: StdioCollector { onStreamFinished: root.parseDevices(text) } }
    Process { id: lightingStatusProcess; stdout: StdioCollector { onStreamFinished: root.parseLighting(text) } }
    Process {
        id: laptopLightingProcess
        stderr: StdioCollector { id: laptopLightingError }
        onExited: function(code) {
            root.statusError = code !== 0
            root.statusMessage = code === 0 ? "Iluminación de la laptop actualizada" : (laptopLightingError.text.trim() || "No se pudo cambiar la iluminación")
            root.refreshLighting()
        }
    }
    Timer { interval: 3000; repeat: true; running: root.lightingPollingEnabled; onTriggered: root.refreshLighting() }
    Process {
        id: applyProcess
        stdout: StdioCollector { id: applyOutput }
        stderr: StdioCollector { id: applyError }
        onExited: function(code) {
            root.loading = false
            root.statusError = code !== 0
            root.statusMessage = code === 0
                ? "Configuración guardada para el próximo inicio"
                : (applyError.text.trim() || "No se pudo aplicar la configuración")
            root.refresh()
        }
    }
}
