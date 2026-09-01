import QtQuick
import QtQuick.Layouts

import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.Pipewire

Item {
    id: root
    property var targetScreen: null

    readonly property bool opened:
        audioWindow.visible

    readonly property var sink:
        Pipewire.defaultAudioSink

    readonly property var source:
        Pipewire.defaultAudioSource

    readonly property int sinkVolume:
        sink && sink.audio
            ? Math.round(sink.audio.volume * 100)
            : 0

    readonly property int sourceVolume:
        source && source.audio
            ? Math.round(source.audio.volume * 100)
            : 0

    readonly property bool sinkMuted:
        sink && sink.audio
            ? sink.audio.muted
            : false

    readonly property bool sourceMuted:
        source && source.audio
            ? source.audio.muted
            : false

    readonly property var streamNodes:
        Pipewire.nodes
            ? Pipewire.nodes.values.filter(
                function(node) {
                    return node
                        && node.audio
                        && node.isStream
                        && node.isSink
                }
            )
            : []

    readonly property var outputDevices:
        Pipewire.nodes
            ? Pipewire.nodes.values.filter(
                function(node) {
                    return node
                        && node.audio
                        && node.isSink
                        && !node.isStream
                }
            )
            : []

    readonly property var inputDevices:
        Pipewire.nodes
            ? Pipewire.nodes.values.filter(
                function(node) {
                    return node
                        && node.audio
                        && !node.isSink
                        && !node.isStream
                }
            )
            : []

    property int activeTab: 0
    property int maxVolume: 100

    PwObjectTracker {
        objects:
            Pipewire.nodes
                ? Pipewire.nodes.values.filter(
                    function(node) {
                        return node && node.audio
                    }
                )
                : []
    }

    function open() {
        audioWindow.visible = true
    }

    function close() {
        audioWindow.visible = false
    }

    function toggle() {
        audioWindow.visible
            ? root.close()
            : root.open()
    }

    function displayName(node) {
        if (!node)
            return "Dispositivo desconocido"

        if (
            node.description
            && node.description !== node.name
        ) {
            return node.description
        }

        if (
            node.properties
            && node.properties["node.description"]
        ) {
            return node.properties["node.description"]
        }

        if (
            node.nickname
            && node.nickname !== node.name
        ) {
            return node.nickname
        }

        return node.name || "Dispositivo desconocido"
    }

    function streamName(node) {
        if (!node)
            return "Aplicación"

        const properties = node.properties || {}

        return properties["application.name"]
            || properties["media.name"]
            || properties["application.process.binary"]
            || root.displayName(node)
            || "Aplicación"
    }

    function normalizeIconName(value) {
        if (!value)
            return ""

        return String(value)
            .trim()
            .replace(/\.desktop$/i, "")
            .replace(/-bin$/i, "")
    }

    function streamIcon(node) {
        if (!node)
            return ""

        const properties = node.properties || {}

        const candidates = [
            properties["application.icon-name"],
            properties["application.icon_name"],
            properties["application.id"],
            properties["application.name"],
            properties["application.process.binary"]
        ]

        for (let i = 0; i < candidates.length; i++) {
            const candidate =
                root.normalizeIconName(candidates[i])

            if (!candidate)
                continue

            const direct =
                Quickshell.iconPath(candidate, true)

            if (direct)
                return direct

            const entry =
                DesktopEntries.heuristicLookup(candidate)

            if (entry && entry.icon) {
                const resolved =
                    Quickshell.iconPath(
                        entry.icon,
                        true
                    )

                if (resolved)
                    return resolved
            }
        }

        return ""
    }

    function setSinkVolume(value) {
        if (!root.sink || !root.sink.audio)
            return

        root.sink.audio.volume =
            Math.max(
                0,
                Math.min(root.maxVolume, value)
            ) / 100
    }

    function setSourceVolume(value) {
        if (!root.source || !root.source.audio)
            return

        root.source.audio.volume =
            Math.max(
                0,
                Math.min(100, value)
            ) / 100
    }

    function setStreamVolume(node, value) {
        if (!node || !node.audio)
            return

        node.audio.volume =
            Math.max(
                0,
                Math.min(root.maxVolume, value)
            ) / 100
    }

    function toggleSinkMute() {
        if (root.sink && root.sink.audio)
            root.sink.audio.muted =
                !root.sink.audio.muted
    }

    function toggleSourceMute() {
        if (root.source && root.source.audio)
            root.source.audio.muted =
                !root.source.audio.muted
    }

    PanelWindow {
        id: audioWindow
        screen: root.targetScreen

        visible: false
        color: "transparent"

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        WlrLayershell.namespace:
            "minibar-audio-panel"

        WlrLayershell.layer:
            WlrLayershell.Overlay

        WlrLayershell.exclusiveZone: -1

        WlrLayershell.keyboardFocus:
            audioWindow.visible
                ? WlrKeyboardFocus.OnDemand
                : WlrKeyboardFocus.None

        Rectangle {
            anchors.fill: parent
            color: "#59050605"

            MouseArea {
                anchors.fill: parent
                onClicked: root.close()
            }
        }

        Rectangle {
            anchors.fill: parent
            color: "transparent"

            Rectangle {
                id: panel

                anchors {
                    top: parent.top
                    right: parent.right
                    topMargin: 48
                    rightMargin: 8
                    bottomMargin: 8
                }

                width: Math.min(424, parent.width - 16)
                height: Math.min(534, parent.height - 56)

                radius: 20
                color: "#f70b0c0a"

                border.width: 1
                border.color: "#4a4b42"

                MouseArea {
                    anchors.fill: parent
                }

                scale:
                    audioWindow.visible
                        ? 1.0
                        : 0.96

                opacity:
                    audioWindow.visible
                        ? 1.0
                        : 0.0

                Behavior on scale {
                    NumberAnimation {
                        duration: 220
                        easing.type: Easing.OutCubic
                    }
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: 170
                    }
                }

                ColumnLayout {
                    anchors {
                        fill: parent
                        margins: 16
                    }

                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            Layout.fillWidth: true

                            text: "Audio"
                            color: "#ece8dc"

                            font.pixelSize: 19
                            font.bold: true
                        }

                        Rectangle {
                            Layout.preferredWidth: 30
                            Layout.preferredHeight: 30

                            radius: 10

                            color:
                                closeMouse.containsMouse
                                    ? "#292a24"
                                    : "#171814"

                            Text {
                                anchors.centerIn: parent

                                text: "󰅖"
                                color: "#ece8dc"

                                font.pixelSize: 15
                                font.family:
                                    "JetBrainsMono Nerd Font"
                            }

                            MouseArea {
                                id: closeMouse

                                anchors.fill: parent
                                hoverEnabled: true

                                cursorShape:
                                    Qt.PointingHandCursor

                                onClicked: root.close()
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40

                        radius: 12
                        color: "#151612"

                        Row {
                            anchors {
                                fill: parent
                                margins: 3
                            }

                            Rectangle {
                                width: parent.width / 2
                                height: parent.height

                                radius: 9

                                color:
                                    root.activeTab === 0
                                        ? "#d5a84f"
                                        : "transparent"

                                Text {
                                    anchors.centerIn: parent

                                    text: "Volúmenes"

                                    color:
                                        root.activeTab === 0
                                            ? "#11120f"
                                            : "#ece8dc"

                                    font.pixelSize: 12
                                    font.bold:
                                        root.activeTab === 0
                                }

                                MouseArea {
                                    anchors.fill: parent

                                    cursorShape:
                                        Qt.PointingHandCursor

                                    onClicked:
                                        root.activeTab = 0
                                }
                            }

                            Rectangle {
                                width: parent.width / 2
                                height: parent.height

                                radius: 9

                                color:
                                    root.activeTab === 1
                                        ? "#d5a84f"
                                        : "transparent"

                                Text {
                                    anchors.centerIn: parent

                                    text: "Dispositivos"

                                    color:
                                        root.activeTab === 1
                                            ? "#11120f"
                                            : "#ece8dc"

                                    font.pixelSize: 12
                                    font.bold:
                                        root.activeTab === 1
                                }

                                MouseArea {
                                    anchors.fill: parent

                                    cursorShape:
                                        Qt.PointingHandCursor

                                    onClicked:
                                        root.activeTab = 1
                                }
                            }
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        // =====================================
                        // PESTAÑA DE VOLÚMENES
                        // =====================================

                        Flickable {
                            id: volumeFlickable

                            anchors.fill: parent

                            visible:
                                root.activeTab === 0

                            contentWidth: width
                            contentHeight:
                                volumeColumn.implicitHeight

                            clip: true

                            flickableDirection:
                                Flickable.VerticalFlick

                            boundsBehavior:
                                Flickable.StopAtBounds

                            Column {
                                id: volumeColumn

                                width:
                                    volumeFlickable.width

                                spacing: 12

                                AudioSection {
                                    width: parent.width

                                    title:
                                        "Salida"

                                    subtitle:
                                        root.sink
                                            ? root.displayName(
                                                root.sink
                                            )
                                            : "Sin salida disponible"

                                    icon:
                                        root.sinkMuted
                                            || root.sinkVolume === 0
                                                ? "󰖁"
                                                : "󰕾"

                                    value:
                                        root.sinkVolume

                                    muted:
                                        root.sinkMuted

                                    maximum:
                                        root.maxVolume

                                    onValueChangedByUser:
                                        function(newValue) {
                                            root.setSinkVolume(
                                                newValue
                                            )
                                        }

                                    onMuteClicked:
                                        root.toggleSinkMute()
                                }

                                Rectangle {
                                    width: parent.width
                                    height: 1
                                    color: "#34362f"
                                }

                                AudioSection {
                                    width: parent.width

                                    title:
                                        "Micrófono"

                                    subtitle:
                                        root.source
                                            ? root.displayName(
                                                root.source
                                            )
                                            : "Sin micrófono disponible"

                                    icon:
                                        root.sourceMuted
                                            ? "󰍭"
                                            : "󰍬"

                                    value:
                                        root.sourceVolume

                                    muted:
                                        root.sourceMuted

                                    maximum: 100

                                    onValueChangedByUser:
                                        function(newValue) {
                                            root.setSourceVolume(
                                                newValue
                                            )
                                        }

                                    onMuteClicked:
                                        root.toggleSourceMute()
                                }

                                Rectangle {
                                    width: parent.width
                                    height: 1
                                    color: "#34362f"
                                }

                                Text {
                                    width: parent.width

                                    text:
                                        "Aplicaciones"

                                    color: "#d5a84f"

                                    font.pixelSize: 13
                                    font.bold: true
                                }

                                Text {
                                    width: parent.width

                                    visible:
                                        root.streamNodes.length
                                            === 0

                                    text:
                                        "Ninguna aplicación está reproduciendo audio"

                                    color: "#65675f"

                                    font.pixelSize: 12

                                    horizontalAlignment:
                                        Text.AlignHCenter

                                    wrapMode:
                                        Text.Wrap
                                }

                                Repeater {
                                    model:
                                        root.streamNodes

                                    delegate: Rectangle {
                                        id: streamCard

                                        required property var modelData

                                        width:
                                            volumeColumn.width

                                        height:
                                            streamContent
                                                .implicitHeight
                                            + 20

                                        radius: 14
                                        color: "#151612"

                                        border.width: 1
                                        border.color: "#34362f"

                                        Column {
                                            id: streamContent

                                            anchors {
                                                left: parent.left
                                                right: parent.right
                                                top: parent.top

                                                leftMargin: 10
                                                rightMargin: 10
                                                topMargin: 10
                                            }

                                            spacing: 8

                                            Row {
                                                width: parent.width
                                                spacing: 9

                                                Rectangle {
                                                    width: 30
                                                    height: 30
                                                    radius: 9

                                                    color: "#34362f"

                                                    IconImage {
                                                        id: streamIcon

                                                        anchors {
                                                            fill: parent
                                                            margins: 5
                                                        }

                                                        source:
                                                            root.streamIcon(
                                                                streamCard
                                                                    .modelData
                                                            )

                                                        visible:
                                                            source !== ""
                                                            && status
                                                                === Image.Ready

                                                        smooth: true
                                                        mipmap: true
                                                    }

                                                    Text {
                                                        anchors.centerIn:
                                                            parent

                                                        visible:
                                                            !streamIcon
                                                                .visible

                                                        text: {
                                                            const name =
                                                                root.streamName(
                                                                    streamCard
                                                                        .modelData
                                                                )

                                                            return name.length
                                                                    > 0
                                                                ? name
                                                                    .charAt(0)
                                                                    .toUpperCase()
                                                                : "?"
                                                        }

                                                        color: "#ece8dc"
                                                        font.bold: true
                                                    }
                                                }

                                                Text {
                                                    width:
                                                        parent.width
                                                        - 30
                                                        - 9
                                                        - 72

                                                    anchors.verticalCenter:
                                                        parent.verticalCenter

                                                    text:
                                                        root.streamName(
                                                            streamCard
                                                                .modelData
                                                        )

                                                    color: "#d7d3c7"
                                                    font.pixelSize: 12
                                                    font.bold: true

                                                    elide:
                                                        Text.ElideRight
                                                }

                                                Text {
                                                    width: 40

                                                    anchors.verticalCenter:
                                                        parent.verticalCenter

                                                    text:
                                                        streamCard.modelData
                                                        && streamCard
                                                            .modelData
                                                            .audio
                                                            ? Math.round(
                                                                streamCard
                                                                    .modelData
                                                                    .audio
                                                                    .volume
                                                                * 100
                                                            ) + "%"
                                                            : "0%"

                                                    color: "#ece8dc"
                                                    font.pixelSize: 11

                                                    horizontalAlignment:
                                                        Text.AlignRight
                                                }

                                                Rectangle {
                                                    width: 24
                                                    height: 24
                                                    radius: 8

                                                    anchors.verticalCenter:
                                                        parent.verticalCenter

                                                    color:
                                                        streamMuteMouse
                                                            .containsMouse
                                                            ? "#292a24"
                                                            : "transparent"

                                                    Text {
                                                        anchors.centerIn:
                                                            parent

                                                        text:
                                                            streamCard
                                                                .modelData
                                                            && streamCard
                                                                .modelData
                                                                .audio
                                                                .muted
                                                                ? "󰖁"
                                                                : "󰕾"

                                                        color:
                                                            streamCard
                                                                .modelData
                                                            && streamCard
                                                                .modelData
                                                                .audio
                                                                .muted
                                                                ? "#65675f"
                                                                : "#d5a84f"

                                                        font.pixelSize: 14
                                                        font.family:
                                                            "JetBrainsMono Nerd Font"
                                                    }

                                                    MouseArea {
                                                        id: streamMuteMouse

                                                        anchors.fill: parent
                                                        hoverEnabled: true

                                                        cursorShape:
                                                            Qt.PointingHandCursor

                                                        onClicked: {
                                                            if (
                                                                streamCard
                                                                    .modelData
                                                                && streamCard
                                                                    .modelData
                                                                    .audio
                                                            ) {
                                                                streamCard
                                                                    .modelData
                                                                    .audio
                                                                    .muted =
                                                                    !streamCard
                                                                        .modelData
                                                                        .audio
                                                                        .muted
                                                            }
                                                        }
                                                    }
                                                }
                                            }

                                            VolumeSlider {
                                                width: parent.width

                                                value:
                                                    streamCard.modelData
                                                    && streamCard
                                                        .modelData
                                                        .audio
                                                        ? Math.round(
                                                            streamCard
                                                                .modelData
                                                                .audio
                                                                .volume
                                                            * 100
                                                        )
                                                        : 0

                                                maximum:
                                                    root.maxVolume

                                                muted:
                                                    streamCard.modelData
                                                    && streamCard
                                                        .modelData
                                                        .audio
                                                        ? streamCard
                                                            .modelData
                                                            .audio
                                                            .muted
                                                        : false

                                                onMovedByUser:
                                                    function(newValue) {
                                                        root.setStreamVolume(
                                                            streamCard
                                                                .modelData,
                                                            newValue
                                                        )
                                                    }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // =====================================
                        // PESTAÑA DE DISPOSITIVOS
                        // =====================================

                        Flickable {
                            id: devicesFlickable

                            anchors.fill: parent

                            visible:
                                root.activeTab === 1

                            contentWidth: width
                            contentHeight:
                                devicesColumn.implicitHeight

                            clip: true

                            flickableDirection:
                                Flickable.VerticalFlick

                            boundsBehavior:
                                Flickable.StopAtBounds

                            Column {
                                id: devicesColumn

                                width:
                                    devicesFlickable.width

                                spacing: 10

                                Text {
                                    width: parent.width

                                    text:
                                        "Dispositivos de salida"

                                    color: "#d5a84f"

                                    font.pixelSize: 13
                                    font.bold: true
                                }

                                Repeater {
                                    model:
                                        root.outputDevices

                                    delegate: DeviceItem {
                                        required property var modelData

                                        width:
                                            devicesColumn.width

                                        title:
                                            root.displayName(
                                                modelData
                                            )

                                        selected:
                                            root.sink
                                            && modelData.name
                                                === root.sink.name

                                        icon: "󰕾"

                                        onSelected: {
                                            Pipewire
                                                .preferredDefaultAudioSink =
                                                modelData
                                        }
                                    }
                                }

                                Rectangle {
                                    width: parent.width
                                    height: 1
                                    color: "#34362f"
                                }

                                Text {
                                    width: parent.width

                                    text:
                                        "Dispositivos de entrada"

                                    color: "#d5a84f"

                                    font.pixelSize: 13
                                    font.bold: true
                                }

                                Repeater {
                                    model:
                                        root.inputDevices

                                    delegate: DeviceItem {
                                        required property var modelData

                                        width:
                                            devicesColumn.width

                                        title:
                                            root.displayName(
                                                modelData
                                            )

                                        selected:
                                            root.source
                                            && modelData.name
                                                === root.source.name

                                        icon: "󰍬"

                                        onSelected: {
                                            Pipewire
                                                .preferredDefaultAudioSource =
                                                modelData
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Item {
            anchors.fill: parent
            focus: audioWindow.visible

            Keys.onEscapePressed:
                root.close()
        }
    }

    // =========================================================
    // COMPONENTE DE UNA SECCIÓN PRINCIPAL
    // =========================================================

    component AudioSection: Rectangle {
        id: section

        property string title: ""
        property string subtitle: ""
        property string icon: ""

        property real value: 0
        property real maximum: 100
        property bool muted: false

        signal valueChangedByUser(real newValue)
        signal muteClicked()

        implicitHeight:
            sectionColumn.implicitHeight + 20

        radius: 14
        color: "#151612"

        border.width: 1
        border.color: "#34362f"

        Column {
            id: sectionColumn

            anchors {
                left: parent.left
                right: parent.right
                top: parent.top

                leftMargin: 10
                rightMargin: 10
                topMargin: 10
            }

            spacing: 9

            Row {
                width: parent.width
                spacing: 9

                Rectangle {
                    width: 34
                    height: 34
                    radius: 10

                    color: "#34362f"

                    Text {
                        anchors.centerIn: parent

                        text: section.icon

                        color: section.muted
                            ? "#65675f"
                            : "#d5a84f"

                        font.pixelSize: 17
                        font.family:
                            "JetBrainsMono Nerd Font"
                    }
                }

                Column {
                    width:
                        parent.width
                        - 34
                        - 9
                        - 50
                        - 28

                    anchors.verticalCenter:
                        parent.verticalCenter

                    spacing: 2

                    Text {
                        width: parent.width

                        text: section.title
                        color: "#ece8dc"

                        font.pixelSize: 13
                        font.bold: true
                    }

                    Text {
                        width: parent.width

                        text: section.subtitle
                        color: "#aaa89d"

                        font.pixelSize: 10

                        elide: Text.ElideRight
                    }
                }

                Text {
                    width: 42

                    anchors.verticalCenter:
                        parent.verticalCenter

                    text:
                        Math.round(section.value)
                        + "%"

                    color: section.muted
                        ? "#65675f"
                        : "#ece8dc"

                    font.pixelSize: 11

                    horizontalAlignment:
                        Text.AlignRight
                }

                Rectangle {
                    width: 28
                    height: 28
                    radius: 9

                    anchors.verticalCenter:
                        parent.verticalCenter

                    color:
                        sectionMuteMouse.containsMouse
                            ? "#292a24"
                            : "transparent"

                    Text {
                        anchors.centerIn: parent

                        text: section.muted
                            ? "󰖁"
                            : section.icon

                        color: section.muted
                            ? "#65675f"
                            : "#d5a84f"

                        font.pixelSize: 14
                        font.family:
                            "JetBrainsMono Nerd Font"
                    }

                    MouseArea {
                        id: sectionMuteMouse

                        anchors.fill: parent
                        hoverEnabled: true

                        cursorShape:
                            Qt.PointingHandCursor

                        onClicked:
                            section.muteClicked()
                    }
                }
            }

            VolumeSlider {
                width: parent.width

                value: section.value
                maximum: section.maximum
                muted: section.muted

                onMovedByUser:
                    function(newValue) {
                        section.valueChangedByUser(
                            newValue
                        )
                    }
            }
        }
    }

    // =========================================================
    // SLIDER PROPIO, SIN QtQuick.Controls
    // =========================================================

    component VolumeSlider: Item {
        id: slider

        property real value: 0
        property real maximum: 100
        property bool muted: false

        signal movedByUser(real newValue)

        height: 24

        function valueFromPosition(positionX) {
            if (slider.width <= 0)
                return 0

            return Math.max(
                0,
                Math.min(
                    slider.maximum,
                    positionX
                    / slider.width
                    * slider.maximum
                )
            )
        }

        Rectangle {
            id: sliderTrack

            anchors {
                left: parent.left
                right: parent.right
                verticalCenter: parent.verticalCenter
            }

            height: 5
            radius: 3
            color: "#292a24"

            Rectangle {
                width:
                    slider.maximum > 0
                        ? Math.max(
                            0,
                            Math.min(
                                parent.width,
                                slider.value
                                / slider.maximum
                                * parent.width
                            )
                        )
                        : 0

                height: parent.height
                radius: parent.radius

                color: slider.muted
                    ? "#65675f"
                    : "#d5a84f"

                Behavior on width {
                    NumberAnimation {
                        duration:
                            sliderMouse.pressed
                                ? 0
                                : 90
                    }
                }
            }
        }

        Rectangle {
            width: 16
            height: 16
            radius: 8

            y:
                parent.height / 2
                - height / 2

            x:
                slider.maximum > 0
                    ? Math.max(
                        0,
                        Math.min(
                            slider.width - width,
                            slider.value
                            / slider.maximum
                            * (slider.width - width)
                        )
                    )
                    : 0

            color: slider.muted
                ? "#65675f"
                : "#d5a84f"

            border.width: 2
            border.color: "#11120f"
        }

        MouseArea {
            id: sliderMouse

            anchors.fill: parent

            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            onPressed: function(mouse) {
                slider.movedByUser(
                    slider.valueFromPosition(
                        mouse.x
                    )
                )
            }

            onPositionChanged: function(mouse) {
                if (!pressed)
                    return

                slider.movedByUser(
                    slider.valueFromPosition(
                        mouse.x
                    )
                )
            }

            onWheel: function(wheel) {
                const step =
                    wheel.angleDelta.y > 0
                        ? 3
                        : -3

                slider.movedByUser(
                    Math.max(
                        0,
                        Math.min(
                            slider.maximum,
                            slider.value + step
                        )
                    )
                )

                wheel.accepted = true
            }
        }
    }

    // =========================================================
    // ELEMENTO DE DISPOSITIVO
    // =========================================================

    component DeviceItem: Rectangle {
        id: device

        property string title: ""
        property string icon: ""
        property bool selected: false

        signal selected()

        height: 46
        radius: 13

        color:
            deviceMouse.containsMouse
                ? "#171814"
                : "#151612"

        border.width:
            device.selected ? 2 : 1

        border.color:
            device.selected
                ? "#d5a84f"
                : "#34362f"

        Row {
            anchors {
                fill: parent
                margins: 9
            }

            spacing: 10

            Rectangle {
                width: 28
                height: 28
                radius: 9

                anchors.verticalCenter:
                    parent.verticalCenter

                color: device.selected
                    ? "#25251f"
                    : "#34362f"

                Text {
                    anchors.centerIn: parent

                    text: device.icon

                    color: device.selected
                        ? "#d5a84f"
                        : "#ece8dc"

                    font.pixelSize: 15
                    font.family:
                        "JetBrainsMono Nerd Font"
                }
            }

            Text {
                width:
                    parent.width
                    - 28
                    - 10
                    - 24

                anchors.verticalCenter:
                    parent.verticalCenter

                text: device.title
                color: "#d7d3c7"

                font.pixelSize: 12

                elide: Text.ElideMiddle
            }

            Rectangle {
                width: 18
                height: 18
                radius: 9

                anchors.verticalCenter:
                    parent.verticalCenter

                color: "transparent"

                border.width: 2

                border.color:
                    device.selected
                        ? "#d5a84f"
                        : "#65675f"

                Rectangle {
                    anchors.centerIn: parent

                    width: 9
                    height: 9
                    radius: 5

                    visible:
                        device.selected

                    color: "#d5a84f"
                }
            }
        }

        MouseArea {
            id: deviceMouse

            anchors.fill: parent
            hoverEnabled: true

            cursorShape:
                Qt.PointingHandCursor

            onClicked:
                device.selected()
        }
    }
}
