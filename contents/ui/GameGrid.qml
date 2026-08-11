import QtQuick

GridView {
    id: grid

    clip: true

    cellWidth: 180
    cellHeight: 110

    model: []

    delegate: Rectangle {
        width: 170
        height: 100

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
