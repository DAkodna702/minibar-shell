import QtQuick

import Quickshell
import Quickshell.Io

Item {
    id: root

    property bool pollingEnabled: false
    property int maxEntries: 100

    // Historial normal de cliphist.
    property var entries: []

    // Elementos guardados permanentemente.
    property var pins: []

    property string searchText: ""
    property bool loading: false
    property int imageRevision: 0

    property var previewQueue: []
    property var requestedPreviews: ({})

    readonly property int count: entries.length

    readonly property var filteredEntries:
        filterList(entries)

    readonly property var filteredPins:
        filterList(pins)

    readonly property string dataDirectory:
        Quickshell.dataPath("clipboardplus")

    readonly property string pinsPath:
        dataDirectory + "/pins.json"

    readonly property string pinnedFilesDirectory:
        dataDirectory + "/pinned"

    readonly property string previewDirectory:
        Quickshell.cachePath("clipboardplus-previews")

    signal copied(string preview)
    signal errorOccurred(string message)

    // =========================================================
    // UTILIDADES
    // =========================================================

    function normalize(value) {
        return value
            ? String(value).toLowerCase()
            : ""
    }

    function safeId(value) {
        return String(value || "item")
            .replace(/[^a-zA-Z0-9_-]/g, "_")
    }

    function fileUrl(path) {
        if (!path || path === "")
            return ""

        return "file://" + path
            + "?revision=" + root.imageRevision
    }

    function isImagePreview(preview) {
        if (!preview)
            return false

        const value = String(preview).toLowerCase()

        return value.includes("[[ binary data")
            || value.includes("binary data")
            || value.includes("[[binary")
    }

    function filterList(sourceList) {
        const query = normalize(root.searchText).trim()

        if (query === "")
            return sourceList

        const result = []

        for (let i = 0; i < sourceList.length; i++) {
            const entry = sourceList[i]

            if (
                normalize(entry.preview).includes(query)
                || normalize(entry.type).includes(query)
            ) {
                result.push(entry)
            }
        }

        return result
    }

    function isPinned(entry) {
        if (!entry)
            return false

        for (let i = 0; i < root.pins.length; i++) {
            const pin = root.pins[i]

            if (
                pin.sourceId === entry.id
                && pin.isImage === entry.isImage
            ) {
                return true
            }
        }

        return false
    }

    // =========================================================
    // LEER HISTORIAL
    // =========================================================

    function parseList(output) {
        const result = []

        if (!output || output.trim() === "")
            return result

        const lines = output.split("\n")

        const entryLimit = Math.min(lines.length, root.maxEntries)

        for (let i = 0; i < entryLimit; i++) {
            const rawLine = lines[i]

            if (!rawLine || rawLine.trim() === "")
                continue

            const separatorIndex = rawLine.indexOf("\t")

            let entryId = ""
            let preview = rawLine

            if (separatorIndex >= 0) {
                entryId = rawLine.substring(0, separatorIndex)
                preview = rawLine.substring(separatorIndex + 1)
            }

            preview = preview
                .replace(/\r/g, "")
                .trim()

            const imageEntry = root.isImagePreview(preview)

            const previewPath = imageEntry
                ? root.previewDirectory
                    + "/history-"
                    + root.safeId(entryId)
                    + ".img"
                : ""

            const entry = {
                key: "history-" + entryId + "-" + i,
                id: entryId,
                sourceId: entryId,
                raw: rawLine,

                preview: imageEntry
                    ? "Imagen copiada"
                    : (
                        preview === ""
                            ? "(contenido vacío)"
                            : preview
                    ),

                originalPreview: preview,
                isImage: imageEntry,
                type: imageEntry ? "Imagen" : "Texto",
                imagePath: previewPath,
                pinned: false
            }

            result.push(entry)

            if (imageEntry)
                root.queueImagePreview(entry)
        }

        return result
    }

    function refresh() {
        if (listProcess.running)
            return

        root.loading = true
        listProcess.exec(["cliphist", "list"])
    }

    // =========================================================
    // MINIATURAS DE IMÁGENES
    // =========================================================

    function queueImagePreview(entry) {
        if (!entry || !entry.raw || !entry.imagePath)
            return

        if (root.requestedPreviews[entry.imagePath])
            return

        const requested = {}

        for (const path in root.requestedPreviews)
            requested[path] = root.requestedPreviews[path]

        requested[entry.imagePath] = true
        root.requestedPreviews = requested

        root.previewQueue =
            root.previewQueue.concat([entry])

        root.runNextPreview()
    }

    function runNextPreview() {
        if (previewProcess.running)
            return

        if (root.previewQueue.length === 0)
            return

        const nextEntry = root.previewQueue[0]

        root.previewQueue =
            root.previewQueue.slice(1)

        previewProcess.currentEntry = nextEntry

        previewProcess.exec([
            "sh",
            "-c",
            "mkdir -p \"$(dirname \"$2\")\"; "
                + "printf '%s' \"$1\" | cliphist decode > \"$2\"",
            "clipboard-preview",
            nextEntry.raw,
            nextEntry.imagePath
        ])
    }

    // =========================================================
    // COPIAR
    // =========================================================

    function copyEntry(entry) {
        if (
            !entry
            || !entry.raw
            || copyHistoryProcess.running
        ) {
            return
        }

        copyHistoryProcess.pendingPreview =
            entry.preview

        copyHistoryProcess.exec([
            "sh",
            "-c",
            "printf '%s' \"$1\" | cliphist decode | wl-copy",
            "clipboard-copy",
            entry.raw
        ])
    }

    function copyPinned(pin) {
        if (
            !pin
            || !pin.path
            || copyPinnedProcess.running
        ) {
            return
        }

        copyPinnedProcess.pendingPreview =
            pin.preview

        copyPinnedProcess.exec([
            "sh",
            "-c",
            "mime=$(file --brief --mime-type \"$1\"); "
                + "if [ -z \"$mime\" ]; then mime=text/plain; fi; "
                + "wl-copy --type \"$mime\" < \"$1\"",
            "clipboard-copy-pin",
            pin.path
        ])
    }

    // =========================================================
    // ELIMINAR HISTORIAL
    // =========================================================

    function deleteEntry(entry) {
        if (
            !entry
            || !entry.raw
            || deleteProcess.running
            || wipeProcess.running
        ) {
            return
        }

        deleteProcess.exec([
            "sh",
            "-c",
            "printf '%s' \"$1\" | cliphist delete",
            "clipboard-delete",
            entry.raw
        ])
    }

    function clearAll() {
        if (wipeProcess.running || deleteProcess.running)
            return

        wipeProcess.exec(["cliphist", "wipe"])
    }

    // =========================================================
    // FIJADOS
    // =========================================================

    function pinEntry(entry) {
        if (
            !entry
            || !entry.raw
            || pinProcess.running
        ) {
            return
        }

        if (root.isPinned(entry))
            return

        const timestamp = Date.now()

        const extension =
            entry.isImage ? ".img" : ".txt"

        const destination =
            root.pinnedFilesDirectory
            + "/pin-"
            + timestamp
            + "-"
            + root.safeId(entry.id)
            + extension

        pinProcess.pendingEntry = entry
        pinProcess.pendingPath = destination
        pinProcess.pendingKey = "pin-" + timestamp

        pinProcess.exec([
            "sh",
            "-c",
            "mkdir -p \"$(dirname \"$2\")\"; "
                + "printf '%s' \"$1\" | cliphist decode > \"$2\"",
            "clipboard-pin",
            entry.raw,
            destination
        ])
    }

    function finishPin() {
        const entry = pinProcess.pendingEntry

        if (!entry)
            return

        const newPin = {
            key: pinProcess.pendingKey,
            id: pinProcess.pendingKey,
            sourceId: entry.id,

            preview: entry.preview,
            originalPreview: entry.originalPreview,

            isImage: entry.isImage,
            type: entry.isImage ? "Imagen" : "Texto",

            path: pinProcess.pendingPath,
            imagePath: entry.isImage
                ? pinProcess.pendingPath
                : "",

            pinned: true,
            createdAt: Date.now()
        }

        root.pins = root.pins.concat([newPin])
        root.savePins()
    }

    function unpin(pin) {
        if (!pin)
            return

        const result = []

        for (let i = 0; i < root.pins.length; i++) {
            if (root.pins[i].key !== pin.key)
                result.push(root.pins[i])
        }

        root.pins = result
        root.savePins()

        if (pin.path) {
            removePinnedFileProcess.exec([
                "rm",
                "-f",
                pin.path
            ])
        }
    }

    function loadPins() {
        if (!pinsFile.loaded)
            return

        try {
            const contents = pinsFile.text().trim()

            if (contents === "") {
                root.pins = []
                return
            }

            const parsed = JSON.parse(contents)

            root.pins =
                Array.isArray(parsed)
                    ? parsed
                    : []
        } catch (error) {
            console.log(
                "Error leyendo pins.json:",
                error
            )

            root.pins = []
        }

        root.imageRevision += 1
    }

    function savePins() {
        try {
            pinsFile.setText(
                JSON.stringify(root.pins, null, 2)
            )
        } catch (error) {
            root.errorOccurred(
                "No se pudieron guardar los fijados"
            )
        }
    }

    // =========================================================
    // ARCHIVO JSON
    // =========================================================

    FileView {
        id: pinsFile

        path: root.pinsPath

        blockLoading: true
        atomicWrites: true
        printErrors: false

        onLoaded: {
            root.loadPins()
        }

        onSaveFailed: function(error) {
            root.errorOccurred(
                "No se pudieron guardar los fijados"
            )
        }
    }

    // =========================================================
    // PROCESOS
    // =========================================================

    Process {
        id: initializeProcess

        onExited: function(exitCode, exitStatus) {
            pinsFile.reload()
            root.refresh()
        }
    }

    Process {
        id: listProcess

        stdout: StdioCollector {
            onStreamFinished: {
                root.entries = root.parseList(text)
                root.loading = false
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim() !== "") {
                    console.log(
                        "cliphist list:",
                        text
                    )
                }
            }
        }

        onExited: function(exitCode, exitStatus) {
            root.loading = false

            if (exitCode !== 0) {
                root.errorOccurred(
                    "No se pudo leer cliphist"
                )
            }
        }
    }

    Process {
        id: previewProcess

        property var currentEntry: null

        onExited: function(exitCode, exitStatus) {
            if (exitCode === 0) {
                root.imageRevision += 1
            } else if (previewProcess.currentEntry) {
                root.requestedPreviews =
                    root.withoutPreviewRequest(
                        previewProcess.currentEntry.imagePath
                    )
            }

            previewProcess.currentEntry = null
            root.runNextPreview()
        }
    }

    function withoutPreviewRequest(pathToRemove) {
        const requested = {}

        for (const path in root.requestedPreviews) {
            if (path !== pathToRemove)
                requested[path] = root.requestedPreviews[path]
        }

        return requested
    }

    Process {
        id: copyHistoryProcess

        property string pendingPreview: ""

        onExited: function(exitCode, exitStatus) {
            if (exitCode === 0) {
                root.copied(
                    copyHistoryProcess.pendingPreview
                )

                refreshTimer.restart()
            } else {
                root.errorOccurred(
                    "No se pudo copiar el elemento"
                )
            }
        }
    }

    Process {
        id: copyPinnedProcess

        property string pendingPreview: ""

        onExited: function(exitCode, exitStatus) {
            if (exitCode === 0) {
                root.copied(
                    copyPinnedProcess.pendingPreview
                )
            } else {
                root.errorOccurred(
                    "No se pudo copiar el fijado"
                )
            }
        }
    }

    Process {
        id: deleteProcess

        onExited: function(exitCode, exitStatus) {
            if (exitCode === 0)
                refreshTimer.restart()
            else
                root.errorOccurred(
                    "No se pudo eliminar el elemento"
                )
        }
    }

    Process {
        id: wipeProcess

        onExited: function(exitCode, exitStatus) {
            if (exitCode === 0) {
                // Solo borra historial. Los pins permanecen.
                root.entries = []
                root.searchText = ""
            } else {
                root.errorOccurred(
                    "No se pudo limpiar el historial"
                )
            }
        }
    }

    Process {
        id: pinProcess

        property var pendingEntry: null
        property string pendingPath: ""
        property string pendingKey: ""

        onExited: function(exitCode, exitStatus) {
            if (exitCode === 0) {
                root.finishPin()
                root.imageRevision += 1
            } else {
                root.errorOccurred(
                    "No se pudo fijar el elemento"
                )
            }

            pendingEntry = null
            pendingPath = ""
            pendingKey = ""
        }
    }

    Process {
        id: removePinnedFileProcess
    }

    Timer {
        id: refreshTimer

        interval: 180
        repeat: false

        onTriggered: root.refresh()
    }

    Timer {
        interval: 1800
        running: root.pollingEnabled
        repeat: true

        onTriggered: {
            if (!listProcess.running)
                root.refresh()
        }
    }

    Component.onCompleted: {
        initializeProcess.exec([
            "sh",
            "-c",
            "mkdir -p \"$1\" \"$2\" \"$3\"; "
                + "[ -f \"$4\" ] || printf '[]\\n' > \"$4\"",
            "clipboard-initialize",
            root.dataDirectory,
            root.pinnedFilesDirectory,
            root.previewDirectory,
            root.pinsPath
        ])
    }

    onPollingEnabledChanged: {
        if (root.pollingEnabled)
            root.refresh()
    }
}
