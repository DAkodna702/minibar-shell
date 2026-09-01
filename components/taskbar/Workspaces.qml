import QtQuick
import Quickshell.Hyprland

Row {
    id: root

    property int workspaceCount: 10

    spacing: 5

    Repeater {
        model: root.workspaceCount

        delegate: Rectangle {
            required property int index

            property int workspaceNumber: index + 1

            property bool activeWorkspace:
                Hyprland.focusedWorkspace !== null
                && Hyprland.focusedWorkspace.id === workspaceNumber

            width: activeWorkspace ? 26 : 18
            height: 24
            radius: 8

            color: activeWorkspace
                ? "#d5a84f"
                : "#151612"

            Behavior on width {
                NumberAnimation {
                    duration: 150
                }
            }

            Text {
                anchors.centerIn: parent

                text: workspaceNumber

                color: parent.activeWorkspace
                    ? "#11120f"
                    : "#aaa89d"

                font.pixelSize: 11
                font.bold: parent.activeWorkspace
            }

            // Sin acciones por ahora.
        }
    }
}
