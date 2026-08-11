import QtQuick
import SteamBanners.Process

QtObject {
    id: scanner

    property var games: []

    property Process process: Process {
        onOutputReady: function(output) {
            console.log("### PROCESS OUTPUT ###")
            console.log(output)

            try {
                scanner.games = JSON.parse(output)
                console.log("### GAMES PARSED:", scanner.games.length)
                scanner.scanFinished()
            } catch (e) {
                console.log("### JSON ERROR:", e)
            }
        }

        onErrorOccurred: function(error) {
            console.log("### PROCESS ERROR:", error)
        }

        onFinished: function(exitCode) {
            console.log("### PROCESS FINISHED:", exitCode)
        }
    }

    signal scanFinished()

    function scan() {
        console.log("### STARTING STEAM SCAN ###")

        process.start(
            "python3",
            [
                "/var/home/Naiwen/.local/share/plasma/plasmoids/com.new.steambanners/contents/scripts/steam_scan.py"
            ]
        )
    }
}
