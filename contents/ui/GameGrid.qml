import QtQuick

GridView {
    id: grid

    clip: true

    property int columns: 2
    property int cardHeight: 120

    cellWidth: width / columns
    cellHeight: cardHeight + 10

    model: []

    delegate: Item {
        width: grid.cellWidth - 10
        height: grid.cardHeight

        Rectangle {
            anchors.fill: parent

            radius: 8
            color: "#202020"
            border.color: "#444444"
            border.width: 1
            clip: true

            Image {
                id: gameLogo

                anchors.fill: parent
                anchors.margins: 12

                visible: modelData.image !== undefined
                         && modelData.image !== null
                         && modelData.image !== ""

                source: visible
                    ? "file://" + modelData.image
                    : ""

                fillMode: Image.PreserveAspectFit
                asynchronous: true
                cache: true
            }

            Text {
                anchors.centerIn: parent
                width: parent.width - 20

                visible: !gameLogo.visible

                color: "white"
                text: modelData.name
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.Wrap
            }
        }
    }
}
