import QtQuick

import Quickshell
import Quickshell.Wayland

Item {
    id: root

    required property var service

    property var currentNotification: null

    function showNotification(notification) {
        if (!notification)
            return

        currentNotification = notification
        popupWindow.visible = true
        hideTimer.restart()
    }

    function hidePopup() {
        popupWindow.visible = false
    }

    Connections {
        target: root.service

        function onPopupRequested(notification) {
            root.showNotification(notification)
        }
    }

    Timer {
        id: hideTimer

        interval: 6000
        repeat: false

        onTriggered: root.hidePopup()
    }

    PanelWindow {
        id: popupWindow

        visible: false
        color: "transparent"

        implicitWidth: 390
        implicitHeight:
            popupCard.visible
                ? popupCard.implicitHeight + 24
                : 100

        anchors {
            top: true
            right: true
        }

        WlrLayershell.namespace: "minibar-notification-popup"
        WlrLayershell.layer: WlrLayershell.Overlay
        WlrLayershell.exclusiveZone: -1
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        Rectangle {
            anchors.fill: parent
            color: "transparent"

            NotificationCard {
                id: popupCard

                visible: root.currentNotification !== null

                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top

                    leftMargin: 12
                    rightMargin: 12
                    topMargin: 12
                }

                notification: root.currentNotification

                onDismissed: {
                    root.hidePopup()
                }
            }
        }
    }
}
