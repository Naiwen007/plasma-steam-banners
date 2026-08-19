import QtQuick
import QtQuick.Controls as QQC2
import org.kde.plasma.plasmoid
import SteamBanners.Process

PlasmoidItem {
    id: root

    implicitWidth: 600
    implicitHeight: 500

    property bool apiKeyAvailable: true
    property int apiNoticeHeight: apiKeyAvailable ? 0 : 64

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

    Process {
        id: apiKeyChecker

        onOutputReady: function(output) {
            root.apiKeyAvailable = output.trim() === "1"
        }

        onErrorOccurred: function(error) {
            console.log("### API KEY CHECK ERROR:", error)
            root.apiKeyAvailable = false
        }
    }

    SteamScanner {
        id: scanner

        onScanFinished: {
            console.log("### SCAN FINISHED ###")
            console.log("Games:", scanner.games.length)
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
    // HEADER
    // ============================================================

    Item {
        id: headerArea

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right

        height: 200

        Image {
            id: headerImage

            anchors.fill: parent

            source: "../images/header.png"
            fillMode: Image.Stretch

            asynchronous: true
            cache: true
            smooth: true
        }

        MouseArea {
            id: refreshArea

            x: headerArea.width * 0.787
            y: headerArea.height * 0.18

            width: headerArea.width * 0.083
            height: headerArea.height * 0.64

            hoverEnabled: true

            cursorShape: scanner.scanning
            ? Qt.ArrowCursor
            : Qt.PointingHandCursor

            onClicked: {
                if (!scanner.scanning) {
                    scanner.scan(true)
                }
            }

            QQC2.ToolTip.visible: containsMouse

            QQC2.ToolTip.text: scanner.scanning
            ? i18n("Refreshing...")
            : i18n("Refresh games")
        }

        MouseArea {
            id: settingsArea

            x: headerArea.width * 0.885
            y: headerArea.height * 0.18

            width: headerArea.width * 0.083
            height: headerArea.height * 0.64

            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            onClicked: {
                plasmoid.internalAction("configure").trigger()
            }

            QQC2.ToolTip.visible: containsMouse
            QQC2.ToolTip.text: i18n("Settings")
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

        anchors.topMargin: root.apiKeyAvailable ? 0 : 8
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
                anchors.verticalCenter: parent.verticalCenter

                width: parent.width - settingsNoticeButton.width - 30

                text: i18n(
                    "SteamGridDB API key not found. Add one in Settings to download game artwork."
                )

                wrapMode: Text.WordWrap
            }

            QQC2.Button {
                id: settingsNoticeButton

                anchors.verticalCenter: parent.verticalCenter

                text: i18n("Open Settings")

                onClicked: {
                    plasmoid.internalAction("configure").trigger()
                }
            }
        }
    }

    // ============================================================
    // CONTENT AREA
    // ============================================================

    Item {
        id: contentArea

        anchors.top: root.apiKeyAvailable
        ? headerArea.bottom
        : apiNotice.bottom

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        anchors.topMargin: 8
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        anchors.bottomMargin: 10

        // ========================================================
        // SEARCH BAR
        // ========================================================

        Rectangle {
            id: searchBar

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right

            height: 40

            radius: 8

            color: "#0c151d"

            border.color: searchField.activeFocus
            ? "#45b9ee"
            : "#304859"

            border.width: 1

            Behavior on border.color {
                ColorAnimation {
                    duration: 120
                }
            }

            QQC2.TextField {
                id: searchField

                anchors.fill: parent

                anchors.leftMargin: 8
                anchors.rightMargin: clearSearchButton.visible ? 40 : 8

                placeholderText: i18n("Search games...")

                background: Item {}

                selectByMouse: true

                onAccepted: {
                    focus = false
                }
            }

            QQC2.ToolButton {
                id: clearSearchButton

                anchors.right: parent.right
                anchors.rightMargin: 4
                anchors.verticalCenter: parent.verticalCenter

                width: 32
                height: 32

                visible: searchField.text !== ""

                text: "×"

                onClicked: {
                    searchField.clear()
                    searchField.forceActiveFocus()
                }

                QQC2.ToolTip.visible: hovered
                QQC2.ToolTip.text: i18n("Clear search")
            }
        }

        // ========================================================
        // GAME GRID
        // ========================================================

        GameGrid {
            id: gameGrid

            anchors.top: searchBar.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom

            anchors.topMargin: 8

            games: scanner.games

            searchText: searchField.text

            columns: Math.max(
                1,
                plasmoid.configuration.columns || 2
            )

            cardHeight: Math.max(
                80,
                plasmoid.configuration.cardHeight || 120
            )

            sortMode: plasmoid.configuration.sortMode || 0

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

            anchors.top: searchBar.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom

            anchors.topMargin: 8

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
                    anchors.horizontalCenter: parent.horizontalCenter

                    text: root.noSearchResults
                    ? "⌕"
                    : root.noFavoritesFound
                    ? "★"
                    : "?"

                    color: root.noSearchResults
                    ? "#55bce8"
                    : root.noFavoritesFound
                    ? "#ffd34e"
                    : "#55bce8"

                    font.pixelSize: 34
                    font.bold: true
                }

                QQC2.Label {
                    width: parent.width

                    text: root.noSearchResults
                    ? i18n("No games match your search.")
                    : root.noFavoritesFound
                    ? i18n("No favorite games yet.")
                    : i18n("No Steam games found.")

                    color: "#eef6fb"

                    font.pixelSize: 18
                    font.bold: true

                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                }

                QQC2.Label {
                    width: parent.width

                    text: root.noSearchResults
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

                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                }

                QQC2.Button {
                    anchors.horizontalCenter: parent.horizontalCenter

                    visible:
                    root.noFavoritesFound
                    && !root.noSearchResults

                    text: i18n("Open Settings")

                    onClicked: {
                        plasmoid.internalAction("configure").trigger()
                    }
                }

                QQC2.Button {
                    anchors.horizontalCenter: parent.horizontalCenter

                    visible:
                    root.noGamesFound
                    && !root.noSearchResults

                    text: i18n("Scan again")

                    onClicked: {
                        scanner.scan()
                    }
                }

                QQC2.Button {
                    anchors.horizontalCenter: parent.horizontalCenter

                    visible: root.noSearchResults

                    text: i18n("Clear search")

                    onClicked: {
                        searchField.clear()
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
        console.log("### MAIN QML LOADED ###")

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
