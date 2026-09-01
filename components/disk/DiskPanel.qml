import QtQuick
import QtQuick.Layouts

import Quickshell
import Quickshell.Wayland

Item {
    id: root
    property var targetScreen: null

    required property var service

    readonly property bool opened:
        diskWindow.visible

    property string statusMessage: ""

    function open() {
        diskWindow.visible = true
        root.service.refresh()
    }

    function close() {
        diskWindow.visible = false
    }

    function toggle() {
        diskWindow.visible
            ? root.close()
            : root.open()
    }

    Connections {
        target: root.service

        function onRefreshed() {
            root.statusMessage = ""
        }

        function onErrorOccurred(message) {
            root.statusMessage = message
            statusTimer.restart()
        }
    }

    Timer {
        id: statusTimer

        interval: 3000
        repeat: false

        onTriggered: {
            root.statusMessage = ""
        }
    }

    PanelWindow {
        id: diskWindow
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
            "minibar-disk-panel"

        WlrLayershell.layer:
            WlrLayershell.Overlay

        WlrLayershell.exclusiveZone: -1

        WlrLayershell.keyboardFocus:
            diskWindow.visible
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
                height: Math.min(554, parent.height - 56)

                radius: 20
                color: "#f70b0c0a"

                border.width: 1
                border.color: "#4a4b42"

                MouseArea {
                    anchors.fill: parent
                }

                ColumnLayout {
                    anchors {
                        fill: parent
                        margins: 16
                    }

                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            Layout.fillWidth: true

                            text: "Almacenamiento"

                            color: "#ece8dc"
                            font.pixelSize: 19
                            font.bold: true
                        }

                        Rectangle {
                            Layout.preferredWidth: 30
                            Layout.preferredHeight: 30

                            radius: 10

                            color:
                                refreshMouse.containsMouse
                                    ? "#292a24"
                                    : "#171814"

                            Text {
                                anchors.centerIn: parent

                                text: "󰑐"
                                color: "#d5a84f"

                                font.pixelSize: 15
                                font.family:
                                    "JetBrainsMono Nerd Font"
                            }

                            MouseArea {
                                id: refreshMouse

                                anchors.fill: parent
                                hoverEnabled: true

                                cursorShape:
                                    Qt.PointingHandCursor

                                onClicked: {
                                    root.service.refresh()
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
                        Layout.preferredHeight: 92

                        radius: 16
                        color: "#151612"

                        border.width: 1

                        border.color:
                            root.service.usageColor(
                                root.service
                                    .primaryUsagePercent
                            )

                        RowLayout {
                            anchors {
                                fill: parent
                                margins: 14
                            }

                            spacing: 12

                            Rectangle {
                                Layout.preferredWidth: 50
                                Layout.preferredHeight: 50

                                radius: 15
                                color: "#34362f"

                                Text {
                                    anchors.centerIn: parent

                                    text: "󰋊"

                                    color:
                                        root.service.usageColor(
                                            root.service
                                                .primaryUsagePercent
                                        )

                                    font.pixelSize: 25
                                    font.family:
                                        "JetBrainsMono Nerd Font"
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4

                                Text {
                                    Layout.fillWidth: true

                                    text: "Disco principal"

                                    color: "#ece8dc"
                                    font.pixelSize: 14
                                    font.bold: true
                                }

                                Text {
                                    Layout.fillWidth: true

                                    text:
                                        root.service
                                            .primaryUsagePercent
                                        + "% utilizado"

                                    color:
                                        root.service.usageColor(
                                            root.service
                                                .primaryUsagePercent
                                        )

                                    font.pixelSize: 12
                                    font.bold: true
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 6

                                    radius: 3
                                    color: "#292a24"

                                    Rectangle {
                                        width:
                                            parent.width
                                            * Math.min(
                                                100,
                                                root.service
                                                    .primaryUsagePercent
                                            )
                                            / 100

                                        height: parent.height
                                        radius: parent.radius

                                        color:
                                            root.service.usageColor(
                                                root.service
                                                    .primaryUsagePercent
                                            )

                                        Behavior on width {
                                            NumberAnimation {
                                                duration: 250
                                                easing.type:
                                                    Easing.OutCubic
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        Layout.fillWidth: true

                        visible:
                            root.statusMessage !== ""

                        text: root.statusMessage

                        color: "#d66d68"
                        font.pixelSize: 10

                        horizontalAlignment:
                            Text.AlignHCenter

                        wrapMode: Text.Wrap
                    }

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            Layout.fillWidth: true

                            text: "Particiones"

                            color: "#ece8dc"
                            font.pixelSize: 13
                            font.bold: true
                        }

                        Text {
                            visible:
                                root.service.loading

                            text: "Actualizando…"

                            color: "#d5a84f"
                            font.pixelSize: 10
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        Text {
                            anchors.centerIn: parent

                            visible:
                                !root.service.loading
                                && root.service
                                    .partitions.length === 0

                            text:
                                "󰋊\nNo se encontró información"

                            horizontalAlignment:
                                Text.AlignHCenter

                            color: "#65675f"

                            font.pixelSize: 13
                            font.family:
                                "JetBrainsMono Nerd Font"
                        }

                        ListView {
                            id: diskList

                            anchors.fill: parent

                            visible:
                                root.service
                                    .partitions.length > 0

                            model:
                                root.service.partitions

                            spacing: 8
                            clip: true

                            boundsBehavior:
                                Flickable.StopAtBounds

                            delegate: DiskItem {
                                required property var modelData

                                width: diskList.width
                                partition: modelData
                            }
                        }
                    }
                }
            }
        }

        Item {
            anchors.fill: parent
            focus: diskWindow.visible

            Keys.onEscapePressed:
                root.close()
        }
    }

    component DiskItem: Rectangle {
        id: diskItem

        required property var partition

        implicitHeight: diskColumn.implicitHeight + 20

        radius: 14
        color: "#151612"

        border.width: 1
        border.color: "#34362f"

        ColumnLayout {
            id: diskColumn

            anchors {
                left: parent.left
                right: parent.right
                top: parent.top

                leftMargin: 10
                rightMargin: 10
                topMargin: 10
            }

            spacing: 7

            RowLayout {
                Layout.fillWidth: true
                spacing: 9

                Rectangle {
                    Layout.preferredWidth: 34
                    Layout.preferredHeight: 34

                    radius: 10
                    color: "#34362f"

                    Text {
                        anchors.centerIn: parent

                        text:
                            diskItem.partition.fstype
                            === "zfs"
                                ? "󰆼"
                                : "󰋊"

                        color:
                            root.service.usageColor(
                                diskItem.partition.percent
                            )

                        font.pixelSize: 17
                        font.family:
                            "JetBrainsMono Nerd Font"
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        Layout.fillWidth: true

                        text:
                            diskItem.partition.mount

                        color: "#ece8dc"
                        font.pixelSize: 12
                        font.bold: true

                        elide: Text.ElideMiddle
                    }

                    Text {
                        Layout.fillWidth: true

                        text:
                            diskItem.partition.device
                            + " · "
                            + diskItem.partition.fstype

                        color: "#65675f"
                        font.pixelSize: 9

                        elide: Text.ElideMiddle
                    }
                }

                Text {
                    text:
                        diskItem.partition.percent + "%"

                    color:
                        root.service.usageColor(
                            diskItem.partition.percent
                        )

                    font.pixelSize: 12
                    font.bold: true
                }
            }

            RowLayout {
                Layout.fillWidth: true

                Text {
                    Layout.fillWidth: true

                    text:
                        "Usado: "
                        + diskItem.partition.used
                        + " de "
                        + diskItem.partition.size

                    color: "#aaa89d"
                    font.pixelSize: 10
                }

                Text {
                    text:
                        "Libre: "
                        + diskItem.partition.available

                    color: "#9eb39d"
                    font.pixelSize: 10
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 5

                radius: 3
                color: "#292a24"

                Rectangle {
                    width:
                        parent.width
                        * Math.min(
                            100,
                            diskItem.partition.percent
                        )
                        / 100

                    height: parent.height
                    radius: parent.radius

                    color:
                        root.service.usageColor(
                            diskItem.partition.percent
                        )
                }
            }
        }
    }
}
