import QtQuick
import SteamBanners.Process

QtObject {
    id: scanner

    property var games: []
    property bool scanning: false
    property bool refreshingArtwork: false

    property string scriptPath: {
        var url = Qt.resolvedUrl(
            "../scripts/steam_scan.py"
        ).toString()

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

                console.log(
                    "### GAMES PARSED:",
                    scanner.games.length
                )

                scanner.scanFinished()

            } catch (e) {
                console.log(
                    "### JSON ERROR:",
                    e
                )
            }
        }

        onErrorOccurred: function(error) {
            console.log(
                "### PROCESS ERROR:",
                error
            )

            scanner.scanning = false
            scanner.refreshingArtwork = false
        }

        onFinished: function(exitCode) {
            console.log(
                "### PROCESS FINISHED:",
                exitCode
            )

            scanner.scanning = false
            scanner.refreshingArtwork = false
        }
    }

    signal scanFinished()

    function scan(refreshArtwork) {
        if (scanning) {
            console.log(
                "### SCAN ALREADY RUNNING ###"
            )
            return
        }

        var doRefresh =
        refreshArtwork === true

        console.log(
            doRefresh
            ? "### STARTING FULL ARTWORK REFRESH ###"
            : "### STARTING FAST LOCAL SCAN ###"
        )

        console.log(
            "### SCRIPT:",
            scriptPath
        )

        scanning = true
        refreshingArtwork = doRefresh

        var arguments = [
            scriptPath
        ]

        if (doRefresh) {
            arguments.push(
                "--refresh-artwork"
            )
        }

        process.start(
            "python3",
            arguments
        )
    }
}
