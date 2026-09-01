import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Item {
    id: root

    property alias server: notificationServer

    property var latestNotification: null
    property int unreadCount: 0
    property int maxTrackedNotifications: 50

    signal popupRequested(var notification)

    function markAllRead() {
        unreadCount = 0
    }

    function clearAll() {
        const notifications =
            notificationServer.trackedNotifications.values

        // Se recorre al revés porque dismiss elimina elementos.
        for (let i = notifications.length - 1; i >= 0; i--) {
            const notification = notifications[i]

            if (notification)
                notification.dismiss()
        }

        unreadCount = 0
        latestNotification = null
    }

    function notificationCount() {
        return notificationServer.trackedNotifications.values.length
    }

    function enforceHistoryLimit() {
        const notifications =
            notificationServer.trackedNotifications.values
        const excess =
            notifications.length - root.maxTrackedNotifications

        for (let i = 0; i < excess; i++) {
            const notification = notifications[i]

            if (notification)
                notification.dismiss()
        }
    }

    NotificationServer {
        id: notificationServer

        bodySupported: true
        bodyMarkupSupported: false
        bodyHyperlinksSupported: false

        imageSupported: true
        bodyImagesSupported: true

        actionsSupported: true
        actionIconsSupported: true

        persistenceSupported: true
        keepOnReload: true

        onNotification: function(notification) {
            /*
             * Es obligatorio marcarla como tracked.
             * De lo contrario Quickshell la descarta.
             */
            notification.tracked = true

            root.latestNotification = notification
            root.unreadCount += 1

            console.log(
                "Nueva notificación:",
                notification.appName,
                notification.summary
            )

            root.popupRequested(notification)

            Qt.callLater(root.enforceHistoryLimit)
        }
    }
}
