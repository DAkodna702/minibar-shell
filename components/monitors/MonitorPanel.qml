import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

Item {
    id: root
    required property var service
    property var targetScreen: null
    readonly property bool opened: monitorWindow.visible

    function open() { monitorWindow.visible = true; service.refresh() }
    function close() { monitorWindow.visible = false; service.identifying = false }
    function toggle() { opened ? close() : open() }

    PanelWindow {
        id: monitorWindow
        screen: root.targetScreen
        visible: false
        color: "transparent"
        anchors { top: true; bottom: true; left: true; right: true }
        WlrLayershell.namespace: "minibar-monitor-manager"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.exclusiveZone: -1
        WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        Rectangle {
            anchors.fill: parent
            color: "#66050605"
            MouseArea { anchors.fill: parent; onClicked: root.close() }
        }

        Rectangle {
            anchors { top: parent.top; horizontalCenter: parent.horizontalCenter; topMargin: 54 }
            width: Math.min(720, parent.width - 28)
            height: Math.min(650, parent.height - 70)
            radius: 20
            color: "#f70b0c0a"
            border.width: 1
            border.color: "#4a4b42"
            clip: true
            MouseArea { anchors.fill: parent }

            Rectangle { anchors { top: parent.top; left: parent.left; right: parent.right } height: 3; color: "#d5a84f" }

            ColumnLayout {
                anchors { fill: parent; margins: 18 }
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 2
                        Text { text: "MONITORES"; color: "#ece8dc"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 17; font.weight: Font.DemiBold }
                        Text { text: "Resolución · Hz · escala · orientación · brillo"; color: "#77796f"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 9 }
                    }
                    Rectangle {
                        Layout.preferredWidth: 112; Layout.preferredHeight: 32; radius: 9
                        color: identifyMouse.containsMouse || root.service.identifying ? "#3a3320" : "#191a16"
                        border.width: 1; border.color: root.service.identifying ? "#d5a84f" : "#3a3c34"
                        Text { anchors.centerIn: parent; text: root.service.identifying ? "OCULTAR Nº" : "󰍹  IDENTIFICAR"; color: "#d5a84f"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 8 }
                        MouseArea { id: identifyMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.service.identifying = !root.service.identifying }
                    }
                    Text {
                        text: "×"; color: closeMouse.containsMouse ? "#d5a84f" : "#aaa89d"; font.pixelSize: 21
                        MouseArea { id: closeMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.close() }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: "El orden de las tarjetas será el orden físico. La resolución marcada con ★ es la nativa; los cambios se revierten si no confirmas en 15 segundos."
                    wrapMode: Text.WordWrap; color: "#929489"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 9
                }

                Flickable {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    contentHeight: monitorColumn.implicitHeight; clip: true

                    Column {
                        id: monitorColumn
                        width: parent.width
                        spacing: 9

                        Repeater {
                            model: root.service.monitors
                            delegate: Rectangle {
                                id: monitorCard
                                required property var modelData
                                required property int index
                                width: monitorColumn.width; height: 242; radius: 14
                                color: "#141511"; border.width: 1; border.color: "#34362f"

                                RowLayout {
                                    anchors { fill: parent; margins: 12 }
                                    spacing: 12

                                    Rectangle {
                                        Layout.preferredWidth: 54; Layout.fillHeight: true; radius: 11
                                        color: "#1d1e18"; border.width: 1; border.color: "#4a4637"
                                        Column { anchors.centerIn: parent; spacing: 4
                                            Text { anchors.horizontalCenter: parent.horizontalCenter; text: index + 1; color: "#d5a84f"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 28; font.weight: Font.Bold }
                                            Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.name; color: "#77796f"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 7 }
                                        }
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true; Layout.fillHeight: true; spacing: 7
                                        RowLayout {
                                            Layout.fillWidth: true
                                            ColumnLayout { Layout.fillWidth: true; spacing: 1
                                                Text { text: root.service.friendlyName(modelData); color: "#e4e0d5"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11; font.weight: Font.DemiBold }
                                                Text { text: modelData.width + "×" + modelData.height + " · " + modelData.refreshRate.toFixed(2) + " Hz · escala " + modelData.scale.toFixed(2); color: "#77796f"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 8 }
                                            }
                                            Rectangle {
                                                Layout.preferredWidth: 29; Layout.preferredHeight: 27; radius: 8; color: leftMouse.containsMouse ? "#302b1d" : "#1d1e19"; opacity: index > 0 ? 1 : 0.3
                                                Text { anchors.centerIn: parent; text: "←"; color: "#d5a84f"; font.pixelSize: 15 }
                                                MouseArea { id: leftMouse; anchors.fill: parent; enabled: index > 0; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.service.move(index, -1) }
                                            }
                                            Rectangle {
                                                Layout.preferredWidth: 29; Layout.preferredHeight: 27; radius: 8; color: rightMouse.containsMouse ? "#302b1d" : "#1d1e19"; opacity: index < root.service.monitors.length - 1 ? 1 : 0.3
                                                Text { anchors.centerIn: parent; text: "→"; color: "#d5a84f"; font.pixelSize: 15 }
                                                MouseArea { id: rightMouse; anchors.fill: parent; enabled: index < root.service.monitors.length - 1; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.service.move(index, 1) }
                                            }
                                        }

                                        RowLayout {
                                            Layout.fillWidth: true
                                            Text { text: "Resolución"; color: "#77796f"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 8; Layout.preferredWidth: 82 }
                                            Flickable {
                                                Layout.fillWidth: true; Layout.preferredHeight: 27
                                                contentWidth: resolutionRow.implicitWidth
                                                contentHeight: height
                                                clip: true
                                                boundsBehavior: Flickable.StopAtBounds
                                                Row {
                                                    id: resolutionRow
                                                    spacing: 5
                                                    Repeater {
                                                        model: root.service.resolutionsFor(monitorCard.modelData)
                                                        delegate: Rectangle {
                                                            id: resolutionButton
                                                            required property string modelData
                                                            readonly property bool active: modelData === monitorCard.modelData.selectedResolution
                                                            readonly property bool nativeMode: modelData === root.service.nativeResolution(monitorCard.modelData)
                                                            width: 106; height: 25; radius: 7
                                                            color: active ? "#d5a84f" : "#20211c"
                                                            border.width: 1; border.color: active ? "#d5a84f" : nativeMode ? "#746641" : "#383a32"
                                                            Text { anchors.centerIn: parent; text: resolutionButton.modelData.replace("x", "×") + (resolutionButton.nativeMode ? " ★" : ""); color: resolutionButton.active ? "#11120e" : "#aaa99f"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 8; font.weight: Font.Bold }
                                                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.service.chooseResolution(monitorCard.modelData.name, resolutionButton.modelData) }
                                                        }
                                                    }
                                                }
                                            }
                                        }

                                        RowLayout {
                                            Layout.fillWidth: true
                                            Text { text: "Frecuencia"; color: "#77796f"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 8; Layout.preferredWidth: 82 }
                                            Repeater {
                                                model: root.service.modesForSelection(monitorCard.modelData)
                                                delegate: Rectangle {
                                                    id: modeButton
                                                    required property string modelData
                                                    Layout.preferredWidth: 58; Layout.preferredHeight: 25; radius: 7
                                                    color: modelData === monitorCard.modelData.selectedMode ? "#d5a84f" : "#20211c"
                                                    border.width: 1; border.color: modelData === monitorCard.modelData.selectedMode ? "#d5a84f" : "#383a32"
                                                    Text { anchors.centerIn: parent; text: Number(modeButton.modelData.split("@")[1]).toFixed(0) + " Hz"; color: modeButton.color === "#d5a84f" ? "#11120e" : "#aaa99f"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 8; font.weight: Font.Bold }
                                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.service.chooseMode(monitorCard.modelData.name, modeButton.modelData) }
                                                }
                                            }
                                            Item { Layout.fillWidth: true }
                                            Text { text: modelData.selectedMode; color: "#8e8f85"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 8 }
                                        }

                                        RowLayout {
                                            Layout.fillWidth: true
                                            Text { text: "Escala"; color: "#77796f"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 8; Layout.preferredWidth: 82 }
                                            Repeater {
                                                model: [1, 1.25, 1.5, 1.75, 2]
                                                delegate: Rectangle {
                                                    id: scaleButton
                                                    required property real modelData
                                                    readonly property bool active: Math.abs(modelData - monitorCard.modelData.selectedScale) < 0.01
                                                    Layout.preferredWidth: 48; Layout.preferredHeight: 25; radius: 7
                                                    color: active ? "#d5a84f" : "#20211c"
                                                    border.width: 1; border.color: active ? "#d5a84f" : "#383a32"
                                                    Text { anchors.centerIn: parent; text: Number(scaleButton.modelData).toFixed(scaleButton.modelData === 1 || scaleButton.modelData === 2 ? 0 : 2) + "×"; color: scaleButton.active ? "#11120e" : "#aaa99f"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 8; font.weight: Font.Bold }
                                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.service.chooseScale(monitorCard.modelData.name, scaleButton.modelData) }
                                                }
                                            }
                                            Item { Layout.fillWidth: true }
                                        }

                                        RowLayout {
                                            Layout.fillWidth: true
                                            Text { text: "Orientación"; color: "#77796f"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 8; Layout.preferredWidth: 82 }
                                            Repeater {
                                                model: [
                                                    { value: 0, label: "Horizontal" },
                                                    { value: 1, label: "90°" },
                                                    { value: 2, label: "180°" },
                                                    { value: 3, label: "270°" }
                                                ]
                                                delegate: Rectangle {
                                                    id: rotationButton
                                                    required property var modelData
                                                    readonly property bool active: modelData.value === monitorCard.modelData.selectedRotation
                                                    Layout.preferredWidth: 58; Layout.preferredHeight: 25; radius: 7
                                                    color: active ? "#d5a84f" : "#20211c"
                                                    border.width: 1; border.color: active ? "#d5a84f" : "#383a32"
                                                    Text { anchors.centerIn: parent; text: rotationButton.modelData.label; color: rotationButton.active ? "#11120e" : "#aaa99f"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 8; font.weight: Font.Bold }
                                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.service.chooseRotation(monitorCard.modelData.name, rotationButton.modelData.value) }
                                                }
                                            }
                                            Item { Layout.fillWidth: true }
                                        }

                                        RowLayout {
                                            Layout.fillWidth: true
                                            Text { text: modelData.internal ? "Brillo real" : "Atenuación"; color: "#77796f"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 8; Layout.preferredWidth: 82 }
                                            Rectangle {
                                                Layout.fillWidth: true; Layout.preferredHeight: 5; radius: 3; color: "#30312b"
                                                Rectangle { width: parent.width * root.service.brightnessFor(modelData.name) / 100; height: parent.height; radius: 3; color: "#d5a84f" }
                                                MouseArea {
                                                    anchors { left: parent.left; right: parent.right; top: parent.top; bottom: parent.bottom; topMargin: -9; bottomMargin: -9 }
                                                    cursorShape: Qt.PointingHandCursor
                                                    function update(mouse) { root.service.setBrightness(modelData.name, Math.round(Math.max(0, Math.min(width, mouse.x)) / width * 100)) }
                                                    onPressed: function(mouse) { update(mouse) }
                                                    onPositionChanged: function(mouse) { if (pressed) update(mouse) }
                                                }
                                            }
                                            Text { Layout.preferredWidth: 34; horizontalAlignment: Text.AlignRight; text: root.service.brightnessFor(modelData.name) + "%"; color: "#d7d3c7"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 8 }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true; Layout.preferredHeight: root.service.statusMessage === "" ? 0 : 34; visible: height > 0; radius: 9
                    color: root.service.statusError ? "#351d1c" : "#1c241b"; border.width: 1; border.color: root.service.statusError ? "#70403d" : "#3e513d"
                    Text { anchors { fill: parent; leftMargin: 10; rightMargin: 10 } verticalAlignment: Text.AlignVCenter; text: root.service.statusMessage; color: root.service.statusError ? "#df8c86" : "#a9b7a0"; elide: Text.ElideRight; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 8 }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Text { Layout.fillWidth: true; text: "SUPER+1/2/3: espacio local · SUPER+CTRL+←/→: cambiar monitor"; color: "#6f7168"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 8 }
                    Rectangle {
                        visible: root.service.pendingConfirmation; Layout.preferredWidth: 100; Layout.preferredHeight: 34; radius: 9; color: "#2a1d1b"; border.width: 1; border.color: "#74433f"
                        Text { anchors.centerIn: parent; text: "REVERTIR"; color: "#d9847e"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 8; font.weight: Font.Bold }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.service.revert() }
                    }
                    Rectangle {
                        Layout.preferredWidth: root.service.pendingConfirmation ? 160 : 130; Layout.preferredHeight: 34; radius: 9; color: "#d5a84f"
                        Text { anchors.centerIn: parent; text: root.service.pendingConfirmation ? "CONFIRMAR · " + root.service.secondsRemaining + "s" : "APLICAR CAMBIOS"; color: "#10110d"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 8; font.weight: Font.Bold }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.service.pendingConfirmation ? root.service.confirm() : root.service.apply() }
                    }
                }
            }
        }
    }
}
