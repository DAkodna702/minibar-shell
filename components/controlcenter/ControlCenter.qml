import QtQuick
import QtQuick.Layouts

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower

Item {
    id: root
    property var targetScreen: null

    required property var systemService
    required property var networkService
    required property var bluetoothService
    required property var dockerService
    required property var brightnessService
    required property var clipboardService
    required property var diskService
    required property var notificationService
    required property var sshService
    required property var keyboardService
    required property var hermesService
    required property var tailscaleService

    readonly property bool opened: controlWindow.visible
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property int volume: sink && sink.audio ? Math.round(sink.audio.volume * 100) : 0
    readonly property int battery: UPower.displayDevice.ready ? Math.round(UPower.displayDevice.percentage * 100) : 0

    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }

    property int activeTab: 0
    property int confirmPid: -1
    property var expandedProcessGroups: ({})

    signal toolRequested(string tool)

    readonly property var tools: [
        { id: "network", icon: "󰤨", title: "Red" },
        { id: "bluetooth", icon: "󰂯", title: "Bluetooth" },
        { id: "docker", icon: "󰡨", title: "Docker" },
        { id: "brightness", icon: "󰃠", title: "Brillo" },
        { id: "clipboard", icon: "󰅇", title: "Portapapeles" },
        { id: "audio", icon: "󰕾", title: "Audio" },
        { id: "disk", icon: "󰋊", title: "Discos" },
        { id: "notifications", icon: "󰂚", title: "Avisos" },
        { id: "ssh", icon: "󰣀", title: "SSH" },
        { id: "hermes", icon: "󰚩", title: "Hermes" },
        { id: "tailscale", icon: "󰒄", title: "Tailscale" },
        { id: "monitors", icon: "󰍹", title: "Monitores" },
        { id: "keyboards", icon: "󰌌", title: "Teclados" },
        { id: "power", icon: "󰐥", title: "Energía" }
    ]

    function open() { controlWindow.visible = true }
    function close() { controlWindow.visible = false; root.confirmPid = -1 }
    function toggle() { opened ? close() : open() }

    function toolStatus(id) {
        switch (id) {
        case "network":
            return root.networkService.connectionName || "Sin conexión"
        case "bluetooth":
            return root.bluetoothService.enabled
                ? (root.bluetoothService.connectedCount + " conectado(s)")
                : "Apagado"
        case "docker":
            return root.dockerService.runningCount + " ejecutando"
        case "brightness":
            return root.brightnessService.available
                ? root.brightnessService.primaryBrightness + "%"
                : "No disponible"
        case "clipboard":
            return root.clipboardService.count + " elementos"
        case "audio":
            return root.volume + "%"
        case "disk":
            return root.diskService.primaryUsagePercent + "% usado"
        case "notifications":
            return root.notificationService.unreadCount + " sin leer"
        case "ssh":
            return root.sshService.activeTunnelIds.length + " túneles"
        case "hermes":
            return root.hermesService.summary
        case "tailscale":
            return root.tailscaleService.summary
        case "monitors":
            return "Distribución y Hz"
        case "keyboards":
            return root.keyboardService.summary
        case "power":
            return "Sesión"
        }
        return ""
    }

    function fileName(path) {
        const parts = String(path).split("/")
        return parts[parts.length - 1]
    }

    function formatBytes(bytes) {
        const value = Number(bytes) || 0
        if (value >= 1073741824)
            return (value / 1073741824).toFixed(1) + " GB"
        if (value >= 1048576)
            return Math.round(value / 1048576) + " MB"
        return Math.round(value / 1024) + " KB"
    }

    function processGroupExpanded(key) {
        return root.expandedProcessGroups[key] === true
    }

    function toggleProcessGroup(key) {
        const next = Object.assign({}, root.expandedProcessGroups)
        next[key] = next[key] !== true
        root.expandedProcessGroups = next
        root.confirmPid = -1
    }

    Timer {
        id: confirmReset
        interval: 3000
        onTriggered: root.confirmPid = -1
    }

    PanelWindow {
        id: controlWindow
        screen: root.targetScreen
        visible: false
        color: "transparent"
        anchors { top: true; bottom: true; left: true; right: true }
        WlrLayershell.namespace: "minibar-control-center"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.exclusiveZone: -1
        WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        Rectangle {
            anchors.fill: parent
            color: "#66050605"
            MouseArea { anchors.fill: parent; onClicked: root.close() }
        }

        Rectangle {
            id: card
            anchors { top: parent.top; right: parent.right; topMargin: 52; rightMargin: 10; bottomMargin: 10 }
            width: Math.min(560, parent.width - 20)
            height: Math.min(730, parent.height - 62)
            radius: 18
            color: "#f70b0c0a"
            border.width: 1
            border.color: "#4a4b42"
            clip: true

            MouseArea { anchors.fill: parent }
            Rectangle {
                anchors { top: parent.top; left: parent.left; right: parent.right }
                height: 3
                color: "#d5a84f"
            }

            ColumnLayout {
                anchors { fill: parent; margins: 16 }
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Text { text: "CONTROL CENTER"; color: "#ece8dc"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 14; font.weight: Font.DemiBold; font.letterSpacing: 1.8 }
                        Text { text: "SISTEMA · HERRAMIENTAS · FONDOS"; color: "#696b63"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 8; font.letterSpacing: 1.1 }
                    }
                    Text {
                        text: "×"; color: closeMouse.containsMouse ? "#d5a84f" : "#aaa89d"; font.pixelSize: 20
                        MouseArea { id: closeMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.close() }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    Repeater {
                        model: ["RESUMEN", "PROCESOS", "FONDOS"]
                        Rectangle {
                            required property int index
                            required property string modelData
                            Layout.fillWidth: true
                            Layout.preferredHeight: 34
                            radius: 9
                            color: root.activeTab === index ? "#d5a84f" : tabMouse.containsMouse ? "#24251f" : "#151612"
                            border.width: root.activeTab === index ? 0 : 1
                            border.color: "#34362f"
                            Text { anchors.centerIn: parent; text: modelData; color: root.activeTab === index ? "#0b0c09" : "#aaa89d"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 9; font.weight: Font.DemiBold; font.letterSpacing: 1 }
                            MouseArea { id: tabMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { root.activeTab = index; if (index === 2) root.systemService.refreshWallpapers() } }
                        }
                    }
                }

                StackLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    currentIndex: root.activeTab

                    Flickable {
                        id: overviewScroll
                        clip: true
                        contentHeight: overviewColumn.implicitHeight
                        boundsBehavior: Flickable.StopAtBounds

                        ColumnLayout {
                            id: overviewColumn
                            width: overviewScroll.width
                            spacing: 12

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8
                                Repeater {
                                    model: [
                                        { icon: "󰍛", label: "CPU", value: root.systemService.cpuUsage },
                                        { icon: "󰢮", label: "GPU", value: root.systemService.gpuUsage },
                                        { icon: "󰘚", label: "RAM", value: root.systemService.ramUsage }
                                    ]
                                    Rectangle {
                                        required property var modelData
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 104
                                        radius: 13
                                        color: "#151612"
                                        border.width: 1
                                        border.color: "#34362f"
                                        Column {
                                            anchors { fill: parent; margins: 12 }
                                            spacing: 7
                                            Row {
                                                spacing: 7
                                                Text { text: modelData.icon; color: "#d5a84f"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 14 }
                                                Text { text: modelData.label; color: "#8f9086"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 9; font.letterSpacing: 1 }
                                            }
                                            Text { text: Math.round(modelData.value) + "%"; color: "#ece8dc"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 22; font.weight: Font.Light }
                                            Rectangle {
                                                width: parent.width; height: 4; radius: 2; color: "#2b2c27"
                                                Rectangle { width: parent.width * Math.min(1, modelData.value / 100); height: parent.height; radius: 2; color: modelData.value >= 90 ? "#d66d68" : modelData.value >= 70 ? "#d5a84f" : "#8fa18c"; Behavior on width { NumberAnimation { duration: 300 } } }
                                            }
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true; Layout.preferredHeight: 58; radius: 12; color: "#11120f"; border.width: 1; border.color: "#2e302a"
                                Column {
                                    anchors { fill: parent; margins: 10 }
                                    spacing: 3
                                    Text { width: parent.width; text: root.systemService.cpuName; color: "#aaa89d"; elide: Text.ElideRight; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 9 }
                                    Text { width: parent.width; text: root.systemService.gpuName; color: "#696b63"; elide: Text.ElideRight; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 8 }
                                }
                            }

                            Text { text: "HERRAMIENTAS"; color: "#73756c"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 9; font.letterSpacing: 1.4 }

                            GridLayout {
                                Layout.fillWidth: true
                                columns: 5
                                columnSpacing: 7
                                rowSpacing: 7
                                Repeater {
                                    model: root.tools
                                    Rectangle {
                                        required property var modelData
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 78
                                        radius: 12
                                        color: modelData.id === "hermes" && root.hermesService.active
                                            ? (toolMouse.containsMouse ? "#263025" : "#1d271d")
                                            : modelData.id === "tailscale" && root.tailscaleService.connected
                                                ? (toolMouse.containsMouse ? "#263025" : "#1d271d")
                                            : toolMouse.containsMouse ? "#25261f" : "#151612"
                                        border.width: 1
                                        border.color: modelData.id === "hermes" && root.hermesService.active
                                            ? "#668165"
                                            : modelData.id === "tailscale" && root.tailscaleService.connected
                                                ? "#668165"
                                            : toolMouse.containsMouse ? "#6a6045" : "#34362f"
                                        Column { anchors.centerIn: parent; width: parent.width - 10; spacing: 4
                                            Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.icon; color: modelData.id === "power" ? "#d66d68" : ((modelData.id === "hermes" && root.hermesService.active) || (modelData.id === "tailscale" && root.tailscaleService.connected)) ? "#91ad8f" : "#d5a84f"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 18 }
                                            Text { width: parent.width; text: modelData.title; color: "#d7d3c7"; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 9; font.weight: Font.Medium }
                                            Text { width: parent.width; text: root.toolStatus(modelData.id); color: "#66685f"; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 7 }
                                        }
                                        MouseArea {
                                            id: toolMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (modelData.id === "hermes")
                                                    root.hermesService.toggle()
                                                else if (modelData.id === "tailscale")
                                                    root.tailscaleService.toggle()
                                                else
                                                    root.toolRequested(modelData.id)
                                            }
                                        }
                                    }
                                }
                            }

                            Item { Layout.preferredHeight: 4 }
                        }
                    }

                    ColumnLayout {
                        spacing: 8
                        RowLayout {
                            Layout.fillWidth: true
                            Text { Layout.fillWidth: true; text: "APLICACIONES Y SERVICIOS"; color: "#73756c"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 9; font.letterSpacing: 1.3 }
                            Text { text: root.systemService.processGroups.length + " grupos · " + root.systemService.processCount + " procesos"; color: "#65675f"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 8 }
                        }
                        Rectangle {
                            Layout.fillWidth: true; Layout.preferredHeight: 28; radius: 8; color: "#151612"
                            RowLayout { anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                                Item { Layout.preferredWidth: 18 }
                                Text { Layout.fillWidth: true; text: "APLICACIÓN"; color: "#65675f"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 8 }
                                Text { Layout.preferredWidth: 52; text: "PROCS"; color: "#65675f"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 8; horizontalAlignment: Text.AlignRight }
                                Text { Layout.preferredWidth: 42; text: "CPU"; color: "#65675f"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 8 }
                                Text { Layout.preferredWidth: 72; text: "RAM TOTAL"; color: "#65675f"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 8; horizontalAlignment: Text.AlignRight }
                            }
                        }
                        ListView {
                            Layout.fillWidth: true; Layout.fillHeight: true
                            clip: true; spacing: 4; model: root.systemService.processGroups
                            delegate: Item {
                                id: processGroup
                                required property var modelData
                                readonly property bool expanded: root.processGroupExpanded(modelData.key)
                                width: ListView.view.width
                                height: groupHeader.height + (expanded ? processChildren.implicitHeight + 4 : 0)

                                Rectangle {
                                    id: groupHeader
                                    width: parent.width; height: 44; radius: 9
                                    color: groupMouse.containsMouse ? "#20211c" : "#11120f"
                                    border.width: 1; border.color: processGroup.expanded ? "#5b543d" : "#2b2c27"

                                    RowLayout { anchors { fill: parent; leftMargin: 10; rightMargin: 10 } spacing: 6
                                        Text { Layout.preferredWidth: 18; text: processGroup.expanded ? "󰅀" : "󰅂"; color: "#d5a84f"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11 }
                                        ColumnLayout {
                                            Layout.fillWidth: true; spacing: 0
                                            Text { Layout.fillWidth: true; text: processGroup.modelData.name; color: "#e0dccf"; elide: Text.ElideRight; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10; font.weight: Font.DemiBold }
                                            Text { Layout.fillWidth: true; text: "PID raíz " + processGroup.modelData.rootPid; color: "#66685f"; elide: Text.ElideRight; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 7 }
                                        }
                                        Text { Layout.preferredWidth: 52; text: processGroup.modelData.count; color: "#8f9086"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 9; horizontalAlignment: Text.AlignRight }
                                        Text { Layout.preferredWidth: 42; text: processGroup.modelData.cpu.toFixed(1) + "%"; color: processGroup.modelData.cpu >= 50 ? "#d5a84f" : "#85877d"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 8; horizontalAlignment: Text.AlignRight }
                                        Text { Layout.preferredWidth: 72; text: root.formatBytes(processGroup.modelData.memoryBytes); color: processGroup.modelData.memory >= 20 ? "#d5a84f" : "#9a9c91"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 8; horizontalAlignment: Text.AlignRight }
                                    }
                                    MouseArea { id: groupMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.toggleProcessGroup(processGroup.modelData.key) }
                                }

                                Column {
                                    id: processChildren
                                    y: groupHeader.height + 4
                                    width: parent.width
                                    visible: processGroup.expanded
                                    spacing: 3

                                    Repeater {
                                        model: processGroup.expanded ? processGroup.modelData.processes : []
                                        Rectangle {
                                            id: processRow
                                            required property var modelData
                                            width: processChildren.width; height: 32; radius: 8
                                            color: childMouse.containsMouse ? "#1c1d19" : "#0e0f0d"
                                            border.width: 1; border.color: "#262720"

                                            RowLayout { anchors { fill: parent; leftMargin: 12; rightMargin: 7 } spacing: 6
                                                Item { Layout.preferredWidth: 16 }
                                                Text { Layout.preferredWidth: 46; text: processRow.modelData.pid; color: "#777970"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 8 }
                                                ColumnLayout {
                                                    Layout.fillWidth: true; spacing: 0
                                                    Text { Layout.fillWidth: true; text: processRow.modelData.name; color: "#b9b6aa"; elide: Text.ElideRight; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 8 }
                                                    Text { Layout.fillWidth: true; text: processRow.modelData.detail + " · PPID " + processRow.modelData.ppid; color: "#55574f"; elide: Text.ElideRight; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 6 }
                                                }
                                                Text { Layout.preferredWidth: 42; text: processRow.modelData.cpu.toFixed(1) + "%"; color: "#777970"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 7; horizontalAlignment: Text.AlignRight }
                                                Text { Layout.preferredWidth: 62; text: root.formatBytes(processRow.modelData.memoryBytes); color: "#777970"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 7; horizontalAlignment: Text.AlignRight }
                                                Rectangle {
                                                    Layout.preferredWidth: 68; Layout.preferredHeight: 23; radius: 7
                                                    color: root.confirmPid === processRow.modelData.pid ? "#d66d68" : killMouse.containsMouse ? "#3a2523" : "#1d1e19"
                                                    border.width: 1; border.color: root.confirmPid === processRow.modelData.pid ? "#e18a84" : "#3a3b34"
                                                    Text { anchors.centerIn: parent; text: root.confirmPid === processRow.modelData.pid ? "CONFIRMAR" : "TERMINAR"; color: root.confirmPid === processRow.modelData.pid ? "#0b0c09" : "#bf7772"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 6; font.weight: Font.Bold }
                                                    MouseArea { id: killMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { if (root.confirmPid === processRow.modelData.pid) { root.systemService.terminateProcess(processRow.modelData.pid, processRow.modelData.name); root.confirmPid = -1 } else { root.confirmPid = processRow.modelData.pid; confirmReset.restart() } } }
                                                }
                                            }
                                            MouseArea { id: childMouse; anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.NoButton }
                                        }
                                    }
                                    Rectangle {
                                        width: processChildren.width; height: 22; color: "transparent"
                                        visible: processGroup.modelData.processes.length === 0
                                        Text { anchors.centerIn: parent; text: "Sin procesos activos"; color: "#65675f"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 7 }
                                    }
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        spacing: 10
                        RowLayout {
                            Layout.fillWidth: true
                            ColumnLayout { Layout.fillWidth: true; spacing: 1
                                Text { text: "~/wallparpers"; color: "#d7d3c7"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11 }
                                Text { text: "JPG · PNG · WEBP · JXL"; color: "#65675f"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 8; font.letterSpacing: 1 }
                            }
                            Rectangle { Layout.preferredWidth: 84; Layout.preferredHeight: 30; radius: 9; color: refreshMouse.containsMouse ? "#292a24" : "#171814"; border.width: 1; border.color: "#3b3c34"
                                Text { anchors.centerIn: parent; text: "󰑐  RECARGAR"; color: "#d5a84f"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 8 }
                                MouseArea { id: refreshMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.systemService.refreshWallpapers() }
                            }
                        }
                        GridView {
                            Layout.fillWidth: true; Layout.fillHeight: true
                            clip: true; cellWidth: width / 2; cellHeight: 150
                            // Avoid decoding every wallpaper while this view is hidden.
                            model: controlWindow.visible && root.activeTab === 2
                                ? root.systemService.wallpapers
                                : []
                            delegate: Item {
                                required property string modelData
                                width: GridView.view.cellWidth; height: GridView.view.cellHeight
                                Rectangle {
                                    anchors { fill: parent; margins: 5 }
                                    radius: 12; color: "#151612"; clip: true
                                    border.width: root.systemService.selectedWallpaper === modelData ? 2 : 1
                                    border.color: root.systemService.selectedWallpaper === modelData ? "#d5a84f" : "#34362f"
                                    Image {
                                        anchors { fill: parent; bottomMargin: 28 }
                                        source: "file://" + modelData
                                        sourceSize: Qt.size(320, 180)
                                        asynchronous: true
                                        cache: false
                                        fillMode: Image.PreserveAspectCrop
                                    }
                                    Rectangle {
                                        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                                        height: 29
                                        color: "#ed0d0e0b"
                                        Text {
                                            anchors { fill: parent; leftMargin: 9; rightMargin: 9 }
                                            text: root.fileName(modelData)
                                            color: "#c9c6ba"
                                            verticalAlignment: Text.AlignVCenter
                                            elide: Text.ElideMiddle
                                            font.family: "JetBrainsMono Nerd Font"
                                            font.pixelSize: 8
                                        }
                                    }
                                    MouseArea { anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.systemService.applyWallpaper(modelData) }
                                }
                            }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true; visible: root.systemService.wallpapers.length === 0
                            Item { Layout.fillHeight: true }
                            Text { Layout.alignment: Qt.AlignHCenter; text: "󰸉"; color: "#d5a84f"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 38 }
                            Text { Layout.alignment: Qt.AlignHCenter; text: "Aún no hay imágenes"; color: "#aaa89d"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11 }
                            Text { Layout.alignment: Qt.AlignHCenter; text: "Copia tus fondos a ~/wallparpers y pulsa Recargar"; color: "#65675f"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 8 }
                            Item { Layout.fillHeight: true }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: root.systemService.statusMessage === "" ? 0 : 30
                    visible: height > 0
                    radius: 9
                    color: root.systemService.statusError ? "#351d1c" : "#1b241d"
                    border.width: 1
                    border.color: root.systemService.statusError ? "#70403d" : "#354b39"
                    Text {
                        anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                        text: root.systemService.statusMessage
                        color: root.systemService.statusError ? "#df8c86" : "#9eb39d"
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 8
                    }
                }
            }
        }
    }
}
