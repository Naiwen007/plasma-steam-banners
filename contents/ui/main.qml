import QtQuick
import org.kde.plasma.plasmoid

PlasmoidItem {
    implicitWidth: 600
    implicitHeight: 500

    SteamScanner {
        id: scanner

        onScanFinished: {
            console.log("### SCAN FINISHED ###")
            console.log("Games:", scanner.games.length)
        }
    }

    GameGrid {
        id: gameGrid

        anchors.fill: parent
        anchors.margins: 10

        model: scanner.games
        columns: Math.max(1, plasmoid.configuration.columns || 2)
        cardHeight: Math.max(80, plasmoid.configuration.cardHeight || 120)

        favoritesString: plasmoid.configuration.favorites || ""

        onFavoritesStringChanged: {
            if (plasmoid.configuration.favorites !== favoritesString) {
                plasmoid.configuration.favorites = favoritesString
            }
        }
    }

    Component.onCompleted: {
        console.log("### MAIN QML LOADED ###")
        scanner.scan()
    }
}
