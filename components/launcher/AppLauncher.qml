import QtQuick
import QtQuick.Layouts

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets

Item {
    id: root
    property var targetScreen: null

    readonly property bool opened: launcherWindow.visible

    property string searchText: ""
    property var applications: []
    property var filteredApplications: []

    property int selectedIndex: 0
    property int columns: 5

    // =========================================================
    // ABRIR Y CERRAR
    // =========================================================

    function open(): void {
        root.refreshApplications()

        root.searchText = ""
        root.selectedIndex = 0

        launcherWindow.visible = true
        focusTimer.restart()
    }

    function close(): void {
        launcherWindow.visible = false
        root.searchText = ""
        root.selectedIndex = 0
        // Release GridView delegates and their icon textures while closed.
        root.filteredApplications = []
    }

    function toggle(): void {
        if (launcherWindow.visible)
            root.close()
        else
            root.open()
    }

    // =========================================================
    // APLICACIONES
    // =========================================================

    function normalize(value) {
        if (!value)
            return ""

        return String(value)
            .toLowerCase()
            .normalize("NFD")
            .replace(/[\u0300-\u036f]/g, "")
    }

    function refreshApplications() {
        const source =
            DesktopEntries.applications
                ? Array.from(
                    DesktopEntries.applications.values
                  )
                : []

        const result = []

        for (let i = 0; i < source.length; i++) {
            const entry = source[i]

            if (!entry || entry.noDisplay)
                continue

            result.push(entry)
        }

        result.sort(function(a, b) {
            return String(a.name || "")
                .localeCompare(
                    String(b.name || "")
                )
        })

        root.applications = result
        root.filterApplications()
    }

    function filterApplications() {
        const query =
            root.normalize(root.searchText).trim()

        if (query === "") {
            root.filteredApplications =
                root.applications.slice(0, 80)

            root.clampSelection()
            return
        }

        const result = []

        for (
            let i = 0;
            i < root.applications.length;
            i++
        ) {
            const entry = root.applications[i]

            const name =
                root.normalize(entry.name)

            const genericName =
                root.normalize(entry.genericName)

            const comment =
                root.normalize(entry.comment)

            const id =
                root.normalize(entry.id)

            const keywords =
                entry.keywords
                    ? root.normalize(
                        Array.from(entry.keywords)
                            .join(" ")
                      )
                    : ""

            const categories =
                entry.categories
                    ? root.normalize(
                        Array.from(entry.categories)
                            .join(" ")
                      )
                    : ""

            let score = 999

            if (name === query)
                score = 0
            else if (name.startsWith(query))
                score = 1
            else if (name.includes(query))
                score = 2
            else if (genericName.includes(query))
                score = 3
            else if (keywords.includes(query))
                score = 4
            else if (comment.includes(query))
                score = 5
            else if (categories.includes(query))
                score = 6
            else if (id.includes(query))
                score = 7

            if (score < 999) {
                result.push({
                    key: entry.id,
                    entry: entry,
                    score: score
                })
            }
        }

        result.sort(function(a, b) {
            if (a.score !== b.score)
                return a.score - b.score

            return String(a.entry.name || "")
                .localeCompare(
                    String(b.entry.name || "")
                )
        })

        const entries = []

        for (
            let j = 0;
            j < result.length && j < 80;
            j++
        ) {
            entries.push(result[j].entry)
        }

        root.filteredApplications = entries
        root.selectedIndex = 0
        root.clampSelection()
    }

    function clampSelection() {
        if (root.filteredApplications.length === 0) {
            root.selectedIndex = -1
            return
        }

        root.selectedIndex = Math.max(
            0,
            Math.min(
                root.selectedIndex,
                root.filteredApplications.length - 1
            )
        )
    }

    function iconFor(entry) {
        if (!entry || !entry.icon)
            return ""

        return Quickshell.iconPath(
            entry.icon,
            true
        )
    }

    function descriptionFor(entry) {
        if (!entry)
            return ""

        if (
            entry.genericName
            && entry.genericName !== ""
            && entry.genericName !== entry.name
        ) {
            return entry.genericName
        }

        if (entry.comment)
            return entry.comment

        return entry.id || ""
    }

    function launch(entry) {
        if (!entry)
            return

        root.close()

        /*
         * DesktopEntry.execute() ejecuta el comando
         * ya procesado de la entrada .desktop.
         */
        entry.execute()
    }

    function launchSelected() {
        if (
            root.selectedIndex < 0
            || root.selectedIndex
                >= root.filteredApplications.length
        ) {
            return
        }

        root.launch(
            root.filteredApplications[
                root.selectedIndex
            ]
        )
    }

    // =========================================================
    // NAVEGACIÓN
    // =========================================================

    function moveSelectionHorizontal(delta) {
        if (root.filteredApplications.length === 0)
            return

        root.selectedIndex += delta
        root.clampSelection()
        appGrid.positionViewAtIndex(
            root.selectedIndex,
            GridView.Contain
        )
    }

    function moveSelectionVertical(delta) {
        if (root.filteredApplications.length === 0)
            return

        root.selectedIndex += delta * root.columns
        root.clampSelection()
        appGrid.positionViewAtIndex(
            root.selectedIndex,
            GridView.Contain
        )
    }

    // =========================================================
    // VENTANA
    // =========================================================

    PanelWindow {
        id: launcherWindow
        screen: root.targetScreen

        visible: false
        color: "transparent"

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        exclusionMode: ExclusionMode.Ignore

        WlrLayershell.namespace:
            "minibar-app-launcher"

        WlrLayershell.layer:
            WlrLayershell.Overlay

        WlrLayershell.exclusiveZone: -1

        WlrLayershell.keyboardFocus:
            launcherWindow.visible
                ? WlrKeyboardFocus.Exclusive
                : WlrKeyboardFocus.None

        // Fondo oscuro.
        Rectangle {
            anchors.fill: parent
            color: "#66050605"

            opacity:
                launcherWindow.visible ? 1 : 0

            Behavior on opacity {
                NumberAnimation {
                    duration: 180
                }
            }

            MouseArea {
                anchors.fill: parent

                onClicked: {
                    root.close()
                }
            }
        }

        // Panel central.
        Rectangle {
            id: launcherCard

            anchors.centerIn: parent

            width: Math.min(
                launcherWindow.width - 80,
                1000
            )

            height: Math.min(
                launcherWindow.height - 100,
                680
            )

            radius: 22
            color: "#f70b0c0a"

            border.width: 1
            border.color: "#4a4b42"

            opacity:
                launcherWindow.visible ? 1 : 0

            scale:
                launcherWindow.visible ? 1 : 0.94

            Behavior on opacity {
                NumberAnimation {
                    duration: 180
                }
            }

            Behavior on scale {
                NumberAnimation {
                    duration: 240
                    easing.type: Easing.OutBack
                }
            }

            /*
             * Impide que un clic dentro del panel llegue
             * al fondo y cierre el lanzador.
             */
            MouseArea {
                anchors.fill: parent
            }

            ColumnLayout {
                anchors {
                    fill: parent
                    margins: 22
                }

                spacing: 16

                // =============================================
                // CABECERA
                // =============================================

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Rectangle {
                        Layout.preferredWidth: 44
                        Layout.preferredHeight: 44

                        radius: 14
                        color: "#25251f"

                        Text {
                            anchors.centerIn: parent

                            text: "󰀻"
                            color: "#d5a84f"

                            font.pixelSize: 22
                            font.family:
                                "JetBrainsMono Nerd Font"
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        Text {
                            Layout.fillWidth: true

                            text: "Aplicaciones"

                            color: "#ece8dc"
                            font.pixelSize: 19
                            font.bold: true
                        }

                        Text {
                            Layout.fillWidth: true

                            text:
                                "Busca y ejecuta tus aplicaciones"

                            color: "#65675f"
                            font.pixelSize: 10
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32

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

                // =============================================
                // BUSCADOR
                // =============================================

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 54

                    radius: 17
                    color: "#151612"

                    border.width:
                        searchInput.activeFocus ? 2 : 1

                    border.color:
                        searchInput.activeFocus
                            ? "#d5a84f"
                            : "#3a3b34"

                    Behavior on border.color {
                        ColorAnimation {
                            duration: 120
                        }
                    }

                    Row {
                        anchors {
                            fill: parent
                            leftMargin: 16
                            rightMargin: 12
                        }

                        spacing: 11

                        Text {
                            anchors.verticalCenter:
                                parent.verticalCenter

                            text: "󰍉"
                            color: "#d5a84f"

                            font.pixelSize: 19
                            font.family:
                                "JetBrainsMono Nerd Font"
                        }

                        Item {
                            width:
                                parent.width - 48

                            height: parent.height

                            Text {
                                anchors.verticalCenter:
                                    parent.verticalCenter

                                visible:
                                    searchInput.text === ""

                                text:
                                    "Buscar una aplicación…"

                                color: "#65675f"
                                font.pixelSize: 14
                            }

                            TextInput {
                                id: searchInput

                                anchors.fill: parent

                                verticalAlignment:
                                    TextInput.AlignVCenter

                                color: "#ece8dc"
                                font.pixelSize: 14

                                selectionColor: "#d5a84f"
                                selectedTextColor: "#11120f"

                                clip: true
                                focus: launcherWindow.visible

                                text: root.searchText

                                onTextChanged: {
                                    if (
                                        root.searchText !== text
                                    ) {
                                        root.searchText = text
                                        root.filterApplications()
                                    }
                                }

                                Keys.onEscapePressed: {
                                    root.close()
                                }

                                Keys.onReturnPressed: {
                                    root.launchSelected()
                                }

                                Keys.onEnterPressed: {
                                    root.launchSelected()
                                }

                                Keys.onLeftPressed: {
                                    root.moveSelectionHorizontal(-1)
                                }

                                Keys.onRightPressed: {
                                    root.moveSelectionHorizontal(1)
                                }

                                Keys.onUpPressed: {
                                    root.moveSelectionVertical(-1)
                                }

                                Keys.onDownPressed: {
                                    root.moveSelectionVertical(1)
                                }

                                Keys.onTabPressed: {
                                    root.moveSelectionHorizontal(1)
                                }

                                Keys.onBacktabPressed: {
                                    root.moveSelectionHorizontal(-1)
                                }
                            }
                        }
                    }
                }

                // =============================================
                // RESULTADOS
                // =============================================

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Text {
                        anchors.centerIn: parent

                        visible:
                            root.filteredApplications.length
                            === 0

                        text:
                            "󰍉\nNo se encontraron aplicaciones"

                        horizontalAlignment:
                            Text.AlignHCenter

                        color: "#65675f"

                        font.pixelSize: 14
                        font.family:
                            "JetBrainsMono Nerd Font"
                    }

                    GridView {
                        id: appGrid

                        anchors.fill: parent

                        visible:
                            root.filteredApplications.length
                            > 0

                        model:
                            root.filteredApplications

                        cellWidth:
                            width / root.columns

                        cellHeight: 130

                        clip: true

                        boundsBehavior:
                            Flickable.StopAtBounds

                        keyNavigationEnabled: false

                        delegate: Item {
                            id: appDelegate

                            required property var modelData
                            required property int index

                            width: appGrid.cellWidth
                            height: appGrid.cellHeight

                            property bool selected:
                                index === root.selectedIndex

                            Rectangle {
                                anchors {
                                    fill: parent
                                    margins: 5
                                }

                                radius:
                                    appMouse.containsMouse
                                    || appDelegate.selected
                                        ? 30
                                        : 18

                                color: {
                                    if (appDelegate.selected)
                                        return "#25251f"

                                    if (appMouse.containsMouse)
                                        return "#171814"

                                    return "#151612"
                                }

                                border.width:
                                    appDelegate.selected ? 2 : 1

                                border.color:
                                    appDelegate.selected
                                        ? "#d5a84f"
                                        : "#34362f"

                                Behavior on radius {
                                    NumberAnimation {
                                        duration: 220
                                        easing.type:
                                            Easing.OutCubic
                                    }
                                }

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 120
                                    }
                                }

                                Column {
                                    anchors {
                                        fill: parent
                                        margins: 10
                                    }

                                    spacing: 7

                                    Rectangle {
                                        anchors.horizontalCenter:
                                            parent.horizontalCenter

                                        width: 55
                                        height: 55
                                        radius: 17

                                        color:
                                            appDelegate.selected
                                                ? "#4a4b42"
                                                : "#34362f"

                                        IconImage {
                                            id: applicationIcon

                                            anchors {
                                                fill: parent
                                                margins: 9
                                            }

                                            source:
                                                root.iconFor(
                                                    appDelegate
                                                        .modelData
                                                )

                                            asynchronous: true
                                            smooth: true
                                            mipmap: true

                                            visible:
                                                source !== ""
                                                && status
                                                    === Image.Ready
                                        }

                                        Text {
                                            anchors.centerIn: parent

                                            visible:
                                                !applicationIcon.visible

                                            text: {
                                                const appName =
                                                    appDelegate
                                                        .modelData
                                                        .name
                                                        || "?"

                                                return appName
                                                    .charAt(0)
                                                    .toUpperCase()
                                            }

                                            color: "#ece8dc"
                                            font.pixelSize: 20
                                            font.bold: true
                                        }
                                    }

                                    Text {
                                        width: parent.width

                                        text:
                                            appDelegate
                                                .modelData
                                                .name
                                                || "Aplicación"

                                        horizontalAlignment:
                                            Text.AlignHCenter

                                        color: "#ece8dc"

                                        font.pixelSize: 12
                                        font.bold:
                                            appDelegate.selected

                                        maximumLineCount: 1
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        width: parent.width

                                        text:
                                            root.descriptionFor(
                                                appDelegate
                                                    .modelData
                                            )

                                        horizontalAlignment:
                                            Text.AlignHCenter

                                        color: "#65675f"
                                        font.pixelSize: 9

                                        maximumLineCount: 1
                                        elide: Text.ElideRight
                                    }
                                }

                                MouseArea {
                                    id: appMouse

                                    anchors.fill: parent
                                    hoverEnabled: true

                                    cursorShape:
                                        Qt.PointingHandCursor

                                    onEntered: {
                                        root.selectedIndex =
                                            appDelegate.index
                                    }

                                    onClicked: {
                                        root.selectedIndex =
                                            appDelegate.index

                                        root.launch(
                                            appDelegate.modelData
                                        )
                                    }
                                }
                            }
                        }
                    }
                }

                // =============================================
                // PIE
                // =============================================

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: "#34362f"
                }

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        Layout.fillWidth: true

                        text:
                            root.filteredApplications.length
                            + " aplicaciones"

                        color: "#65675f"
                        font.pixelSize: 10
                    }

                    Text {
                        text:
                            "↑↓←→ navegar   Enter abrir   Esc cerrar"

                        color: "#65675f"
                        font.pixelSize: 9
                    }
                }
            }
        }

        Item {
            anchors.fill: parent
            focus: launcherWindow.visible

            Keys.onEscapePressed: {
                root.close()
            }
        }
    }

    Timer {
        id: focusTimer

        interval: 80
        repeat: false

        onTriggered: {
            searchInput.forceActiveFocus()
        }
    }

    Component.onCompleted: {
        root.refreshApplications()
    }
}
