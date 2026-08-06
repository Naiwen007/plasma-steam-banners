import QtQuick

QtObject {

    id: scanner

    property var games: []

    signal scanFinished()

    function scan() {
        console.log("SteamScanner ready")

        // Tillfälligt test:
        // Backend kopplas in här senare.
        games = []

        scanFinished()
    }
}
