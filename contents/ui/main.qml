import QtQuick
import QtQuick.Controls as QQC2
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import SteamBanners.Process

PlasmoidItem {
    id: root

    implicitWidth: 600
    implicitHeight: 500

    property bool apiKeyAvailable: true
    property int apiNoticeHeight: apiKeyAvailable ? 0 : 64

    property bool searchOpen: false

    property bool noGamesFound:
    !scanner.scanning
    && scanner.games.length === 0

    property bool noFavoritesFound:
    !scanner.scanning
    && scanner.games.length > 0
    && gameGrid.sortMode === 2
    && gameGrid.sortedGames.length === 0
    && searchField.text.trim() === ""

    property bool noSearchResults:
    !scanner.scanning
    && scanner.games.length > 0
    && searchField.text.trim() !== ""
    && gameGrid.sortedGames.length === 0

    FontLoader {
        id: orbitronFont
        source: "../fonts/Orbitron Bold.ttf"

        onStatusChanged: {
            console.log(
                "### ORBITRON FONT ###",
                status,
                name
            )
        }
    }

    // ============================================================
    // API KEY CHECK
    // ============================================================

    Process {
        id: apiKeyChecker

        onOutputReady: function(output) {
            root.apiKeyAvailable = output.trim() === "1"
        }

        onErrorOccurred: function(error) {
            console.log(
                "### API KEY CHECK ERROR:",
                error
            )

            root.apiKeyAvailable = false
        }
    }

    // ============================================================
    // STEAM SCANNER
    // ============================================================

    SteamScanner {
        id: scanner

        onScanFinished: {
            console.log("### SCAN FINISHED ###")
            console.log(
                "Games:",
                scanner.games.length
            )
        }
    }

    // ============================================================
    // BACKGROUND
    // ============================================================

    Rectangle {
        anchors.fill: parent
        color: "#080d12"
    }

    // ============================================================
    // NEW RESPONSIVE HEADER
    // ============================================================

    Rectangle {
        id: headerArea

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right

        height: 150

        radius: 12

        color: "#06121a"

        border.color: "#28576d"
        border.width: 1

        // ============================================================
        // GRADIENT
        // ============================================================

        gradient: Gradient {
            orientation: Gradient.Horizontal

            GradientStop { position: 0.00; color: "#06121a" }
            GradientStop { position: 0.36; color: "#06121a" }
            GradientStop { position: 0.43; color: "#0a2430" }
            GradientStop { position: 0.47; color: "#0d3342" }
            GradientStop { position: 0.50; color: "#104456" }
            GradientStop { position: 0.53; color: "#0d3342" }
            GradientStop { position: 0.57; color: "#0a2430" }
            GradientStop { position: 0.64; color: "#06121a" }
            GradientStop { position: 1.00; color: "#06121a" }
        }

        // --------------------------------------------------------
        // Subtle top glow
        // --------------------------------------------------------

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.leftMargin: 12
            anchors.rightMargin: 12

            height: 1

            color: "#28d9ff"
            opacity: 0.25
        }

        // --------------------------------------------------------
        // Subtle lower glow
        // --------------------------------------------------------

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: 12
            anchors.rightMargin: 12

            height: 2

            color: "#28d9ff"
            opacity: 0.55
        }

        // --------------------------------------------------------
        // LEFT: STEAM LOGO
        // --------------------------------------------------------

        Item {
            id: steamLogoArea

            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom

            width: 140

            Rectangle {
                id: steamGlow

                anchors.centerIn: parent

                width: 120
                height: 120

                radius: width / 2

                color: "#22cfff"
                opacity: 0.12
            }

            Rectangle {
                anchors.centerIn: parent

                width: 118
                height: 118

                radius: width / 2

                color: "#1c9fd0"
                opacity: 0.12
            }

            Rectangle {
                id: steamCircle

                anchors.centerIn: parent

                width: 104
                height: 104

                radius: width / 2

                color: "#071722"

                border.color: "#49dfff"
                border.width: 2

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 5

                    radius: width / 2

                    color: "#061019"

                    border.color: "#2a6f8d"
                    border.width: 1
                }

                Kirigami.Icon {
                    anchors.centerIn: parent

                    width: 68
                    height: 68

                    source: "steam"
                }
            }
        }

        // --------------------------------------------------------
        // RIGHT: 2x2 BUTTON GRID
        // --------------------------------------------------------

        Grid {
            id: headerButtons

            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter

            columns: 2

            rowSpacing: 7
            columnSpacing: 7

            // ====================================================
            // SEARCH
            // ====================================================

            QQC2.ToolButton {
                id: searchButton

                width: 40
                height: 40

                display: QQC2.AbstractButton.IconOnly

                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: 30
                    height: 30
                    source: "search"
                }

                onClicked: {
                    root.searchOpen = !root.searchOpen

                    if (root.searchOpen) {
                        Qt.callLater(function() {
                            searchField.forceActiveFocus()
                        })
                    }
                }

                background: Rectangle {
                    radius: 8

                    color: searchButton.down
                    ? "#12384a"
                    : searchButton.hovered
                    ? "#0d2d3c"
                    : "#081923"

                    border.width:
                    searchButton.hovered
                    || root.searchOpen
                    ? 2
                    : 1

                    border.color:
                    root.searchOpen
                    ? "#35d9ff"
                    : searchButton.hovered
                    ? "#25d7ff"
                    : "#24536a"

                    Behavior on color {
                        ColorAnimation {
                            duration: 100
                        }
                    }

                    Behavior on border.color {
                        ColorAnimation {
                            duration: 100
                        }
                    }
                }

                QQC2.ToolTip.visible: hovered

                QQC2.ToolTip.text:
                root.searchOpen
                ? i18n("Close search")
                : i18n("Search games")
            }

            // ====================================================
            // REFRESH
            // ====================================================

            QQC2.ToolButton {
                id: refreshButton

                width: 40
                height: 40

                enabled: true

                display: QQC2.AbstractButton.IconOnly

                Kirigami.Icon {
                    id: refreshIcon

                    anchors.centerIn: parent

                    width: 30
                    height: 30

                    source: "view-refresh"

                    transformOrigin: Item.Center

                    RotationAnimation on rotation {
                        running: scanner.scanning
                        loops: Animation.Infinite
                        from: 0
                        to: 360
                        duration: 900
                    }

                    onRotationChanged: {
                        if (!scanner.scanning) {
                            rotation = 0
                        }
                    }
                }

                onClicked: {
                    if (!scanner.scanning) {
                        scanner.scan(true)
                    }
                }

                background: Rectangle {
                    radius: 8

                    color: refreshButton.down
                    ? "#12384a"
                    : refreshButton.hovered
                    ? "#0d2d3c"
                    : "#081923"

                    border.width:
                    refreshButton.hovered
                    || scanner.scanning
                    ? 2
                    : 1

                    border.color:
                    scanner.scanning
                    ? "#35d9ff"
                    : refreshButton.hovered
                    ? "#25d7ff"
                    : "#24536a"

                    Behavior on color {
                        ColorAnimation {
                            duration: 100
                        }
                    }

                    Behavior on border.color {
                        ColorAnimation {
                            duration: 100
                        }
                    }
                }

                QQC2.ToolTip.visible: hovered

                QQC2.ToolTip.text:
                scanner.scanning
                ? i18n("Refreshing...")
                : i18n("Refresh artwork")
            }

            // ====================================================
            // GENRE
            // Visual placeholder for the next feature
            // ====================================================

            QQC2.ToolButton {
                id: genreButton

                width: 40
                height: 40

                display: QQC2.AbstractButton.IconOnly

                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: 31
                    height: 31
                    source: "applications-games-symbolic"
                }

                opacity: 0.60

                onClicked: {
                    console.log(
                        "### GENRE FILTER COMING SOON ###"
                    )
                }

                background: Rectangle {
                    radius: 8

                    color: genreButton.down
                    ? "#12384a"
                    : genreButton.hovered
                    ? "#0d2d3c"
                    : "#081923"

                    border.width:
                    genreButton.hovered
                    ? 2
                    : 1

                    border.color:
                    genreButton.hovered
                    ? "#25d7ff"
                    : "#24536a"

                    Behavior on color {
                        ColorAnimation {
                            duration: 100
                        }
                    }

                    Behavior on border.color {
                        ColorAnimation {
                            duration: 100
                        }
                    }
                }

                QQC2.ToolTip.visible: hovered
                QQC2.ToolTip.text:
                i18n("Genre filter — coming soon")
            }

            // ====================================================
            // SETTINGS
            // ====================================================

            QQC2.ToolButton {
                id: settingsButton

                width: 40
                height: 40

                display: QQC2.AbstractButton.IconOnly

                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: 30
                    height: 30
                    source: "framework"
                }

                onClicked: {
                    plasmoid
                    .internalAction("configure")
                    .trigger()
                }

                background: Rectangle {
                    radius: 8

                    color: settingsButton.down
                    ? "#12384a"
                    : settingsButton.hovered
                    ? "#0d2d3c"
                    : "#081923"

                    border.width:
                    settingsButton.hovered
                    ? 2
                    : 1

                    border.color:
                    settingsButton.hovered
                    ? "#25d7ff"
                    : "#24536a"

                    Behavior on color {
                        ColorAnimation {
                            duration: 100
                        }
                    }

                    Behavior on border.color {
                        ColorAnimation {
                            duration: 100
                        }
                    }
                }

                QQC2.ToolTip.visible: hovered
                QQC2.ToolTip.text:
                i18n("Settings")
            }
        }

        // --------------------------------------------------------
        // CENTER: TITLE
        // --------------------------------------------------------

        Item {
            id: titleArea

            anchors.left: steamLogoArea.right
            anchors.right: headerButtons.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom

            anchors.leftMargin: 12
            anchors.rightMargin: 20

            // ====================================================
            // TITLE
            // ====================================================

            Row {
                id: titleRow

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 34

                spacing: 15

                Item {
                    id: steamTitleWrap

                    width: steamFront.implicitWidth
                    height: steamFront.implicitHeight + 4

                    Repeater {
                        model: 4

                        Text {
                            x: index + 1
                            y: index + 1

                            text: "STEAM"

                            color: index < 2
                            ? "#607684"
                            : "#263b48"

                            font.family: orbitronFont.name
                            font.bold: true
                            font.pixelSize: 50
                            font.letterSpacing: 10
                        }
                    }

                    Text {
                        id: steamFront

                        x: 0
                        y: 0

                        text: "STEAM"
                        color: "#e4edf2"

                        font.family: orbitronFont.name
                        font.bold: true
                        font.pixelSize: 50
                        font.letterSpacing: 10
                    }
                }

                Item {
                    id: bannersTitleWrap

                    width: bannersFront.implicitWidth
                    height: bannersFront.implicitHeight + 4

                    Text {
                        id: bannersShadowBack

                        x: 6
                        y: 6

                        text: "BANNERS"
                        color: "#06384a"
                        opacity: 0.65

                        font.family: "Orbitron"
                        font.bold: true
                        font.pixelSize: 50
                        font.letterSpacing: 10
                    }

                    Repeater {
                        model: 6

                        Text {
                            x: index + 1
                            y: index + 1

                            text: "BANNERS"

                            color: index < 3
                            ? "#0b6e8b"
                            : "#06384a"

                            font.family: orbitronFont.name
                            font.bold: true
                            font.pixelSize: 50
                            font.letterSpacing: 10
                        }
                    }

                    Text {
                        id: bannersFront

                        text: "BANNERS"
                        color: "#12c8f4"

                        font.family: "Orbitron"
                        font.bold: true
                        font.pixelSize: 50
                        font.letterSpacing: 10
                    }
                }
            }

            // ====================================================
            // SLOGAN + DECORATIVE LINES
            // ====================================================

            Item {
                id: sloganRow

                anchors.top: titleRow.bottom
                anchors.topMargin: 10

                anchors.horizontalCenter: titleRow.horizontalCenter
                anchors.horizontalCenterOffset: -10

                width: titleArea.width
                height: 24

                Text {
                    id: headerSubtitle

                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter

                    text: "YOUR GAMES - YOUR BANNERS"

                    color: "#e9f2f6"

                    font.bold: true
                    font.pixelSize: 16
                    font.letterSpacing: 1.6

                    verticalAlignment: Text.AlignVCenter
                }

                Item {
                    anchors.right: headerSubtitle.left
                    anchors.rightMargin: 12
                    anchors.verticalCenter: headerSubtitle.verticalCenter

                    width: 110
                    height: 5

                    Repeater {
                        model: 3

                        Rectangle {
                            x: index + 1
                            y: index + 1
                            width: 110
                            height: 2

                            color: index < 1
                            ? "#147b96"
                            : "#07506b"
                        }
                    }

                    Rectangle {
                        x: 0
                        y: 0
                        width: 110
                        height: 2
                        color: "#28d9ff"
                        opacity: 0.95
                    }
                }

                Item {
                    anchors.left: headerSubtitle.right
                    anchors.leftMargin: 12
                    anchors.verticalCenter: headerSubtitle.verticalCenter

                    width: 110
                    height: 5

                    Repeater {
                        model: 3

                        Rectangle {
                            x: index + 1
                            y: index + 1
                            width: 110
                            height: 2

                            color: index < 1
                            ? "#147b96"
                            : "#07506b"
                        }
                    }

                    Rectangle {
                        x: 0
                        y: 0
                        width: 110
                        height: 2
                        color: "#28d9ff"
                        opacity: 0.95
                    }
                }

            }
        }
    }

    // ============================================================
    // API KEY NOTICE
    // ============================================================

    Rectangle {
        id: apiNotice

        anchors.top: headerArea.bottom
        anchors.left: parent.left
        anchors.right: parent.right

        anchors.topMargin:
        root.apiKeyAvailable ? 0 : 8

        anchors.leftMargin: 10
        anchors.rightMargin: 10

        height: root.apiNoticeHeight

        visible: !root.apiKeyAvailable

        radius: 8

        color: "#132330"
        border.color: "#2f789e"
        border.width: 1

        Row {
            anchors.fill: parent

            anchors.leftMargin: 14
            anchors.rightMargin: 10

            spacing: 12

            QQC2.Label {
                anchors.verticalCenter:
                parent.verticalCenter

                width:
                parent.width
                - settingsNoticeButton.width
                - 30

                text: i18n(
                    "SteamGridDB API key not found. Add one in Settings to download game artwork."
                )

                wrapMode: Text.WordWrap
            }

            QQC2.Button {
                id: settingsNoticeButton

                anchors.verticalCenter:
                parent.verticalCenter

                text: i18n("Open Settings")

                onClicked: {
                    plasmoid
                    .internalAction("configure")
                    .trigger()
                }
            }
        }
    }

    // ============================================================
    // COLLAPSIBLE SEARCH PANEL
    // ============================================================

    Item {
        id: searchPanel

        anchors.top:
        root.apiKeyAvailable
        ? headerArea.bottom
        : apiNotice.bottom

        anchors.topMargin: 10
        anchors.left: parent.left
        anchors.right: parent.right

        height: root.searchOpen ? 52 : 0

        clip: true

        Behavior on height {
            NumberAnimation {
                duration: 140
                easing.type: Easing.OutQuad
            }
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top

            anchors.leftMargin: 10
            anchors.rightMargin: 10
            anchors.topMargin: 8

            height: 40

            radius: 8

            color:
            searchField.activeFocus
            ? "#0b202b"
            : "#081923"

            border.width:
            searchField.activeFocus
            ? 2
            : 1

            border.color:
            searchField.activeFocus
            ? "#35d9ff"
            : "#24536a"

            Behavior on color {
                ColorAnimation {
                    duration: 100
                }
            }

            Behavior on border.color {
                ColorAnimation {
                    duration: 100
                }
            }

            QQC2.TextField {
                id: searchField

                anchors.fill: parent

                anchors.leftMargin: 8
                anchors.rightMargin:
                clearSearchButton.visible
                ? 40
                : 8

                placeholderText:
                i18n("Search games...")

                background: Item {}

                selectByMouse: true

                onAccepted: {
                    focus = false
                }

                Keys.onEscapePressed: {
                    root.searchOpen = false
                    focus = false
                }
            }

            QQC2.ToolButton {
                id: clearSearchButton

                anchors.right: parent.right
                anchors.rightMargin: 4

                anchors.verticalCenter:
                parent.verticalCenter

                width: 36
                height: 36

                visible:
                searchField.text !== ""

                text: "×"
                font.pixelSize: 24
                font.bold: true

                onClicked: {
                    searchField.clear()
                    searchField.forceActiveFocus()
                }

                QQC2.ToolTip.visible:
                hovered

                QQC2.ToolTip.text:
                i18n("Clear search")
            }
        }
    }

    // ============================================================
    // CONTENT AREA
    // ============================================================

    Item {
        id: contentArea

        anchors.top: searchPanel.bottom

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        anchors.topMargin: 8
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        anchors.bottomMargin: 10

        // ========================================================
        // GAME GRID
        // ========================================================

        GameGrid {
            id: gameGrid

            anchors.fill: parent

            games: scanner.games

            searchText:
            searchField.text

            columns: Math.max(
                1,
                plasmoid.configuration.columns || 2
            )

            cardHeight: Math.max(
                80,
                plasmoid.configuration.cardHeight || 120
            )

            sortMode:
            plasmoid.configuration.sortMode || 0

            favoritesString:
            plasmoid.configuration.favorites || ""

            onFavoritesStringChanged: {
                if (
                    plasmoid.configuration.favorites
                    !== favoritesString
                ) {
                    plasmoid.configuration.favorites =
                    favoritesString
                }
            }
        }

        // ========================================================
        // EMPTY STATE
        // ========================================================

        Item {
            id: emptyState

            anchors.fill: parent

            visible:
            root.noGamesFound
            || root.noFavoritesFound
            || root.noSearchResults

            Column {
                anchors.centerIn: parent

                width: Math.min(
                    parent.width - 40,
                    420
                )

                spacing: 10

                Text {
                    anchors.horizontalCenter:
                    parent.horizontalCenter

                    text:
                    root.noSearchResults
                    ? "⌕"
                    : root.noFavoritesFound
                    ? "★"
                    : "?"

                    color:
                    root.noSearchResults
                    ? "#55bce8"
                    : root.noFavoritesFound
                    ? "#ffd34e"
                    : "#55bce8"

                    font.pixelSize: 34
                    font.bold: true
                }

                QQC2.Label {
                    width: parent.width

                    text:
                    root.noSearchResults
                    ? i18n(
                        "No games match your search."
                    )
                    : root.noFavoritesFound
                    ? i18n(
                        "No favorite games yet."
                    )
                    : i18n(
                        "No Steam games found."
                    )

                    color: "#eef6fb"

                    font.pixelSize: 18
                    font.bold: true

                    horizontalAlignment:
                    Text.AlignHCenter

                    wrapMode:
                    Text.WordWrap
                }

                QQC2.Label {
                    width: parent.width

                    text:
                    root.noSearchResults
                    ? i18n(
                        "Try a different game title or clear the search."
                    )
                    : root.noFavoritesFound
                    ? i18n(
                        "Right-click a game and add it to favorites, or change the View setting."
                    )
                    : i18n(
                        "Make sure Steam is installed and that at least one Steam library can be found."
                    )

                    color: "#93a9b8"

                    horizontalAlignment:
                    Text.AlignHCenter

                    wrapMode:
                    Text.WordWrap
                }

                QQC2.Button {
                    anchors.horizontalCenter:
                    parent.horizontalCenter

                    visible:
                    root.noFavoritesFound
                    && !root.noSearchResults

                    text:
                    i18n("Open Settings")

                    onClicked: {
                        plasmoid
                        .internalAction("configure")
                        .trigger()
                    }
                }

                QQC2.Button {
                    anchors.horizontalCenter:
                    parent.horizontalCenter

                    visible:
                    root.noGamesFound
                    && !root.noSearchResults

                    text:
                    i18n("Scan again")

                    onClicked: {
                        scanner.scan(false)
                    }
                }

                QQC2.Button {
                    anchors.horizontalCenter:
                    parent.horizontalCenter

                    visible:
                    root.noSearchResults

                    text:
                    i18n("Clear search")

                    onClicked: {
                        searchField.clear()

                        root.searchOpen = true

                        searchField.forceActiveFocus()
                    }
                }
            }
        }
    }

    // ============================================================
    // STARTUP
    // ============================================================

    Component.onCompleted: {
        console.log(
            "### MAIN QML LOADED ###"
        )

        apiKeyChecker.start(
            "python3",
            [
                "-c",

                "import pathlib; " +
                "p=pathlib.Path.home()/'.config'/'steambanners'/'steamgriddb.key'; " +
                "print('1' if p.exists() and p.read_text(encoding='utf-8').strip() else '0')"
            ]
        )

        scanner.scan(false)
    }
}
