import QtQuick

// Creates a panel only while it is open. When the panel hides itself (for
// example after clicking its backdrop), release its complete QML object tree.
Loader {
    id: root

    property bool unloadOnClose: true

    active: false

    onLoaded: {
        if (root.item && !root.item.opened)
            root.item.open()
    }

    Connections {
        target: root.item
        ignoreUnknownSignals: true

        function onOpenedChanged() {
            const panel = root.item

            if (!panel || panel.opened)
                return

            Qt.callLater(function() {
                if (
                    root.unloadOnClose
                    && root.item === panel
                    && !panel.opened
                ) {
                    root.active = false
                }
            })
        }
    }
}
