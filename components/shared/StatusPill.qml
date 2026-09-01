import QtQuick

Rectangle {
    id: root

    property string symbol: ""

    width: 30
    height: 28
    radius: 9
    color: "#151612"

    Text {
        anchors.centerIn: parent
        text: root.symbol
        color: "#ece8dc"
        font.pixelSize: 15
        font.family: "JetBrainsMono Nerd Font"
    }
}
