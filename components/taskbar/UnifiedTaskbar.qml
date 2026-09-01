import QtQuick
import QtQuick.Layouts

import Quickshell
import Quickshell.Widgets
import Quickshell.Hyprland

Item {
    id: root

    property int iconSize: 18
    property int iconPadding: 5
    property int itemSpacing: 3
    property int workspaceSpacing: 5
    property string monitorName: ""

    implicitWidth: workspaceRow.implicitWidth
    implicitHeight: 28

    // =========================================================
    // INFORMACIÓN DE LAS VENTANAS
    // =========================================================

    function getAppId(windowObject) {
        if (!windowObject)
            return "unknown"

        if (
            windowObject.wayland
            && windowObject.wayland.appId
        ) {
            return windowObject.wayland.appId
        }

        if (windowObject.lastIpcObject) {
            if (windowObject.lastIpcObject.class)
                return windowObject.lastIpcObject.class

            if (windowObject.lastIpcObject.initialClass)
                return windowObject.lastIpcObject.initialClass
        }

        return "unknown"
    }

    function normalizeText(value) {
        if (!value)
            return ""

        return value
            .toString()
            .toLowerCase()
            .replace(".desktop", "")
            .replace(/[^a-z0-9]/g, "")
    }

    function normalizedAppId(windowObject) {
        const appId = getAppId(windowObject)

        if (!appId || appId === "")
            return "unknown"

        return appId.toLowerCase()
    }

    // =========================================================
    // BUSCAR EL ARCHIVO .DESKTOP CORRECTO
    // =========================================================

    function desktopEntryFor(appId) {
        if (!appId || appId === "unknown")
            return null

        let entry = DesktopEntries.heuristicLookup(appId)

        if (entry)
            return entry

        const normalizedId = normalizeText(appId)

        const applications = DesktopEntries.applications
            ? DesktopEntries.applications.values
            : []

        for (let i = 0; i < applications.length; i++) {
            const candidate = applications[i]

            if (!candidate)
                continue

            const candidateId =
                normalizeText(candidate.id)

            const candidateName =
                normalizeText(candidate.name)

            const candidateStartupClass =
                normalizeText(candidate.startupClass)

            if (
                candidateId === normalizedId
                || candidateName === normalizedId
                || candidateStartupClass === normalizedId
            ) {
                return candidate
            }
        }

        for (let j = 0; j < applications.length; j++) {
            const partialCandidate = applications[j]

            if (!partialCandidate)
                continue

            const partialId =
                normalizeText(partialCandidate.id)

            const partialName =
                normalizeText(partialCandidate.name)

            const partialStartup =
                normalizeText(partialCandidate.startupClass)

            if (
                (
                    partialId !== ""
                    && (
                        normalizedId.includes(partialId)
                        || partialId.includes(normalizedId)
                    )
                )
                || (
                    partialName !== ""
                    && (
                        normalizedId.includes(partialName)
                        || partialName.includes(normalizedId)
                    )
                )
                || (
                    partialStartup !== ""
                    && (
                        normalizedId.includes(partialStartup)
                        || partialStartup.includes(normalizedId)
                    )
                )
            ) {
                return partialCandidate
            }
        }

        return null
    }

    function iconForApp(appId) {
        const entry = desktopEntryFor(appId)

        if (!entry || !entry.icon)
            return ""

        return Quickshell.iconPath(
            entry.icon,
            true
        )
    }

    function appName(appId) {
        const entry = desktopEntryFor(appId)

        if (entry && entry.name)
            return entry.name

        if (!appId || appId === "unknown")
            return "?"

        const parts = appId.split(".")

        return parts[parts.length - 1]
    }

    // =========================================================
    // AGRUPAR VENTANAS DEL MISMO PROGRAMA
    // =========================================================

    function groupWindows(windows) {
        const groups = {}

        for (let i = 0; i < windows.length; i++) {
            const windowObject = windows[i]

            if (!windowObject)
                continue

            const appId = normalizedAppId(windowObject)

            if (!groups[appId]) {
                groups[appId] = {
                    key: appId,
                    appId: appId,
                    windows: [],
                    firstWindow: windowObject
                }
            }

            groups[appId].windows.push(windowObject)
        }

        const result = []

        for (const key in groups)
            result.push(groups[key])

        result.sort(function(a, b) {
            return appName(a.appId).localeCompare(
                appName(b.appId)
            )
        })

        return result
    }

    // =========================================================
    // CREAR MODELO DE WORKSPACES OCUPADOS
    // =========================================================

    function buildWorkspaceModel() {
        const workspaceValues =
            Hyprland.workspaces
                ? Array.from(Hyprland.workspaces.values)
                : []

        const toplevelValues =
            Hyprland.toplevels
                ? Array.from(Hyprland.toplevels.values)
                : []

        const focusedWorkspace =
            Hyprland.focusedWorkspace

        void toplevelValues
        void focusedWorkspace

        const result = []

        for (let i = 0; i < workspaceValues.length; i++) {
            const workspace = workspaceValues[i]

            if (!workspace || workspace.id < 1)
                continue

            if (
                root.monitorName !== ""
                && (!workspace.monitor || workspace.monitor.name !== root.monitorName)
            ) {
                continue
            }

            const windows =
                workspace.toplevels
                    ? Array.from(workspace.toplevels.values)
                    : []

            // Solo mostrar workspaces con ventanas.
            if (windows.length === 0)
                continue

            result.push({
                key: "workspace-" + workspace.id,
                workspaceId: workspace.id,
                workspaceName: workspace.name,
                workspaceObject: workspace,

                active:
                    Hyprland.focusedWorkspace !== null
                    && Hyprland.focusedWorkspace.id
                        === workspace.id,

                urgent: workspace.urgent,
                applications: groupWindows(windows)
            })
        }

        result.sort(function(a, b) {
            return a.workspaceId - b.workspaceId
        })

        return result
    }

    // =========================================================
    // ACTIVAR Y CERRAR VENTANAS
    // =========================================================

    function windowIsActive(windowObject) {
        if (!windowObject)
            return false

        if (windowObject.activated)
            return true

        return Boolean(
            windowObject.wayland
            && windowObject.wayland.activated
        )
    }

    function activateWindow(windowObject) {
        if (!windowObject)
            return

        if (
            windowObject.wayland
            && typeof windowObject.wayland.activate === "function"
        ) {
            windowObject.wayland.activate()
            return
        }

        if (
            typeof windowObject.activate === "function"
        ) {
            windowObject.activate()
        }
    }

    function closeWindow(windowObject) {
        if (!windowObject)
            return

        if (
            windowObject.wayland
            && typeof windowObject.wayland.close === "function"
        ) {
            windowObject.wayland.close()
            return
        }

        if (
            typeof windowObject.close === "function"
        ) {
            windowObject.close()
        }
    }

    function activateApplication(group) {
        if (
            !group
            || !group.windows
            || group.windows.length === 0
        ) {
            return
        }

        let activeIndex = -1

        for (let i = 0; i < group.windows.length; i++) {
            if (windowIsActive(group.windows[i])) {
                activeIndex = i
                break
            }
        }

        const nextIndex =
            group.windows.length === 1
                ? 0
                : (activeIndex + 1)
                    % group.windows.length

        activateWindow(group.windows[nextIndex])
    }

    function closeOneWindow(group) {
        if (
            !group
            || !group.windows
            || group.windows.length === 0
        ) {
            return
        }

        closeWindow(
            group.windows[group.windows.length - 1]
        )
    }

    property var groupedWorkspaces: buildWorkspaceModel()

    // =========================================================
    // INTERFAZ
    // =========================================================

    Row {
        id: workspaceRow

        anchors.verticalCenter: parent.verticalCenter
        spacing: root.workspaceSpacing

        Repeater {
            model: ScriptModel {
                values: root.groupedWorkspaces
                objectProp: "key"
            }

            delegate: Rectangle {
                id: workspacePill

                required property var modelData

                property var workspaceData: modelData

                implicitWidth:
                    appsRow.implicitWidth

                implicitHeight: 28
                radius: 10

                color: "transparent"

                border.width: 0

                border.color: {
                    if (workspaceData.urgent)
                        return "#d66d68"

                    if (workspaceData.active)
                        return "#d5a84f"

                    return "transparent"
                }

                Behavior on color {
                    ColorAnimation {
                        duration: 140
                    }
                }

                Behavior on border.color {
                    ColorAnimation {
                        duration: 140
                    }
                }

                Row {
                    id: appsRow

                    anchors.centerIn: parent
                    spacing: root.itemSpacing

                    Repeater {
                        model: ScriptModel {
                            values:
                                workspaceData.applications
                                    ? workspaceData.applications
                                    : []

                            objectProp: "key"
                        }

                        delegate: Item {
                            id: appItem

                            required property var modelData

                            property var appGroup: modelData

                            property int windowCount:
                                appGroup.windows.length

                            property string resolvedIcon:
                                root.iconForApp(
                                    appGroup.appId
                                )

                            property bool focused: {
                                for (
                                    let i = 0;
                                    i < appGroup.windows.length;
                                    i++
                                ) {
                                    if (
                                        root.windowIsActive(
                                            appGroup.windows[i]
                                        )
                                    ) {
                                        return true
                                    }
                                }

                                return false
                            }

                            width:
                                root.iconSize
                                + root.iconPadding * 2

                            height: 24

                            Rectangle {
                                anchors.fill: parent
                                radius: 8
                                visible: false
                                color: "transparent"

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 120
                                    }
                                }
                            }

                            IconImage {
                                id: applicationIcon

                                anchors.centerIn: parent

                                width: root.iconSize
                                height: root.iconSize

                                source:
                                    appItem.resolvedIcon

                                asynchronous: true
                                smooth: true
                                mipmap: true

                                visible:
                                    appItem.resolvedIcon !== ""
                                    && status === Image.Ready

                                onStatusChanged: {
                                    if (
                                        status === Image.Error
                                        && source !== ""
                                    ) {
                                        console.log(
                                            "No se pudo cargar icono:",
                                            appItem.appGroup.appId,
                                            source
                                        )
                                    }
                                }
                            }

                            Text {
                                anchors.centerIn:
                                    applicationIcon

                                visible:
                                    !applicationIcon.visible

                                text: {
                                    const name =
                                        root.appName(
                                            appItem.appGroup.appId
                                        )

                                    return name.length > 0
                                        ? name
                                            .charAt(0)
                                            .toUpperCase()
                                        : "?"
                                }

                                color: "#ece8dc"
                                font.pixelSize: 11
                                font.bold: true
                            }

                            Rectangle {
                                anchors {
                                    horizontalCenter: parent.horizontalCenter
                                    bottom: parent.bottom
                                }
                                width: appItem.focused ? 12 : 4
                                height: 2
                                radius: 1
                                color: appItem.focused
                                    ? "#d5a84f"
                                    : workspaceData.urgent
                                        ? "#d66d68"
                                        : "#65675f"
                                opacity: appItem.focused
                                    || workspaceData.urgent
                                        ? 1
                                        : 0

                                Behavior on width {
                                    NumberAnimation {
                                        duration: 150
                                        easing.type: Easing.OutCubic
                                    }
                                }
                            }

                            MouseArea {
                                id: appMouse

                                anchors.fill: parent
                                hoverEnabled: true

                                acceptedButtons:
                                    Qt.LeftButton
                                    | Qt.MiddleButton

                                cursorShape:
                                    Qt.PointingHandCursor

                                onClicked: function(mouse) {
                                    mouse.accepted = true

                                    if (
                                        mouse.button
                                        === Qt.LeftButton
                                    ) {
                                        root.activateApplication(
                                            appItem.appGroup
                                        )
                                    } else if (
                                        mouse.button
                                        === Qt.MiddleButton
                                    ) {
                                        root.closeOneWindow(
                                            appItem.appGroup
                                        )
                                    }
                                }
                            }
                        }
                    }
                }

                MouseArea {
                    id: workspaceMouse

                    anchors.fill: parent
                    z: -1

                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton
                    cursorShape: Qt.PointingHandCursor

                    onClicked: {
                        if (
                            workspacePill.workspaceData
                            && workspacePill
                                .workspaceData
                                .workspaceObject
                        ) {
                            Hyprland.dispatch(
                                "workspace "
                                + workspacePill
                                    .workspaceData
                                    .workspaceId
                            )
                        }
                    }
                }
            }
        }
    }

    // =========================================================
    // ACTUALIZACIONES
    // =========================================================

    Connections {
        target: Hyprland

        function refreshModel() {
            root.groupedWorkspaces =
                root.buildWorkspaceModel()
        }

        function onRawEvent(event) {
            refreshTimer.restart()
        }

        function onFocusedWorkspaceChanged() {
            refreshTimer.restart()
        }

        function onActiveToplevelChanged() {
            refreshTimer.restart()
        }
    }

    Timer {
        id: refreshTimer

        interval: 80
        repeat: false

        onTriggered: {
            Hyprland.refreshWorkspaces()
            Hyprland.refreshToplevels()

            root.groupedWorkspaces =
                root.buildWorkspaceModel()
        }
    }

    Component.onCompleted: {
        Hyprland.refreshWorkspaces()
        Hyprland.refreshToplevels()

        refreshTimer.start()
    }
}
