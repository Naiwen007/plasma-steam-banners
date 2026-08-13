import QtQuick
import SteamBanners.Process

QtObject {
    id: scanner

    property var games: []
    property bool scanning: false

    property string scriptPath: {
        var url = Qt.resolvedUrl("../scripts/steam_scan.py").toString()

        if (url.startsWith("file://")) {
            url = url.substring(7)
        }

        return decodeURIComponent(url)
    }

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
        console.log("### SCRIPT:", scriptPath)

        scanning = true

        process.start(
            "python3",
            [
                scriptPath
            ]
        )
    }
}
