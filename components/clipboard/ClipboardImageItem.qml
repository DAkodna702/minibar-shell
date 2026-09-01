import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    required property var entry

    property bool pinnedView: false
    property bool alreadyPinned: false
    property int imageRevision: 0

    signal copyRequested(var entry)
    signal deleteRequested(var entry)
    signal pinRequested(var entry)
    signal unpinRequested(var entry)

    width: parent ? parent.width : 370

    implicitHeight:
        imageColumn.implicitHeight + 20

    radius: 16

    color: imageMouse.containsMouse
        ? "#20211c"
        : "#151612"

    border.width: 1

    border.color: root.pinnedView
        ? "#5d5680"
        : (
            imageMouse.containsMouse
                ? "#4a5262"
                : "#34362f"
        )

    function imageSource() {
        if (
            !root.entry
            || !root.entry.imagePath
            || root.entry.imagePath === ""
        ) {
            return ""
        }

        return "file://"
            + root.entry.imagePath
            + "?revision="
            + root.imageRevision
    }

    ColumnLayout {
        id: imageColumn

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top

            leftMargin: 10
            rightMargin: 10
            topMargin: 10
        }

        spacing: 9

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32

                radius: 9

                color: root.pinnedView
                    ? "#413b59"
                    : "#34362f"

                Text {
                    anchors.centerIn: parent

                    text: root.pinnedView
                        ? "󰐃"
                        : "󰋩"

                    color: root.pinnedView
                        ? "#b6a07a"
                        : "#d5a84f"

                    font.pixelSize: 15
                    font.family:
                        "JetBrainsMono Nerd Font"
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    Layout.fillWidth: true

                    text: "Imagen copiada"

                    color: "#d7d3c7"
                    font.pixelSize: 12
                    font.bold: true
                }

                Text {
                    Layout.fillWidth: true

                    text: root.pinnedView
                        ? "Imagen fijada"
                        : "Imagen del historial"

                    color: "#65675f"
                    font.pixelSize: 9
                }
            }

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

            Rectangle {
                visible: !root.pinnedView

                Layout.preferredWidth:
                    visible ? 28 : 0

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

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 170

            radius: 12
            color: "#11120f"

            clip: true

            Image {
                id: previewImage

                anchors.fill: parent

                source: root.imageSource()

                // Decode a preview instead of the full-resolution capture.
                sourceSize: Qt.size(480, 240)

                fillMode:
                    Image.PreserveAspectFit

                asynchronous: true
                cache: false
                smooth: true
                mipmap: true

                visible:
                    status === Image.Ready
            }

            Text {
                anchors.centerIn: parent

                visible:
                    previewImage.status
                    !== Image.Ready

                text: previewImage.status
                    === Image.Loading
                        ? "Cargando imagen…"
                        : "󰋩\nVista previa no disponible"

                horizontalAlignment:
                    Text.AlignHCenter

                color: "#65675f"

                font.pixelSize: 12
                font.family:
                    "JetBrainsMono Nerd Font"
            }

            MouseArea {
                id: imageMouse

                anchors.fill: parent
                hoverEnabled: true

                cursorShape:
                    Qt.PointingHandCursor

                onClicked: {
                    root.copyRequested(root.entry)
                }
            }
        }
    }
}
