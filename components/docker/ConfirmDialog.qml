import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    property bool opened: false
    property string title: "Confirmar"
    property string message: ""
    property string confirmText: "Eliminar"
    property bool danger: true

    signal confirmed()
    signal cancelled()

    visible: opened

    color: "#99000000"

    MouseArea {
        anchors.fill: parent

        onClicked: {
            root.opened = false
            root.cancelled()
        }
    }

    Rectangle {
        anchors.centerIn: parent

        width: 390
        height:
            dialogColumn.implicitHeight + 34

        radius: 20
        color: "#11120f"

        border.width: 1
        border.color:
            root.danger
                ? "#d66d68"
                : "#d5a84f"

        MouseArea {
            anchors.fill: parent
        }

        ColumnLayout {
            id: dialogColumn

            anchors {
                left: parent.left
                right: parent.right
                top: parent.top

                leftMargin: 17
                rightMargin: 17
                topMargin: 17
            }

            spacing: 12

            Text {
                Layout.fillWidth: true

                text: root.title

                color: "#ece8dc"
                font.pixelSize: 16
                font.bold: true
            }

            Text {
                Layout.fillWidth: true

                text: root.message

                color: "#ece8dc"
                font.pixelSize: 12

                wrapMode: Text.Wrap
                textFormat: Text.PlainText
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                DialogButton {
                    Layout.fillWidth: true

                    text: "Cancelar"

                    onClicked: {
                        root.opened = false
                        root.cancelled()
                    }
                }

                DialogButton {
                    Layout.fillWidth: true

                    text: root.confirmText
                    danger: root.danger

                    onClicked: {
                        root.opened = false
                        root.confirmed()
                    }
                }
            }
        }
    }

    component DialogButton: Rectangle {
        id: dialogButton

        property string text: ""
        property bool danger: false

        signal clicked()

        Layout.preferredHeight: 38

        radius: 12

        color: {
            if (buttonMouse.containsMouse) {
                return dialogButton.danger
                    ? "#5a3540"
                    : "#25251f"
            }

            return dialogButton.danger
                ? "#4a3038"
                : "#171814"
        }

        Text {
            anchors.centerIn: parent

            text: dialogButton.text

            color:
                dialogButton.danger
                    ? "#d66d68"
                    : "#ece8dc"

            font.pixelSize: 11
            font.bold: true
        }

        MouseArea {
            id: buttonMouse

            anchors.fill: parent
            hoverEnabled: true

            cursorShape:
                Qt.PointingHandCursor

            onClicked: dialogButton.clicked()
        }
    }
}
