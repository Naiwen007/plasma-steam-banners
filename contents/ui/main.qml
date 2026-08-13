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
                    scanner.scan()
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
    // GAME GRID
    // ============================================================

    GameGrid {
        id: gameGrid

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

        games: scanner.games

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

        scanner.scan()
    }
}
