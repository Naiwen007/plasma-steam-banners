import QtQuick
import QtQuick.Controls as QQC2
import SteamBanners.Process
import Qt5Compat.GraphicalEffects

GridView {
    id: grid

    clip: true

    property int columns: 2
    property int cardHeight: 120
    property int sortMode: 0
    property string searchText: ""

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

            var query = searchText.trim().toLowerCase()

            if (
                query !== ""
                && (game.name || "").toLowerCase().indexOf(query) === -1
            ) {
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
    onSearchTextChanged: rebuildModel()

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

        width: grid.cellWidth
        height: grid.cardHeight

        scale: mouseArea.pressed ? 0.988 : 1.0

        Behavior on scale {
            NumberAnimation {
                duration: 80
                easing.type: Easing.OutQuad
            }
        }

        // Subtle outer glow on hover
        Rectangle {
            anchors.fill: card
            anchors.margins: -2

            radius: card.radius + 2
            color: "transparent"

            border.width: 1
            border.color: "#28a9e8"

            opacity: mouseArea.containsMouse ? 0.55 : 0.0

            Behavior on opacity {
                NumberAnimation {
                    duration: 140
                }
            }
        }

        // 3D depth behind card
        Rectangle {
            id: cardDepth

            x: card.x + 3
            y: card.y + 4

            width: card.width
            height: card.height

            radius: card.radius

            color: mouseArea.containsMouse
            ? "#0c384a"
            : "#050d13"

            border.color: mouseArea.containsMouse
            ? "#1d6d8d"
            : "#102530"

            Behavior on color {
                ColorAnimation {
                    duration: 140
                }
            }

            Behavior on border.color {
                ColorAnimation {
                    duration: 140
                }
            }
        }

        Rectangle {
            id: card

            anchors.fill: parent
            anchors.leftMargin: 5
            anchors.rightMargin: 5

            transform: Translate {
                x: mouseArea.pressed ? 2 : 0
                y: mouseArea.pressed
                    ? 2
                    : mouseArea.containsMouse
                        ? -1
                        : 0

                Behavior on x {
                    NumberAnimation {
                        duration: 70
                    }
                }

                Behavior on y {
                    NumberAnimation {
                        duration: 70
                    }
                }
            }

            radius: 9
            color: "#0c151d"

            border.color: grid.isFavorite(modelData.appid)
                ? "#d5a72b"
                : (mouseArea.containsMouse
                    ? "#45b9ee"
                    : "#304859")

            border.width: grid.isFavorite(modelData.appid) ? 2 : 1

            clip: true

            Behavior on border.color {
                ColorAnimation {
                    duration: 140
                }
            }

            // ----------------------------------------------------
            // HERO BACKGROUND
            // ----------------------------------------------------

            Item {
                id: heroContainer

                anchors.fill: parent
                visible: modelData.hero !== undefined
                && modelData.hero !== null
                && modelData.hero !== ""

                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width: heroContainer.width
                        height: heroContainer.height
                        radius: card.radius
                    }
                }

                Image {
                    id: heroImage

                    anchors.fill: parent

                    source: heroContainer.visible
                    ? "file://" + modelData.hero
                    : ""

                    fillMode: Image.PreserveAspectCrop

                    asynchronous: true
                    cache: true
                    smooth: true
                }

                // Dark cinematic overlay
                Rectangle {
                    anchors.fill: parent

                    gradient: Gradient {
                        GradientStop {
                            position: 0.0
                            color: mouseArea.containsMouse
                            ? "#28040a10"
                            : "#3a040a10"
                        }

                        GradientStop {
                            position: 0.55
                            color: mouseArea.containsMouse
                            ? "#38050b11"
                            : "#50050b11"
                        }

                        GradientStop {
                            position: 1.0
                            color: mouseArea.containsMouse
                            ? "#6202070b"
                            : "#7802070b"
                        }
                    }
                }

                // Slight blue tint
                Rectangle {
                    anchors.fill: parent

                    color: "#08192a"
                    opacity: mouseArea.containsMouse ? 0.08 : 0.14

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 140
                        }
                    }
                }
            }

            // ----------------------------------------------------
            // GAME LOGO
            // ----------------------------------------------------

            // Tight 3D depth
            DropShadow {

                anchors.fill: gameLogo
                source: gameLogo

                horizontalOffset: 4
                verticalOffset: 4

                radius: 3
                samples: 7
                spread: 0.35

                color: "#80304452"
                transparentBorder: true

                z: 1
            }

            Image {
                id: gameLogo

                z: 2

                anchors.centerIn: parent
                anchors.fill: parent

                anchors.leftMargin: 10
                anchors.rightMargin: 10
                anchors.topMargin: 7
                anchors.bottomMargin: 7

                visible: modelData.logo !== undefined
                         && modelData.logo !== null
                         && modelData.logo !== ""

                source: visible
                    ? "file://" + modelData.logo
                    : ""

                fillMode: Image.PreserveAspectFit

                asynchronous: true
                cache: true
                smooth: true

                opacity: mouseArea.containsMouse ? 1.0 : 0.94

                Behavior on opacity {
                    NumberAnimation {
                        duration: 140
                    }
                }
            }

            // Fallback when SteamGridDB has no logo
            Text {
                anchors.centerIn: parent

                width: parent.width - 32

                visible: !gameLogo.visible

                color: "#f2f6f9"
                text: modelData.name

                font.pixelSize: 18
                font.bold: true
                font.letterSpacing: 0.5

                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.Wrap
            }

            // ----------------------------------------------------
            // FAVORITE STAR
            // ----------------------------------------------------

            Text {
                anchors.top: parent.top
                anchors.right: parent.right

                anchors.topMargin: 7
                anchors.rightMargin: 9

                visible: grid.isFavorite(modelData.appid)

                text: "★"
                color: "#ffd34e"

                font.pixelSize: 18

                style: Text.Outline
                styleColor: "#66000000"
            }

            // Soft top bevel highlight
            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top

                height: 8

                color: "transparent"

                gradient: Gradient {
                    GradientStop {
                        position: 0.0
                        color: mouseArea.containsMouse
                        ? "#806bdcff"
                        : "#40477184"
                    }

                    GradientStop {
                        position: 0.45
                        color: mouseArea.containsMouse
                        ? "#306bdcff"
                        : "#20477184"
                    }

                    GradientStop {
                        position: 1.0
                        color: "#00477184"
                    }
                }

                opacity: mouseArea.containsMouse ? 0.75 : 0.55

                Behavior on opacity {
                    NumberAnimation {
                        duration: 140
                    }
                }
            }

            // ----------------------------------------------------
            // CONTEXT MENU
            // ----------------------------------------------------

            QQC2.Menu {
                id: contextMenu

                QQC2.MenuItem {
                    text: grid.isFavorite(modelData.appid)
                        ? i18n("Remove from favorites")
                        : i18n("Add to favorites")

                    onTriggered: {
                        grid.toggleFavorite(modelData.appid)
                    }
                }
            }

            // ----------------------------------------------------
            // INTERACTION
            // ----------------------------------------------------

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
