import QtQuick
import SteamBanners.Process

QtObject {
    id: scanner

    property var games: []
    property bool scanning: false

    property Process process: Process {
        onOutputReady: function(output) {
            console.log("### PROCESS OUTPUT ###")

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
            scanner.scanning = false
        }

        onFinished: function(exitCode) {
            console.log("### PROCESS FINISHED:", exitCode)
            scanner.scanning = false
        }
    }

    signal scanFinished()

    function scan() {
        if (scanning) {
            console.log("### SCAN ALREADY RUNNING ###")
            return
        }

        console.log("### STARTING STEAM SCAN ###")
        scanning = true

        process.start(
            "python3",
            [
                "/var/home/Naiwen/.local/share/plasma/plasmoids/com.new.steambanners/contents/scripts/steam_scan.py"
            ]
        )
    }
}
