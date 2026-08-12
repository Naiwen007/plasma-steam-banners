import QtQuick
import QtQuick.Controls as QQC2
import SteamBanners.Process

GridView {
    id: grid

    clip: true

    property int columns: 2
    property int cardHeight: 120

    cellWidth: width / columns
    cellHeight: cardHeight + 10

    model: []

    Process {
        id: launcher

        onErrorOccurred: function(error) {
            console.log("### STEAM LAUNCH ERROR:", error)
        }

        onFinished: function(exitCode) {
            console.log("### STEAM LAUNCH FINISHED:", exitCode)
        }
    }

    delegate: Item {
        id: delegateRoot

        width: grid.cellWidth - 10
        height: grid.cardHeight

        scale: mouseArea.pressed ? 0.97 : 1.0

        Behavior on scale {
            NumberAnimation {
                duration: 80
                easing.type: Easing.OutQuad
            }
        }

        Rectangle {
            id: card

            anchors.fill: parent

            radius: 8
            color: mouseArea.containsMouse ? "#303030" : "#202020"
            border.color: mouseArea.containsMouse ? "#777777" : "#444444"
            border.width: 1
            clip: true

            Behavior on color {
                ColorAnimation {
                    duration: 120
                }
            }

            Behavior on border.color {
                ColorAnimation {
                    duration: 120
                }
            }

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

            MouseArea {
                id: mouseArea

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                onClicked: {
                    console.log(
                        "### LAUNCHING:",
                        modelData.name,
                        modelData.appid
                    )

                    launcher.start(
                        "steam",
                        ["steam://rungameid/" + modelData.appid]
                    )
                }
            }

            QQC2.ToolTip {
                visible: mouseArea.containsMouse
                delay: 600
                text: modelData.name
            }
        }
    }
}
