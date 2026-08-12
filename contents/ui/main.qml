import QtQuick
import QtQuick.Controls as QQC2
import org.kde.plasma.plasmoid

PlasmoidItem {
    id: root

    implicitWidth: 600
    implicitHeight: 500

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
    // Fixed height: 200 px
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

            // Fill the 200 px header without stretching the image.
            // Excess image area is cropped instead.
            fillMode: Image.Stretch

            asynchronous: true
            cache: true
            smooth: true
        }

        // ========================================================
        // REFRESH
        // Invisible click area over the refresh button in header.png
        // ========================================================

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

        // ========================================================
        // SETTINGS
        // Invisible click area over the settings button in header.png
        // ========================================================

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
    // GAME GRID
    // ============================================================

    GameGrid {
        id: gameGrid

        anchors.top: headerArea.bottom
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
        scanner.scan()
    }
}
