import QtQuick
import QtQuick.Controls as QQC2
import Qt5Compat.GraphicalEffects

GridView {
    id: grid

    clip: true

    property int columns: 2
    property int cardHeight: 120
    property int artworkRevision: 0
    property int singleArtworkRevision: 0
    property int refreshedAppid: 0
    property var artworkRevisionByAppid: ({})
    property var heroOverrideByAppid: ({})
    property var logoOverrideByAppid: ({})
    property var manualHeroSelectionState: ({})
    property var manualLogoSelectionState: ({})
    property int sortMode: 0
    property string searchText: ""
    property string genreFilter: ""
    property string storeFilter: ""
    property bool scanBusy: false
    property int refreshingAppid: 0

    signal refreshArtworkRequested(int appid)
    signal chooseHeroRequested(int appid)
    signal chooseLogoRequested(int appid)
    signal clearHeroSelectionRequested(int appid)
    signal clearLogoSelectionRequested(int appid)
    signal launchRequested(var game)

    property var games: []
    property string favoritesString: ""
    property var sortedGames: []
    property var availableGenres: []

    cellWidth: width / columns
    cellHeight: cardHeight + 10

    model: sortedGames

    function gameKey(value) {
        if (
            value
            && typeof value === "object"
        ) {
            if (value.gameId) {
                return String(value.gameId)
            }

            if (
                value.appid !== undefined
                && value.appid !== null
            ) {
                return (
                    "steam:"
                    + String(value.appid)
                )
            }

            return ""
        }

        var text = String(
            value !== undefined
            && value !== null
            ? value
            : ""
        )

        if (text === "") {
            return ""
        }

        if (text.indexOf(":") !== -1) {
            return text
        }

        return "steam:" + text
    }

    function gameStore(game) {
        if (!game) {
            return ""
        }

        if (
            game.store !== undefined
            && game.store !== null
            && String(game.store) !== ""
        ) {
            return String(
                game.store
            ).toLowerCase()
        }

        if (
            game.appid !== undefined
            && game.appid !== null
        ) {
            return "steam"
        }

        return ""
    }

    function isSteamGame(game) {
        if (!game) {
            return false
        }

        if (
            game.provider !== undefined
            && game.provider !== null
            && String(game.provider) !== ""
        ) {
            return (
                String(game.provider).toLowerCase()
                === "steam"
            )
        }

        return (
            game.appid !== undefined
            && game.appid !== null
        )
    }

    function artworkVersion(value) {
        var key = gameKey(value)
        var gameRevision =
        artworkRevisionByAppid[key] || 0

        return artworkRevision + "-" + gameRevision
    }

    function refreshSingleArtwork(appid) {
        var key = gameKey(appid)
        var revisions = Object.assign(
            {},
            artworkRevisionByAppid
        )

        singleArtworkRevision += 1
        refreshedAppid = Number(appid)

        revisions[key] = singleArtworkRevision
        artworkRevisionByAppid = revisions
    }

    function setArtworkOverride(
        appid,
        artworkType,
        path
    ) {
        var key = gameKey(appid)

        if (artworkType === "hero") {
            var heroes = Object.assign(
                {},
                heroOverrideByAppid
            )

            heroes[key] = path
            heroOverrideByAppid = heroes

        } else if (artworkType === "logo") {
            var logos = Object.assign(
                {},
                logoOverrideByAppid
            )

            logos[key] = path
            logoOverrideByAppid = logos
        }

        refreshSingleArtwork(appid)
    }

    function clearArtworkOverride(
        appid,
        artworkType
    ) {
        var key = gameKey(appid)

        if (artworkType === "hero") {
            var heroes = Object.assign(
                {},
                heroOverrideByAppid
            )

            delete heroes[key]
            heroOverrideByAppid = heroes

        } else if (artworkType === "logo") {
            var logos = Object.assign(
                {},
                logoOverrideByAppid
            )

            delete logos[key]
            logoOverrideByAppid = logos
        }

        refreshSingleArtwork(appid)
    }

    function hasManualArtworkSelection(
        game,
        artworkType
    ) {
        var key = gameKey(game)

        if (artworkType === "hero") {
            if (
                manualHeroSelectionState[key]
                !== undefined
            ) {
                return manualHeroSelectionState[key]
            }

            return game.manualHeroSelection === true
        }

        if (artworkType === "logo") {
            if (
                manualLogoSelectionState[key]
                !== undefined
            ) {
                return manualLogoSelectionState[key]
            }

            return game.manualLogoSelection === true
        }

        return false
    }

    function setManualArtworkSelection(
        appid,
        artworkType,
        selected
    ) {
        var key = gameKey(appid)

        if (artworkType === "hero") {
            var heroes = Object.assign(
                {},
                manualHeroSelectionState
            )

            heroes[key] = selected === true
            manualHeroSelectionState = heroes

        } else if (artworkType === "logo") {
            var logos = Object.assign(
                {},
                manualLogoSelectionState
            )

            logos[key] = selected === true
            manualLogoSelectionState = logos
        }
    }

    function heroPath(game) {
        var key = gameKey(game)

        return heroOverrideByAppid[key]
        || game.hero
        || ""
    }

    function logoPath(game) {
        var key = gameKey(game)

        return logoOverrideByAppid[key]
        || game.logo
        || ""
    }

    function favoriteIds() {
        if (
            !favoritesString
            || favoritesString === ""
        ) {
            return []
        }

        var normalized = []

        favoritesString
        .split(",")
        .filter(function(id) {
            return id !== ""
        })
        .forEach(function(id) {
            var key = gameKey(id)

            if (
                key !== ""
                && normalized.indexOf(key) === -1
            ) {
                normalized.push(key)
            }
        })

        return normalized
    }

    function isFavorite(value) {
        var key = gameKey(value)

        if (key === "") {
            return false
        }

        return favoriteIds().indexOf(key) !== -1
    }

    function toggleFavorite(value) {
        var key = gameKey(value)

        if (key === "") {
            return
        }

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

    function rebuildGenres() {
        var result = []
        var seen = {}

        if (!games) {
            availableGenres = result
            return
        }

        for (var i = 0; i < games.length; ++i) {
            var genres = games[i].genres || []

            for (var j = 0; j < genres.length; ++j) {
                var genre = genres[j]

                if (
                    genre
                    && genre !== ""
                    && !seen[genre]
                ) {
                    seen[genre] = true
                    result.push(genre)
                }
            }
        }

        result.sort(function(a, b) {
            return a.localeCompare(b)
        })

        availableGenres = result

        if (
            genreFilter !== ""
            && result.indexOf(genreFilter) === -1
        ) {
            genreFilter = ""
        }
    }

    function rebuildModel() {
        var result = []

        if (!games) {
            sortedGames = result
            return
        }

        for (var i = 0; i < games.length; ++i) {
            var game = games[i]

            if (sortMode === 2 && !isFavorite(game)) {
                continue
            }

            if (
                storeFilter !== ""
                && gameStore(game) !== storeFilter
            ) {
                continue
            }

            if (genreFilter !== "") {
                var genres = game.genres || []

                if (genres.indexOf(genreFilter) === -1) {
                    continue
                }
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
                var favoriteA = isFavorite(a)
                var favoriteB = isFavorite(b)

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

    onGamesChanged: {
        rebuildGenres()
        rebuildModel()
    }

    onSortModeChanged: rebuildModel()
    onFavoritesStringChanged: rebuildModel()
    onSearchTextChanged: rebuildModel()
    onGenreFilterChanged: rebuildModel()
    onStoreFilterChanged: rebuildModel()

    Component.onCompleted: {
        rebuildGenres()
        rebuildModel()
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

        // Outer glow for hover and favorites
        Rectangle {
            anchors.fill: card
            anchors.margins: -3

            radius: card.radius + 3
            color: "transparent"

            border.width:
            grid.isFavorite(modelData)
            ? 2
            : 1

            border.color:
            grid.isFavorite(modelData)
            ? "#ffd34e"
            : "#28a9e8"

            opacity:
            grid.isFavorite(modelData)
            ? (mouseArea.containsMouse ? 0.90 : 0.60)
            : (mouseArea.containsMouse ? 0.55 : 0.0)

            Behavior on opacity {
                NumberAnimation {
                    duration: 140
                }
            }

            Behavior on border.color {
                ColorAnimation {
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

            border.color: grid.isFavorite(modelData)
                ? "#d5a72b"
                : (mouseArea.containsMouse
                    ? "#45b9ee"
                    : "#304859")

            border.width: grid.isFavorite(modelData) ? 2 : 1

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

                visible:
                    grid.heroPath(modelData) !== ""

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
                    ? "file://" + grid.heroPath(modelData)
                        + "?v=" + grid.artworkVersion(modelData)
                    : ""

                    fillMode: Image.PreserveAspectCrop

                    asynchronous: true
                    cache: false
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

                visible:
                    grid.logoPath(modelData) !== ""

                source: visible
                ? "file://" + grid.logoPath(modelData)
                    + "?v=" + grid.artworkVersion(modelData)
                : ""

                fillMode: Image.PreserveAspectFit

                asynchronous: true
                cache: false
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
            // FAVORITE HIGHLIGHT
            // ----------------------------------------------------

            Rectangle {
                z: 4

                anchors.fill: parent
                anchors.margins: 1

                radius: card.radius - 1

                visible: grid.isFavorite(modelData)

                color: Qt.rgba(
                    1.0,
                    0.78,
                    0.15,
                    mouseArea.containsMouse ? 0.08 : 0.04
                )

                border.width: 2
                border.color: "#ffd34e"

                opacity:
                mouseArea.containsMouse
                ? 1.0
                : 0.82

                Behavior on opacity {
                    NumberAnimation {
                        duration: 140
                    }
                }
            }

            // ----------------------------------------------------
            // FAVORITE STAR
            // ----------------------------------------------------

            Text {
                anchors.top: parent.top
                anchors.right: parent.right

                anchors.topMargin: 7
                anchors.rightMargin: 9

                z: 5

                visible: grid.isFavorite(modelData)

                text: "★"
                color: "#ffd34e"

                font.pixelSize: 22

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
            // SINGLE GAME REFRESH INDICATOR
            // ----------------------------------------------------

            Rectangle {
                z: 6

                anchors.left: parent.left
                anchors.bottom: parent.bottom

                anchors.leftMargin: 9
                anchors.bottomMargin: 8

                height: 28
                width: refreshRow.implicitWidth + 18

                radius: 7

                visible:
                grid.refreshingAppid > 0
                && Number(modelData.appid) === grid.refreshingAppid

                color: "#d9081219"

                border.width: 1
                border.color: "#45b9ee"

                Row {
                    id: refreshRow

                    anchors.centerIn: parent

                    spacing: 6

                    QQC2.BusyIndicator {
                        width: 16
                        height: 16

                        running: parent.parent.visible
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter

                        text: i18n("Refreshing...")
                        color: "#f2f6f9"

                        font.pixelSize: 11
                        font.bold: true
                    }
                }
            }

            // ----------------------------------------------------
            // CONTEXT MENU
            // ----------------------------------------------------

            QQC2.Menu {
                id: steamContextMenu

                QQC2.MenuItem {
                    text: grid.isFavorite(modelData)
                    ? i18n("Remove from favorites")
                    : i18n("Add to favorites")

                    onTriggered: {
                        grid.toggleFavorite(modelData)
                    }
                }

                QQC2.MenuSeparator {}

                QQC2.MenuItem {
                    text: i18n("Refresh artwork")

                    enabled: !grid.scanBusy

                    onTriggered: {
                        grid.refreshArtworkRequested(
                            modelData.appid
                        )
                    }
                }

                QQC2.Menu {
                    title: i18n("Hero artwork")

                    QQC2.MenuItem {
                        text: i18n("Choose...")

                        enabled: !grid.scanBusy

                        onTriggered: {
                            grid.chooseHeroRequested(
                                modelData.appid
                            )
                        }
                    }

                    QQC2.MenuItem {
                        text: i18n("Use automatic")

                        enabled:
                        !grid.scanBusy
                        && grid.hasManualArtworkSelection(
                            modelData,
                            "hero"
                        )

                        onTriggered: {
                            grid.clearHeroSelectionRequested(
                                modelData.appid
                            )
                        }
                    }
                }

                QQC2.Menu {
                    title: i18n("Logo artwork")

                    QQC2.MenuItem {
                        text: i18n("Choose...")

                        enabled: !grid.scanBusy

                        onTriggered: {
                            grid.chooseLogoRequested(
                                modelData.appid
                            )
                        }
                    }

                    QQC2.MenuItem {
                        text: i18n("Use automatic")

                        enabled:
                        !grid.scanBusy
                        && grid.hasManualArtworkSelection(
                            modelData,
                            "logo"
                        )

                        onTriggered: {
                            grid.clearLogoSelectionRequested(
                                modelData.appid
                            )
                        }
                    }
                }
            }


            QQC2.Menu {
                id: heroicContextMenu

                QQC2.MenuItem {
                    text: grid.isFavorite(modelData)
                    ? i18n("Remove from favorites")
                    : i18n("Add to favorites")

                    onTriggered: {
                        grid.toggleFavorite(modelData)
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
                        if (grid.isSteamGame(modelData)) {
                            steamContextMenu.popup()
                        } else {
                            heroicContextMenu.popup()
                        }

                        return
                    }

                    if (mouse.button === Qt.LeftButton) {
                        grid.launchRequested(modelData)
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
