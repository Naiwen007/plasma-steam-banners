import QtQuick

GridView {
    id: grid

    clip: true

    property int columns: 2

    cellWidth: width / columns
    cellHeight: cellWidth * 0.62

    model: []

    delegate: Rectangle {
        width: grid.cellWidth - 10
        height: grid.cellHeight - 10

        radius: 8
        color: "#202020"
        border.color: "#444444"
        border.width: 1

        Text {
            anchors.centerIn: parent

            width: parent.width - 20

            color: "white"
            text: modelData.name
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
        }
    }
}
