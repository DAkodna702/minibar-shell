import QtQuick
import QtQuick.Layouts

import Quickshell
import Quickshell.Wayland

Item {
    id: root
    property var targetScreen: null

    required property var service

    readonly property bool opened:
        clipboardWindow.visible

    property int activeTab: 0
    property string statusMessage: ""

    readonly property var currentModel:
        activeTab === 0
            ? service.filteredEntries
            : service.filteredPins

    function open() {
        clipboardWindow.visible = true
        service.refresh()
        focusTimer.restart()
    }

    function close() {
        clipboardWindow.visible = false
        root.statusMessage = ""
        service.searchText = ""
    }

    function toggle() {
        clipboardWindow.visible
            ? root.close()
            : root.open()
    }

    function showStatus(message) {
        root.statusMessage = message
        statusTimer.restart()
    }

    function copyItem(entry) {
        if (root.activeTab === 0)
            root.service.copyEntry(entry)
        else
            root.service.copyPinned(entry)
    }

    Connections {
        target: root.service

        function onCopied(preview) {
            root.showStatus("Copiado")
        }

        function onErrorOccurred(message) {
            root.showStatus(message)
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

    Timer {
        id: statusTimer

        interval: 1800
        repeat: false

        onTriggered: {
            root.statusMessage = ""
        }
    }

    PanelWindow {
        id: clipboardWindow
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
            "minibar-clipboard-panel"

        WlrLayershell.layer:
            WlrLayershell.Overlay

        WlrLayershell.exclusiveZone: -1

        WlrLayershell.keyboardFocus:
            clipboardWindow.visible
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

                width: Math.min(454, parent.width - 16)
                height: Math.min(624, parent.height - 56)

                radius: 20
                color: "#f70b0c0a"

                border.width: 1
                border.color: "#4a4b42"

                MouseArea {
                    anchors.fill: parent
                }

                opacity:
                    clipboardWindow.visible
                        ? 1
                        : 0

                scale:
                    clipboardWindow.visible
                        ? 1
                        : 0.96

                Behavior on opacity {
                    NumberAnimation {
                        duration: 170
                    }
                }

                Behavior on scale {
                    NumberAnimation {
                        duration: 220
                        easing.type:
                            Easing.OutCubic
                    }
                }

                ColumnLayout {
                    anchors {
                        fill: parent
                        margins: 16
                    }

                    spacing: 12

                    // Cabecera.
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            Layout.fillWidth: true

                            text: "Portapapeles"

                            color: "#ece8dc"

                            font.pixelSize: 19
                            font.bold: true
                        }

                        Text {
                            visible:
                                root.statusMessage !== ""

                            text: root.statusMessage
                            color: "#9eb39d"

                            font.pixelSize: 10
                        }

                        // Limpia solo historial, no fijados.
                        Rectangle {
                            visible:
                                root.activeTab === 0

                            Layout.preferredWidth:
                                visible
                                    ? clearText.implicitWidth + 18
                                    : 0

                            Layout.preferredHeight: 30

                            radius: 10

                            color:
                                clearMouse.containsMouse
                                    ? "#4a3038"
                                    : "#171814"

                            Text {
                                id: clearText

                                anchors.centerIn:
                                    parent

                                text: "Limpiar historial"

                                color:
                                    clearMouse.containsMouse
                                        ? "#d66d68"
                                        : "#ece8dc"

                                font.pixelSize: 10
                            }

                            MouseArea {
                                id: clearMouse

                                anchors.fill: parent
                                hoverEnabled: true

                                cursorShape:
                                    Qt.PointingHandCursor

                                onClicked: {
                                    root.service.clearAll()
                                }
                            }
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
                                anchors.centerIn:
                                    parent

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

                    // Pestañas.
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 42

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

                                Row {
                                    anchors.centerIn: parent
                                    spacing: 6

                                    Text {
                                        text: "󰅌"

                                        color:
                                            root.activeTab === 0
                                                ? "#11120f"
                                                : "#ece8dc"

                                        font.pixelSize: 14
                                        font.family:
                                            "JetBrainsMono Nerd Font"
                                    }

                                    Text {
                                        text:
                                            "Historial ("
                                            + root.service.entries.length
                                            + ")"

                                        color:
                                            root.activeTab === 0
                                                ? "#11120f"
                                                : "#ece8dc"

                                        font.pixelSize: 11
                                        font.bold:
                                            root.activeTab === 0
                                    }
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
                                        ? "#b6a07a"
                                        : "transparent"

                                Row {
                                    anchors.centerIn: parent
                                    spacing: 6

                                    Text {
                                        text: "󰐃"

                                        color:
                                            root.activeTab === 1
                                                ? "#11120f"
                                                : "#ece8dc"

                                        font.pixelSize: 14
                                        font.family:
                                            "JetBrainsMono Nerd Font"
                                    }

                                    Text {
                                        text:
                                            "Fijados ("
                                            + root.service.pins.length
                                            + ")"

                                        color:
                                            root.activeTab === 1
                                                ? "#11120f"
                                                : "#ece8dc"

                                        font.pixelSize: 11
                                        font.bold:
                                            root.activeTab === 1
                                    }
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

                    // Búsqueda.
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40

                        radius: 12
                        color: "#151612"

                        border.width:
                            searchInput.activeFocus
                                ? 1
                                : 0

                        border.color: "#d5a84f"

                        Row {
                            anchors {
                                fill: parent
                                margins: 10
                            }

                            spacing: 8

                            Text {
                                anchors.verticalCenter:
                                    parent.verticalCenter

                                text: "󰍉"
                                color: "#d5a84f"

                                font.pixelSize: 15
                                font.family:
                                    "JetBrainsMono Nerd Font"
                            }

                            Item {
                                width:
                                    parent.width - 23

                                height: parent.height

                                Text {
                                    anchors.verticalCenter:
                                        parent.verticalCenter

                                    visible:
                                        searchInput.text === ""

                                    text:
                                        root.activeTab === 0
                                            ? "Buscar en el historial…"
                                            : "Buscar en fijados…"

                                    color: "#65675f"
                                    font.pixelSize: 12
                                }

                                TextInput {
                                    id: searchInput

                                    anchors.fill: parent

                                    verticalAlignment:
                                        TextInput.AlignVCenter

                                    color: "#d7d3c7"
                                    font.pixelSize: 12

                                    selectionColor: "#d5a84f"
                                    selectedTextColor: "#11120f"

                                    clip: true

                                    text:
                                        root.service.searchText

                                    onTextChanged: {
                                        if (
                                            root.service.searchText
                                            !== text
                                        ) {
                                            root.service.searchText =
                                                text
                                        }
                                    }

                                    Keys.onEscapePressed: {
                                        root.close()
                                    }
                                }
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            Layout.fillWidth: true

                            text:
                                root.currentModel.length
                                + (
                                    root.currentModel.length === 1
                                        ? " elemento"
                                        : " elementos"
                                )

                            color: "#65675f"
                            font.pixelSize: 10
                        }

                        Rectangle {
                            visible:
                                root.service.loading

                            Layout.preferredWidth: 8
                            Layout.preferredHeight: 8

                            radius: 4
                            color: "#d5a84f"

                            SequentialAnimation on opacity {
                                running:
                                    root.service.loading

                                loops:
                                    Animation.Infinite

                                NumberAnimation {
                                    to: 0.25
                                    duration: 400
                                }

                                NumberAnimation {
                                    to: 1
                                    duration: 400
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        color: "#34362f"
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        Text {
                            anchors.centerIn:
                                parent

                            visible:
                                !root.service.loading
                                && root.currentModel.length === 0

                            text:
                                root.service.searchText !== ""
                                    ? "󰍉\nNo se encontraron resultados"
                                    : (
                                        root.activeTab === 0
                                            ? "󰅌\nEl historial está vacío"
                                            : "󰐃\nNo tienes elementos fijados"
                                    )

                            horizontalAlignment:
                                Text.AlignHCenter

                            color: "#65675f"

                            font.pixelSize: 13
                            font.family:
                                "JetBrainsMono Nerd Font"
                        }

                        ListView {
                            id: clipboardList

                            anchors.fill: parent

                            visible:
                                root.currentModel.length > 0

                            model:
                                root.currentModel

                            spacing: 9
                            clip: true

                            boundsBehavior:
                                Flickable.StopAtBounds

                            delegate: Item {
                                id: delegateRoot

                                required property var modelData

                                width:
                                    clipboardList.width

                                height:
                                    itemLoader.item
                                        ? itemLoader.item.implicitHeight
                                        : 80

                                Loader {
                                    id: itemLoader

                                    anchors {
                                        left: parent.left
                                        right: parent.right
                                        top: parent.top
                                    }

                                    property var entryData:
                                        delegateRoot.modelData

                                    sourceComponent:
                                        entryData.isImage
                                            ? imageComponent
                                            : textComponent
                                }

                                Component {
                                    id: textComponent

                                    ClipboardItem {
                                        width:
                                            clipboardList.width

                                        entry:
                                            itemLoader.entryData

                                        pinnedView:
                                            root.activeTab === 1

                                        alreadyPinned:
                                            root.service.isPinned(
                                                itemLoader.entryData
                                            )

                                        onCopyRequested:
                                            function(entry) {
                                                root.copyItem(entry)
                                            }

                                        onDeleteRequested:
                                            function(entry) {
                                                root.service.deleteEntry(
                                                    entry
                                                )
                                            }

                                        onPinRequested:
                                            function(entry) {
                                                root.service.pinEntry(
                                                    entry
                                                )
                                            }

                                        onUnpinRequested:
                                            function(entry) {
                                                root.service.unpin(
                                                    entry
                                                )
                                            }
                                    }
                                }

                                Component {
                                    id: imageComponent

                                    ClipboardImageItem {
                                        width:
                                            clipboardList.width

                                        entry:
                                            itemLoader.entryData

                                        pinnedView:
                                            root.activeTab === 1

                                        alreadyPinned:
                                            root.service.isPinned(
                                                itemLoader.entryData
                                            )

                                        imageRevision:
                                            root.service.imageRevision

                                        onCopyRequested:
                                            function(entry) {
                                                root.copyItem(entry)
                                            }

                                        onDeleteRequested:
                                            function(entry) {
                                                root.service.deleteEntry(
                                                    entry
                                                )
                                            }

                                        onPinRequested:
                                            function(entry) {
                                                root.service.pinEntry(
                                                    entry
                                                )
                                            }

                                        onUnpinRequested:
                                            function(entry) {
                                                root.service.unpin(
                                                    entry
                                                )
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
            focus: clipboardWindow.visible

            Keys.onEscapePressed:
                root.close()
        }
    }
}
