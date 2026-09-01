import QtQuick
import QtQuick.Layouts

import Quickshell
import Quickshell.Wayland

Item {
    id: root
    property var targetScreen: null

    required property var service

    readonly property bool opened:
        brightnessWindow.visible

    property string statusMessage: ""

    function open() {
        brightnessWindow.visible = true
        root.service.refresh()
    }

    function close() {
        brightnessWindow.visible = false
    }

    function toggle() {
        brightnessWindow.visible
            ? root.close()
            : root.open()
    }

    Connections {
        target: root.service

        function onErrorOccurred(message) {
            root.statusMessage = message
            messageTimer.restart()
        }
    }

    Timer {
        id: messageTimer

        interval: 3000
        repeat: false

        onTriggered: {
            root.statusMessage = ""
        }
    }

    PanelWindow {
        id: brightnessWindow
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
            "minibar-brightness-panel"

        WlrLayershell.layer:
            WlrLayershell.Overlay

        WlrLayershell.exclusiveZone: -1

        WlrLayershell.keyboardFocus:
            brightnessWindow.visible
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
                anchors {
                    top: parent.top
                    right: parent.right
                    topMargin: 48
                    rightMargin: 8
                    bottomMargin: 8
                }

                width: Math.min(424, parent.width - 16)
                height: Math.min(454, parent.height - 56)

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

                    spacing: 13

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            Layout.fillWidth: true

                            text: "Brillo de pantallas"

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

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        Text {
                            anchors.centerIn: parent

                            visible:
                                !root.service.loading
                                && root.service.displays.length
                                    === 0

                            text:
                                "󰃞\nNo se detectaron pantallas controlables"

                            horizontalAlignment:
                                Text.AlignHCenter

                            color: "#65675f"

                            font.pixelSize: 13
                            font.family:
                                "JetBrainsMono Nerd Font"
                        }

                        ListView {
                            id: displayList

                            anchors.fill: parent

                            visible:
                                root.service.displays.length
                                > 0

                            model: root.service.displays

                            spacing: 10
                            clip: true

                            boundsBehavior:
                                Flickable.StopAtBounds

                            delegate: DisplayBrightnessCard {
                                required property var modelData

                                width: displayList.width
                                display: modelData
                            }
                        }
                    }
                }
            }
        }

        Item {
            anchors.fill: parent
            focus: brightnessWindow.visible

            Keys.onEscapePressed:
                root.close()
        }
    }

    component DisplayBrightnessCard: Rectangle {
        id: card

        required property var display

        implicitHeight:
            cardColumn.implicitHeight + 22

        radius: 16
        color: "#151612"

        border.width: 1
        border.color: "#3a3b34"

        ColumnLayout {
            id: cardColumn

            anchors {
                left: parent.left
                right: parent.right
                top: parent.top

                leftMargin: 11
                rightMargin: 11
                topMargin: 11
            }

            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Rectangle {
                    Layout.preferredWidth: 38
                    Layout.preferredHeight: 38

                    radius: 11
                    color: "#4a4533"

                    Text {
                        anchors.centerIn: parent

                        text:
                            root.service.brightnessIcon(
                                card.display.percent
                            )

                        color: "#d5a84f"

                        font.pixelSize: 19
                        font.family:
                            "JetBrainsMono Nerd Font"
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        Layout.fillWidth: true

                        text: card.display.name

                        color: "#ece8dc"
                        font.pixelSize: 13
                        font.bold: true

                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true

                        text:
                            card.display.type
                            === "internal"
                                ? card.display.device
                                : "DDC/CI · Display "
                                    + card.display
                                        .displayNumber

                        color: "#65675f"
                        font.pixelSize: 9

                        elide: Text.ElideRight
                    }
                }

                Text {
                    text:
                        Math.round(
                            card.display.percent
                        ) + "%"

                    color: "#d5a84f"

                    font.pixelSize: 13
                    font.bold: true
                }
            }

            BrightnessSlider {
                Layout.fillWidth: true

                value: card.display.percent

                onMovedByUser:
                    function(newValue) {
                        root.service
                            .setDisplayBrightness(
                                card.display,
                                newValue
                            )
                    }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Repeater {
                    model: [10, 25, 50, 75, 100]

                    delegate: Rectangle {
                        required property int modelData

                        Layout.fillWidth: true
                        Layout.preferredHeight: 29

                        radius: 9

                        color:
                            Math.abs(
                                card.display.percent
                                - modelData
                            ) < 3
                                ? "#d5a84f"
                                : quickMouse.containsMouse
                                    ? "#292a24"
                                    : "#171814"

                        Text {
                            anchors.centerIn: parent

                            text: modelData + "%"

                            color:
                                Math.abs(
                                    card.display.percent
                                    - modelData
                                ) < 3
                                    ? "#11120f"
                                    : "#ece8dc"

                            font.pixelSize: 9
                            font.bold: true
                        }

                        MouseArea {
                            id: quickMouse

                            anchors.fill: parent
                            hoverEnabled: true

                            cursorShape:
                                Qt.PointingHandCursor

                            onClicked: {
                                root.service
                                    .setDisplayBrightness(
                                        card.display,
                                        modelData
                                    )
                            }
                        }
                    }
                }
            }
        }
    }

    component BrightnessSlider: Item {
        id: slider

        property real value: 0

        signal movedByUser(real newValue)

        implicitHeight: 25

        function valueFromPosition(positionX) {
            if (slider.width <= 0)
                return 1

            return Math.max(
                1,
                Math.min(
                    100,
                    positionX
                    / slider.width
                    * 100
                )
            )
        }

        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                verticalCenter: parent.verticalCenter
            }

            height: 6
            radius: 3
            color: "#292a24"

            Rectangle {
                width:
                    parent.width
                    * Math.max(
                        0,
                        Math.min(
                            100,
                            slider.value
                        )
                    )
                    / 100

                height: parent.height
                radius: parent.radius

                color: "#d5a84f"
            }
        }

        Rectangle {
            width: 17
            height: 17
            radius: 9

            y:
                parent.height / 2
                - height / 2

            x:
                Math.max(
                    0,
                    Math.min(
                        slider.width - width,
                        slider.value
                        / 100
                        * (slider.width - width)
                    )
                )

            color: "#d5a84f"

            border.width: 2
            border.color: "#11120f"
        }

        MouseArea {
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
                const change =
                    wheel.angleDelta.y > 0
                        ? 5
                        : -5

                slider.movedByUser(
                    Math.max(
                        1,
                        Math.min(
                            100,
                            slider.value + change
                        )
                    )
                )

                wheel.accepted = true
            }
        }
    }
}
