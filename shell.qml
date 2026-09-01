import QtQuick
import QtQuick.Layouts

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

import "components/audio"
import "components/battery"
import "components/bluetooth"
import "components/brightness"
import "components/calendar"
import "components/clipboard"
import "components/controlcenter"
import "components/disk"
import "components/docker"
import "components/hermes"
import "components/launcher"
import "components/keyboards"
import "components/media"
import "components/monitors"
import "components/network"
import "components/notifications"
import "components/power"
import "components/ssh"
import "components/shared"
import "components/taskbar"
import "components/tailscale"

ShellRoot {
    id: root
    property var activeScreen: null
    readonly property var networkServiceObject: networkService
    readonly property var systemServiceObject: systemService
    readonly property var tailscaleServiceObject: tailscaleService

    function lazyOpened(loader) {
        return loader && loader.item
            ? loader.item.opened
            : false
    }

    function openLazyPanel(loader) {
        if (!loader)
            return

        loader.active = true

        // Loading is synchronous by default, but keep onLoaded on each Loader
        // as a fallback if that changes later.
        if (loader.item && !loader.item.opened)
            loader.item.open()
    }

    function closeLazyPanel(loader) {
        if (!loader || !loader.active)
            return

        if (loader.item && loader.item.opened)
            loader.item.close()

        if (loader.unloadOnClose !== false)
            loader.active = false
    }

    function toggleLazyPanel(loader) {
        if (root.lazyOpened(loader))
            root.closeLazyPanel(loader)
        else
            root.openLazyPanel(loader)
    }

    // =========================================================
    // LANZADOR DE APLICACIONES
    // =========================================================

    LazyPanelLoader {
        id: appLauncherLoader
        property var panelScreen: root.activeScreen
        sourceComponent: Component {
            AppLauncher {
                targetScreen: appLauncherLoader.panelScreen
            }
        }
    }

    // =========================================================
    // NOTIFICACIONES
    // =========================================================

    NotificationService {
        id: notificationService
    }

    LazyPanelLoader {
        id: notificationCenterLoader
        property var panelScreen: root.activeScreen
        sourceComponent: Component {
            NotificationCenter {
                service: notificationService
                targetScreen: notificationCenterLoader.panelScreen
            }
        }
    }

    NotificationPopup {
        id: notificationPopup
        service: notificationService
    }

    // =========================================================
    // PORTAPAPELES
    // =========================================================

    ClipboardService {
        id: clipboardService
        pollingEnabled:
            root.lazyOpened(controlCenterLoader)
            || root.lazyOpened(clipboardPanelLoader)
    }

    LazyPanelLoader {
        id: clipboardPanelLoader
        property var panelScreen: root.activeScreen
        sourceComponent: Component {
            ClipboardPanel {
                service: clipboardService
                targetScreen: clipboardPanelLoader.panelScreen
            }
        }
    }

    // =========================================================
    // RED
    // =========================================================

    NetworkService {
        id: networkService
        detailedPollingEnabled:
            root.lazyOpened(controlCenterLoader)
            || root.lazyOpened(networkPanelLoader)
    }

    TailscaleService {
        id: tailscaleService
    }

    LazyPanelLoader {
        id: networkPanelLoader
        property var panelScreen: root.activeScreen
        sourceComponent: Component {
            NetworkPanel {
                service: networkService
                targetScreen: networkPanelLoader.panelScreen
            }
        }
    }

    /// =========================================================
    // DOCKER
    // =========================================================

    DockerService {
        id: dockerService
        pollingEnabled:
            root.lazyOpened(controlCenterLoader)
            || root.lazyOpened(dockerPanelLoader)
    }

    DockerDatabaseService {
        id: dockerDatabaseService

        dockerBinary: "docker"
        pollingEnabled: root.lazyOpened(dockerPanelLoader)
    }

    DockerInfraService {
        id: dockerInfraService

        dockerBinary: "docker"
    }

    LazyPanelLoader {
        id: dockerPanelLoader
        property var panelScreen: root.activeScreen
        sourceComponent: Component {
            DockerPanel {
                service: dockerService
                databaseService: dockerDatabaseService
                infraService: dockerInfraService
                targetScreen: dockerPanelLoader.panelScreen
            }
        }
    }

    // =========================================================
    // BRILLO
    // =========================================================

    BrightnessService {
        id: brightnessService
    }

    LazyPanelLoader {
        id: brightnessPanelLoader
        property var panelScreen: root.activeScreen
        sourceComponent: Component {
            BrightnessPanel {
                service: brightnessService
                targetScreen: brightnessPanelLoader.panelScreen
            }
        }
    }

    // =========================================================
    // DISCOS
    // =========================================================

    DiskService {
        id: diskService

        refreshInterval: 30
        warningThreshold: 80
        criticalThreshold: 95
    }

    LazyPanelLoader {
        id: diskPanelLoader
        property var panelScreen: root.activeScreen
        sourceComponent: Component {
            DiskPanel {
                service: diskService
                targetScreen: diskPanelLoader.panelScreen
            }
        }
    }

    // =========================================================
    // AUDIO
    // =========================================================

    LazyPanelLoader {
        id: audioPanelLoader
        property var panelScreen: root.activeScreen
        sourceComponent: Component {
            AudioPanel {
                targetScreen: audioPanelLoader.panelScreen
            }
        }
    }

    // =========================================================
    // REPRODUCTOR MULTIMEDIA
    // =========================================================

    MediaService {
        id: mediaService
    }

    LazyPanelLoader {
        id: mediaPanelLoader
        property var panelScreen: root.activeScreen
        sourceComponent: Component {
            MediaPanel {
                service: mediaService
                targetScreen: mediaPanelLoader.panelScreen
            }
        }
    }

    // =========================================================
    // BLUETOOTH
    // =========================================================

    BluetoothService {
        id: bluetoothService
    }

    LazyPanelLoader {
        id: bluetoothPanelLoader
        property var panelScreen: root.activeScreen
        sourceComponent: Component {
            BluetoothPanel {
                service: bluetoothService
                targetScreen: bluetoothPanelLoader.panelScreen
            }
        }
    }

    // =========================================================
    // MENÚ DE ENERGÍA
    // =========================================================

    LazyPanelLoader {
        id: powerMenuLoader
        property var panelScreen: root.activeScreen
        sourceComponent: Component {
            PowerMenu {
                targetScreen: powerMenuLoader.panelScreen
            }
        }
    }

    // =========================================================
    // SSH
    // =========================================================

    SSHService {
        id: sshService
    }

    LazyPanelLoader {
        id: sshPanelLoader
        property var panelScreen: root.activeScreen
        sourceComponent: Component {
            SSHPanel {
                service: sshService
                targetScreen: sshPanelLoader.panelScreen
            }
        }
    }

    // =========================================================
    // HERMES AGENT (CONTROL MANUAL, SIN AUTOINICIO)
    // =========================================================

    HermesService {
        id: hermesService
    }

    // =========================================================
    // CALENDARIO Y CENTRO DE CONTROL
    // =========================================================

    LazyPanelLoader {
        id: calendarPanelLoader
        property var panelScreen: root.activeScreen
        sourceComponent: Component {
            CalendarPanel {
                targetScreen: calendarPanelLoader.panelScreen
            }
        }
    }

    MonitorService {
        id: monitorService
        brightnessService: brightnessService
        pollingEnabled: !root.lazyOpened(monitorPanelLoader)
    }
    Connections {
        target: monitorService
        function onTopologyChanged() {
            root.closeOverlaysExcept(null)
            root.activeScreen = null
        }
    }
    MonitorLayers { service: monitorService }
    LazyPanelLoader {
        id: monitorPanelLoader
        property var panelScreen: root.activeScreen
        sourceComponent: Component {
            MonitorPanel {
                service: monitorService
                targetScreen: monitorPanelLoader.panelScreen
            }
        }
    }

    KeyboardService {
        id: keyboardService
        lightingPollingEnabled: root.lazyOpened(keyboardPanelLoader)
    }
    LazyPanelLoader {
        id: keyboardPanelLoader
        property var panelScreen: root.activeScreen
        sourceComponent: Component {
            KeyboardPanel {
                service: keyboardService
                targetScreen: keyboardPanelLoader.panelScreen
            }
        }
    }

    SystemService {
        id: systemService
        pollingEnabled: root.lazyOpened(controlCenterLoader)
    }

    LazyPanelLoader {
        id: controlCenterLoader
        unloadOnClose: false
        property var panelScreen: root.activeScreen
        property var systemServiceRef: systemService
        property var networkServiceRef: networkService
        property var bluetoothServiceRef: bluetoothService
        property var dockerServiceRef: dockerService
        property var brightnessServiceRef: brightnessService
        property var clipboardServiceRef: clipboardService
        property var diskServiceRef: diskService
        property var notificationServiceRef: notificationService
        property var sshServiceRef: sshService
        property var keyboardServiceRef: keyboardService
        property var hermesServiceRef: hermesService
        property var tailscaleServiceRef: tailscaleService
        sourceComponent: Component {
            ControlCenter {
                targetScreen: controlCenterLoader.panelScreen
                systemService: controlCenterLoader.systemServiceRef
                networkService: controlCenterLoader.networkServiceRef
                bluetoothService: controlCenterLoader.bluetoothServiceRef
                dockerService: controlCenterLoader.dockerServiceRef
                brightnessService: controlCenterLoader.brightnessServiceRef
                clipboardService: controlCenterLoader.clipboardServiceRef
                diskService: controlCenterLoader.diskServiceRef
                notificationService: controlCenterLoader.notificationServiceRef
                sshService: controlCenterLoader.sshServiceRef
                keyboardService: controlCenterLoader.keyboardServiceRef
                hermesService: controlCenterLoader.hermesServiceRef
                tailscaleService: controlCenterLoader.tailscaleServiceRef

                onToolRequested: function(tool) {
                    root.openTool(tool)
                }
            }
        }
    }

    // =========================================================
    // FUNCIONES PARA CERRAR PANELES
    // =========================================================

    function closeOverlaysExcept(exception) {
        const lazyLoaders = [
            appLauncherLoader,
            networkPanelLoader,
            dockerPanelLoader,
            brightnessPanelLoader,
            clipboardPanelLoader,
            audioPanelLoader,
            mediaPanelLoader,
            bluetoothPanelLoader,
            diskPanelLoader,
            notificationCenterLoader,
            powerMenuLoader,
            monitorPanelLoader,
            keyboardPanelLoader,
            sshPanelLoader,
            calendarPanelLoader,
            controlCenterLoader
        ]

        for (let j = 0; j < lazyLoaders.length; j++) {
            const loader = lazyLoaders[j]

            if (loader !== exception)
                root.closeLazyPanel(loader)
        }
    }

    function openTool(tool) {
        root.closeLazyPanel(controlCenterLoader)

        const lazyPanels = {
            network: networkPanelLoader,
            bluetooth: bluetoothPanelLoader,
            docker: dockerPanelLoader,
            brightness: brightnessPanelLoader,
            clipboard: clipboardPanelLoader,
            audio: audioPanelLoader,
            disk: diskPanelLoader,
            notifications: notificationCenterLoader,
            power: powerMenuLoader,
            monitors: monitorPanelLoader,
            keyboards: keyboardPanelLoader,
            ssh: sshPanelLoader
        }

        const lazyTarget = lazyPanels[tool]
        if (lazyTarget) {
            root.closeOverlaysExcept(lazyTarget)
            root.openLazyPanel(lazyTarget)
            return
        }

    }

    function openControlTab(tab) {
        root.closeOverlaysExcept(controlCenterLoader)
        root.openLazyPanel(controlCenterLoader)

        if (controlCenterLoader.item)
            controlCenterLoader.item.activeTab = tab
    }

    IpcHandler {
        target: "minibarTools"
        function closeAll(): void { root.closeOverlaysExcept(null) }
        function network(): void { root.openTool("network") }
        function bluetooth(): void { root.openTool("bluetooth") }
        function docker(): void { root.openTool("docker") }
        function brightness(): void { root.openTool("brightness") }
        function clipboard(): void { root.openTool("clipboard") }
        function audio(): void { root.openTool("audio") }
        function disk(): void { root.openTool("disk") }
        function notifications(): void { root.openTool("notifications") }
        function ssh(): void { root.openTool("ssh") }
        function power(): void { root.openTool("power") }
        function monitors(): void { root.openTool("monitors") }
        function keyboards(): void { root.openTool("keyboards") }
    }

    IpcHandler {
        target: "minibarLauncher"
        function open(): void {
            root.closeOverlaysExcept(appLauncherLoader)
            root.openLazyPanel(appLauncherLoader)
        }
        function close(): void { root.closeLazyPanel(appLauncherLoader) }
        function toggle(): void {
            root.closeOverlaysExcept(appLauncherLoader)
            root.toggleLazyPanel(appLauncherLoader)
        }
    }

    IpcHandler {
        target: "minibarCalendar"
        function open(): void {
            root.closeOverlaysExcept(calendarPanelLoader)
            root.openLazyPanel(calendarPanelLoader)
        }
        function close(): void { root.closeLazyPanel(calendarPanelLoader) }
        function toggle(): void {
            root.closeOverlaysExcept(calendarPanelLoader)
            root.toggleLazyPanel(calendarPanelLoader)
        }
    }

    IpcHandler {
        target: "minibarControl"
        function open(): void { root.openControlTab(0) }
        function close(): void { root.closeLazyPanel(controlCenterLoader) }
        function toggle(): void {
            if (root.lazyOpened(controlCenterLoader))
                root.closeLazyPanel(controlCenterLoader)
            else
                root.openControlTab(0)
        }
        function processes(): void { root.openControlTab(1) }
        function wallpapers(): void { root.openControlTab(2) }
    }

    IpcHandler {
        target: "minibarSsh"
        function open(): void { root.openTool("ssh") }
        function close(): void { root.closeLazyPanel(sshPanelLoader) }
        function toggle(): void {
            root.closeOverlaysExcept(sshPanelLoader)
            root.toggleLazyPanel(sshPanelLoader)
        }
        function newKey(): void {
            root.openTool("ssh")
            if (sshPanelLoader.item)
                sshPanelLoader.item.openKeyEditor(false)
        }
        function newProfile(): void {
            root.openTool("ssh")
            if (sshPanelLoader.item)
                sshPanelLoader.item.openProfileEditor()
        }
        function newTunnel(): void {
            root.openTool("ssh")
            if (sshPanelLoader.item)
                sshPanelLoader.item.openTunnelEditor()
        }
    }

    // =========================================================
    // BARRA PRINCIPAL
    // =========================================================

    Variants {
        model: Quickshell.screens

        PanelWindow {
        id: bar
        required property var modelData
        readonly property var hyprMonitor: Hyprland.monitorFor(bar.screen)
        screen: modelData

        anchors {
            top: true
            left: true
            right: true
        }

        implicitHeight: 48
        exclusiveZone: implicitHeight

        color: "transparent"

        Rectangle {
            anchors {
                fill: parent

                leftMargin: 9
                rightMargin: 9
                topMargin: 7
                bottomMargin: 5
            }

            radius: 11
            color: "transparent"

            border.width: 0
            border.color: "transparent"

            Rectangle {
                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                    leftMargin: 14
                    rightMargin: 14
                }

                height: 0
                visible: false
                color: "#302f2a"
            }

            // =================================================
            // LADO IZQUIERDO
            // =================================================

            RowLayout {
                anchors {
                    left: parent.left
                    leftMargin: 8
                    verticalCenter: parent.verticalCenter
                }

                spacing: 7

                LauncherButton {
                    launcherOpen: root.lazyOpened(appLauncherLoader)

                    onClicked: {
                        root.activeScreen = bar.screen
                        root.closeOverlaysExcept(appLauncherLoader)
                        root.toggleLazyPanel(appLauncherLoader)
                    }
                }

                UnifiedTaskbar {
                    monitorName: bar.hyprMonitor ? bar.hyprMonitor.name : ""
                    iconSize: 18
                    iconPadding: 4
                    itemSpacing: 7
                    workspaceSpacing: 8
                }
            }

            // =================================================
            // CENTRO: RELOJ + REPRODUCTOR
            // =================================================

            Row {
                anchors.centerIn: parent
                spacing: 7

                CalendarButton {
                    panelOpen: root.lazyOpened(calendarPanelLoader)

                    onClicked: {
                        root.activeScreen = bar.screen
                        root.closeOverlaysExcept(calendarPanelLoader)
                        root.toggleLazyPanel(calendarPanelLoader)
                    }
                }

                MediaButton {
                    service: mediaService
                    panelOpen: root.lazyOpened(mediaPanelLoader)

                    onClicked: {
                        root.activeScreen = bar.screen
                        root.closeOverlaysExcept(mediaPanelLoader)
                        root.toggleLazyPanel(mediaPanelLoader)
                    }
                }
            }

            // =================================================
            // LADO DERECHO
            // =================================================

            RowLayout {
                anchors {
                    right: parent.right
                    rightMargin: 9
                    verticalCenter: parent.verticalCenter
                }

                ControlCenterButton {
                    networkService: root.networkServiceObject
                    systemService: root.systemServiceObject
                    panelOpen: root.lazyOpened(controlCenterLoader)
                    unreadCount: notificationService.unreadCount

                    onClicked: {
                        root.activeScreen = bar.screen
                        root.closeOverlaysExcept(controlCenterLoader)
                        root.toggleLazyPanel(controlCenterLoader)
                    }
                }

                TailscaleButton {
                    service: root.tailscaleServiceObject
                }
            }
        }
    }
    }
}
