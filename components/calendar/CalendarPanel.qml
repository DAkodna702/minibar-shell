import QtQuick
import QtQuick.Layouts

import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Item {
    id: root
    property var targetScreen: null

    readonly property bool opened: calendarWindow.visible
    property date now: new Date()
    property int viewYear: now.getFullYear()
    property int viewMonth: now.getMonth()
    property int revision: 0

    readonly property var dayCells: {
        void root.revision
        const first = new Date(root.viewYear, root.viewMonth, 1)
        const mondayOffset = (first.getDay() + 6) % 7
        const start = new Date(root.viewYear, root.viewMonth, 1 - mondayOffset)
        const cells = []

        for (let index = 0; index < 42; index++) {
            const date = new Date(
                start.getFullYear(),
                start.getMonth(),
                start.getDate() + index
            )

            cells.push({
                day: date.getDate(),
                month: date.getMonth(),
                year: date.getFullYear(),
                currentMonth: date.getMonth() === root.viewMonth,
                today: date.getDate() === root.now.getDate()
                    && date.getMonth() === root.now.getMonth()
                    && date.getFullYear() === root.now.getFullYear()
            })
        }

        return cells
    }

    function open() { calendarWindow.visible = true }
    function close() { calendarWindow.visible = false }
    function toggle() { opened ? close() : open() }

    function moveMonth(delta) {
        const next = new Date(root.viewYear, root.viewMonth + delta, 1)
        root.viewYear = next.getFullYear()
        root.viewMonth = next.getMonth()
        root.revision++
    }

    function goToday() {
        root.now = new Date()
        root.viewYear = root.now.getFullYear()
        root.viewMonth = root.now.getMonth()
        root.revision++
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            const previousDay = root.now.getDate()
            root.now = new Date()
            if (previousDay !== root.now.getDate())
                root.revision++
        }
    }

    PanelWindow {
        id: calendarWindow
        screen: root.targetScreen
        visible: false
        color: "transparent"
        anchors { top: true; bottom: true; left: true; right: true }
        WlrLayershell.namespace: "minibar-calendar"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.exclusiveZone: -1

        Rectangle {
            anchors.fill: parent
            color: "#59050605"
            MouseArea { anchors.fill: parent; onClicked: root.close() }
        }

        Rectangle {
            anchors { top: parent.top; horizontalCenter: parent.horizontalCenter; topMargin: 52 }
            width: Math.min(370, parent.width - 24)
            height: 430
            radius: 18
            color: "#f50b0c0a"
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
                        Text {
                            text: Qt.formatDateTime(root.now, "hh:mm:ss")
                            color: "#ece8dc"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 28
                            font.weight: Font.Light
                        }
                        Text {
                            text: Qt.formatDateTime(root.now, "dddd, dd 'de' MMMM")
                            color: "#8f9086"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 10
                        }
                    }
                    Text {
                        text: "×"
                        color: closeMouse.containsMouse ? "#d5a84f" : "#aaa89d"
                        font.pixelSize: 20
                        MouseArea { id: closeMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.close() }
                    }
                }

                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: "#31322c" }

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "‹"
                        color: previousMouse.containsMouse ? "#d5a84f" : "#c9c6ba"
                        font.pixelSize: 24
                        MouseArea { id: previousMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.moveMonth(-1) }
                    }
                    Text {
                        Layout.fillWidth: true
                        text: Qt.formatDateTime(new Date(root.viewYear, root.viewMonth, 1), "MMMM yyyy").toUpperCase()
                        color: "#ece8dc"
                        horizontalAlignment: Text.AlignHCenter
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 12
                        font.letterSpacing: 1.5
                    }
                    Text {
                        text: "›"
                        color: nextMouse.containsMouse ? "#d5a84f" : "#c9c6ba"
                        font.pixelSize: 24
                        MouseArea { id: nextMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.moveMonth(1) }
                    }
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 7
                    columnSpacing: 2
                    rowSpacing: 4

                    Repeater {
                        model: ["LU", "MA", "MI", "JU", "VI", "SÁ", "DO"]
                        Text {
                            required property string modelData
                            Layout.fillWidth: true
                            Layout.preferredHeight: 22
                            text: modelData
                            color: "#65675f"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 8
                        }
                    }

                    Repeater {
                        model: root.dayCells
                        Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.preferredHeight: 34
                            radius: 9
                            color: modelData.today ? "#d5a84f" : "transparent"
                            border.width: modelData.today ? 0 : 1
                            border.color: modelData.currentMonth ? "#292a25" : "transparent"
                            Text {
                                anchors.centerIn: parent
                                text: modelData.day
                                color: modelData.today ? "#0b0c09" : modelData.currentMonth ? "#d7d3c7" : "#4e5049"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 10
                                font.weight: modelData.today ? Font.Bold : Font.Normal
                            }
                        }
                    }
                }

                Item { Layout.fillHeight: true }

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 92
                    Layout.preferredHeight: 30
                    radius: 9
                    color: todayMouse.containsMouse ? "#292a24" : "#171814"
                    border.width: 1
                    border.color: "#3b3c34"
                    Text { anchors.centerIn: parent; text: "HOY"; color: "#d5a84f"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 9; font.letterSpacing: 1 }
                    MouseArea { id: todayMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.goToday() }
                }
            }
        }
    }
}
