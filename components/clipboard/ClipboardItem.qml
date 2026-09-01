import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    required property var entry

    property bool pinnedView: false
    property bool alreadyPinned: false

    signal copyRequested(var entry)
    signal deleteRequested(var entry)
    signal pinRequested(var entry)
    signal unpinRequested(var entry)

    width: parent ? parent.width : 370

    implicitHeight:
        contentLayout.implicitHeight + 20

    radius: 14

    color: cardMouse.containsMouse
        ? "#20211c"
        : "#151612"

    border.width: 1

    border.color: root.pinnedView
        ? "#5d5680"
        : (
            cardMouse.containsMouse
                ? "#4a5262"
                : "#34362f"
        )

    Behavior on color {
        ColorAnimation {
            duration: 120
        }
    }

    RowLayout {
        id: contentLayout

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top

            leftMargin: 10
            rightMargin: 10
            topMargin: 10
        }

        spacing: 9

        Rectangle {
            Layout.preferredWidth: 34
            Layout.preferredHeight: 34

            radius: 10

            color: root.pinnedView
                ? "#413b59"
                : "#34362f"

            Text {
                anchors.centerIn: parent

                text: root.pinnedView
                    ? "󰐃"
                    : "󰅌"

                color: root.pinnedView
                    ? "#b6a07a"
                    : "#d5a84f"

                font.pixelSize: 16
                font.family:
                    "JetBrainsMono Nerd Font"
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3

            Text {
                Layout.fillWidth: true

                text: root.entry
                    && root.entry.preview
                        ? root.entry.preview
                        : "(contenido vacío)"

                color: "#d7d3c7"
                font.pixelSize: 12

                wrapMode: Text.Wrap
                textFormat: Text.PlainText

                maximumLineCount: 5
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true

                text: root.pinnedView
                    ? "Texto fijado"
                    : "Texto del historial"

                color: "#65675f"
                font.pixelSize: 9
            }
        }

        // Copiar.
        Rectangle {
            Layout.preferredWidth: 28
            Layout.preferredHeight: 28

            radius: 9

            color: copyMouse.containsMouse
                ? "#25251f"
                : "transparent"

            Text {
                anchors.centerIn: parent

                text: "󰆏"

                color: copyMouse.containsMouse
                    ? "#d5a84f"
                    : "#aaa89d"

                font.pixelSize: 14
                font.family:
                    "JetBrainsMono Nerd Font"
            }

            MouseArea {
                id: copyMouse

                anchors.fill: parent
                hoverEnabled: true

                cursorShape:
                    Qt.PointingHandCursor

                onClicked: function(mouse) {
                    root.copyRequested(root.entry)
                    mouse.accepted = true
                }
            }
        }

        // Fijar o desfijar.
        Rectangle {
            Layout.preferredWidth: 28
            Layout.preferredHeight: 28

            radius: 9

            color: pinMouse.containsMouse
                ? "#413b59"
                : "transparent"

            Text {
                anchors.centerIn: parent

                text: root.pinnedView
                    || root.alreadyPinned
                        ? "󰐃"
                        : "󰐂"

                color: root.pinnedView
                    || root.alreadyPinned
                        ? "#b6a07a"
                        : "#aaa89d"

                font.pixelSize: 14
                font.family:
                    "JetBrainsMono Nerd Font"
            }

            MouseArea {
                id: pinMouse

                anchors.fill: parent
                hoverEnabled: true

                enabled:
                    root.pinnedView
                    || !root.alreadyPinned

                cursorShape:
                    enabled
                        ? Qt.PointingHandCursor
                        : Qt.ArrowCursor

                onClicked: function(mouse) {
                    if (root.pinnedView)
                        root.unpinRequested(root.entry)
                    else if (!root.alreadyPinned)
                        root.pinRequested(root.entry)

                    mouse.accepted = true
                }
            }
        }

        // Eliminar solo del historial.
        Rectangle {
            visible: !root.pinnedView

            Layout.preferredWidth: visible ? 28 : 0
            Layout.preferredHeight: 28

            radius: 9

            color: deleteMouse.containsMouse
                ? "#4a3038"
                : "transparent"

            Text {
                anchors.centerIn: parent

                text: "󰆴"

                color: deleteMouse.containsMouse
                    ? "#d66d68"
                    : "#aaa89d"

                font.pixelSize: 14
                font.family:
                    "JetBrainsMono Nerd Font"
            }

            MouseArea {
                id: deleteMouse

                anchors.fill: parent
                hoverEnabled: true

                cursorShape:
                    Qt.PointingHandCursor

                onClicked: function(mouse) {
                    root.deleteRequested(root.entry)
                    mouse.accepted = true
                }
            }
        }
    }

    MouseArea {
        id: cardMouse

        anchors.fill: parent
        z: -1

        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: {
            root.copyRequested(root.entry)
        }
    }
}
