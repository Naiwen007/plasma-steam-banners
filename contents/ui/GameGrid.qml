import QtQuick
import QtQuick.Controls as QQC2
import SteamBanners.Process

GridView {
    id: grid

    clip: true

    property int columns: 2
    property int cardHeight: 120
    property int sortMode: 0

    property var games: []
    property string favoritesString: ""
    property var sortedGames: []

    cellWidth: width / columns
    cellHeight: cardHeight + 10

    model: sortedGames

    function favoriteIds() {
        if (!favoritesString || favoritesString === "") {
            return []
        }

        return favoritesString
            .split(",")
            .filter(function(id) {
                return id !== ""
            })
    }

    function isFavorite(appid) {
        return favoriteIds().indexOf(String(appid)) !== -1
    }

    function toggleFavorite(appid) {
        var key = String(appid)
        var ids = favoriteIds()
        var index = ids.indexOf(key)

        if (index !== -1) {
            ids.splice(index, 1)
        } else {
            ids.push(key)
        }

        ids.sort()
        favoritesString = ids.join(",")

        rebuildModel()
    }

    function compareNames(a, b) {
        var nameA = (a.name || "").toLowerCase()
        var nameB = (b.name || "").toLowerCase()

        if (nameA < nameB) {
            return -1
        }

        if (nameA > nameB) {
            return 1
        }

        return 0
    }

    function rebuildModel() {
        var result = []

        if (!games) {
            sortedGames = result
            return
        }

        for (var i = 0; i < games.length; ++i) {
            var game = games[i]

            if (sortMode === 2 && !isFavorite(game.appid)) {
                continue
            }

            result.push(game)
        }

        result.sort(function(a, b) {
            if (sortMode === 1) {
                var favoriteA = isFavorite(a.appid)
                var favoriteB = isFavorite(b.appid)

                if (favoriteA && !favoriteB) {
                    return -1
                }

                if (!favoriteA && favoriteB) {
                    return 1
                }
            }

            return compareNames(a, b)
        })

        sortedGames = result
    }

    onGamesChanged: rebuildModel()
    onSortModeChanged: rebuildModel()
    onFavoritesStringChanged: rebuildModel()

    Component.onCompleted: rebuildModel()

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
            color: "#151515"
            border.color: grid.isFavorite(modelData.appid)
                ? "#d6a400"
                : (mouseArea.containsMouse ? "#777777" : "#444444")

            border.width: grid.isFavorite(modelData.appid) ? 2 : 1
            clip: true

            Behavior on border.color {
                ColorAnimation {
                    duration: 120
                }
            }

            Image {
                id: heroImage

                anchors.fill: parent

                visible: modelData.hero !== undefined
                         && modelData.hero !== null
                         && modelData.hero !== ""

                source: visible
                    ? "file://" + modelData.hero
                    : ""

                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
            }

            Rectangle {
                anchors.fill: parent

                color: mouseArea.containsMouse
                    ? "#52000000"
                    : "#70000000"

                Behavior on color {
                    ColorAnimation {
                        duration: 120
                    }
                }
            }

            Image {
                id: gameLogo

                anchors.fill: parent
                anchors.margins: 14

                visible: modelData.logo !== undefined
                         && modelData.logo !== null
                         && modelData.logo !== ""

                source: visible
                    ? "file://" + modelData.logo
                    : ""

                fillMode: Image.PreserveAspectFit
                asynchronous: true
                cache: true
            }

            Text {
                anchors.centerIn: parent
                width: parent.width - 24

                visible: !gameLogo.visible

                color: "white"
                text: modelData.name

                font.pixelSize: 18
                font.bold: true

                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.Wrap
            }

            Text {
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: 8

                visible: grid.isFavorite(modelData.appid)

                text: "★"
                color: "#ffd54a"
                font.pixelSize: 18
            }

            QQC2.Menu {
                id: contextMenu

                QQC2.MenuItem {
                    text: grid.isFavorite(modelData.appid)
                        ? i18n("Ta bort från favoriter")
                        : i18n("Markera som favorit")

                    onTriggered: {
                        grid.toggleFavorite(modelData.appid)
                    }
                }
            }

            MouseArea {
                id: mouseArea

                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                cursorShape: Qt.PointingHandCursor

                onClicked: function(mouse) {
                    if (mouse.button === Qt.RightButton) {
                        contextMenu.popup()
                        return
                    }

                    if (mouse.button === Qt.LeftButton) {
                        launcher.start(
                            "steam",
                            ["steam://rungameid/" + modelData.appid]
                        )
                    }
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
