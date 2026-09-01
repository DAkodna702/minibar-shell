import QtQuick
import Quickshell.Services.UPower

Rectangle {
    id: root

    implicitWidth: batteryRow.implicitWidth + 18
    height: 28
    radius: 9
    color: "transparent"

    property real batteryPercentage:
        UPower.displayDevice.ready
            ? UPower.displayDevice.percentage * 100
            : 0

    function batteryIcon() {
        if (!UPower.displayDevice.ready)
            return "󰂑"

        if (batteryPercentage >= 90)
            return "󰁹"

        if (batteryPercentage >= 70)
            return "󰂀"

        if (batteryPercentage >= 50)
            return "󰁾"

        if (batteryPercentage >= 30)
            return "󰁼"

        if (batteryPercentage >= 10)
            return "󰁺"

        return "󰂎"
    }

    function batteryColor() {
        if (!UPower.displayDevice.ready)
            return "#aaa89d"

        if (batteryPercentage <= 15)
            return "#d66d68"

        if (batteryPercentage <= 30)
            return "#d5a84f"

        return "#9eb39d"
    }

    Row {
        id: batteryRow

        anchors.centerIn: parent
        spacing: 6

        Text {
            text: root.batteryIcon()
            color: root.batteryColor()
            font.pixelSize: 15
            font.family: "JetBrainsMono Nerd Font"
        }

        Text {
            text: UPower.displayDevice.ready
                ? Math.round(root.batteryPercentage) + "%"
                : "--%"

            color: "#ece8dc"
            font.pixelSize: 12
            font.weight: Font.Medium
        }
    }
}
