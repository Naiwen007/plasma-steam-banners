import QtQuick
import SteamBanners.Process

QtObject {
    id: scanner

    property var games: []
    property bool scanning: false
    property bool refreshingArtwork: false
    property int refreshingAppid: 0
    property bool steamFound: true
    property var availableLibraries: []
    property var unavailableLibraries: []
    property string libraryStatusOutput: ""
    property string processOutput: ""
    property bool artworkOptionsLoading: false
    property int artworkOptionsAppid: 0
    property var artworkLogos: []
    property var artworkHeroes: []
    property string artworkOptionsOutput: ""
    property bool artworkSelectionSaving: false
    property string artworkSelectionOutput: ""
    property int artworkSelectionAppid: 0
    property string artworkSelectionType: ""

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
            scanner.processOutput += output
        }

        onErrorOccurred: function(error) {
            console.log(
                "### PROCESS ERROR:",
                error
            )

            scanner.scanning = false
            scanner.refreshingArtwork = false
            scanner.refreshingAppid = 0
        }

        onFinished: function(exitCode) {
            console.log(
                "### PROCESS FINISHED:",
                exitCode
            )

            var refreshedAppid =
            scanner.refreshingAppid

            if (exitCode === 0) {
                try {
                    var result = JSON.parse(
                        scanner.processOutput
                    )

                    console.log(
                        "### GAMES PARSED:",
                        result.length
                    )

                    if (refreshedAppid > 0) {
                        scanner.singleGameRefreshFinished(
                            refreshedAppid
                        )
                    } else {
                        scanner.games = result
                        scanner.scanFinished()
                    }

                } catch (error) {
                    console.log(
                        "### JSON ERROR:",
                        error
                    )
                }
            }

            scanner.processOutput = ""
            scanner.scanning = false
            scanner.refreshingArtwork = false
            scanner.refreshingAppid = 0

            scanner.loadLibraryStatus()
        }
    }

    property Process artworkOptionsProcess: Process {
        onOutputReady: function(output) {
            scanner.artworkOptionsOutput += output
        }

        onErrorOccurred: function(error) {
            scanner.artworkOptionsLoading = false
            scanner.artworkOptionsAppid = 0
            scanner.artworkOptionsOutput = ""
        }

        onFinished: function(exitCode) {
            var appid = scanner.artworkOptionsAppid

            if (exitCode === 0) {
                try {
                    var result = JSON.parse(
                        scanner.artworkOptionsOutput
                    )

                    if (result.success === true) {
                        scanner.artworkLogos =
                        result.logos || []

                        scanner.artworkHeroes =
                        result.heroes || []

                        scanner.artworkOptionsFinished(
                            appid
                        )
                    } else {
                        scanner.artworkOptionsFailed(
                            result.error || "Unknown error"
                        )
                    }

                } catch (error) {
                    scanner.artworkOptionsFailed(
                        String(error)
                    )
                }
            } else {
                scanner.artworkOptionsFailed(
                    "Artwork lookup failed."
                )
            }

            scanner.artworkOptionsOutput = ""
            scanner.artworkOptionsLoading = false
            scanner.artworkOptionsAppid = 0
        }
    }

    property Process artworkSelectionProcess: Process {
        onOutputReady: function(output) {
            scanner.artworkSelectionOutput += output
        }

        onErrorOccurred: function(error) {
            scanner.artworkSelectionSaving = false
            scanner.artworkSelectionOutput = ""
            scanner.artworkSelectionAppid = 0
            scanner.artworkSelectionType = ""
        }

        onFinished: function(exitCode) {
            var appid =
            scanner.artworkSelectionAppid

            var artworkType =
            scanner.artworkSelectionType

            if (exitCode === 0) {
                try {
                    var result = JSON.parse(
                        scanner.artworkSelectionOutput
                    )

                    if (result.success === true) {
                        scanner.artworkSelectionFinished(
                            appid,
                            artworkType,
                            result.path
                        )
                    } else {
                        scanner.artworkSelectionFailed(
                            result.error || "Unknown error"
                        )
                    }

                } catch (error) {
                    scanner.artworkSelectionFailed(
                        String(error)
                    )
                }
            } else {
                scanner.artworkSelectionFailed(
                    "Could not save artwork."
                )
            }

            scanner.artworkSelectionOutput = ""
            scanner.artworkSelectionSaving = false
            scanner.artworkSelectionAppid = 0
            scanner.artworkSelectionType = ""
        }
    }

    property Process libraryStatusProcess: Process {
        onOutputReady: function(output) {
            scanner.libraryStatusOutput += output
        }

        onErrorOccurred: function(error) {
            console.log(
                "### LIBRARY STATUS ERROR:",
                error
            )
        }

        onFinished: function(exitCode) {
            console.log(
                "### LIBRARY STATUS FINISHED:",
                exitCode
            )

            try {
                var status = JSON.parse(
                    scanner.libraryStatusOutput
                )

                scanner.steamFound =
                status.steam_found === true

                scanner.availableLibraries =
                status.available_libraries || []

                scanner.unavailableLibraries =
                status.unavailable_libraries || []

                console.log(
                    "### AVAILABLE LIBRARIES:",
                    scanner.availableLibraries.length
                )

                console.log(
                    "### UNAVAILABLE LIBRARIES:",
                    scanner.unavailableLibraries.length
                )

            } catch (error) {
                console.log(
                    "### LIBRARY STATUS JSON ERROR:",
                    error
                )
            }
        }
    }

    signal scanFinished()
    signal singleGameRefreshFinished(int appid)
    signal artworkOptionsFinished(int appid)
    signal artworkOptionsFailed(string error)
    signal artworkSelectionFinished(
        int appid,
        string artworkType,
        string path
    )

    signal artworkSelectionFailed(string error)

    function loadLibraryStatus() {
        libraryStatusOutput = ""

        libraryStatusProcess.start(
            "python3",
            [
                "-c",
                "import json,pathlib; " +
                "p=pathlib.Path.home()/'.cache'/'steambanners'/'library_status.json'; " +
                "print(p.read_text(encoding='utf-8') if p.exists() else '{}',end='')"
            ]
        )
    }

    function loadArtworkOptions(appid) {
        if (artworkOptionsLoading) {
            return
        }

        var id = Number(appid)

        if (!isFinite(id) || id <= 0) {
            return
        }

        artworkOptionsOutput = ""
        artworkLogos = []
        artworkHeroes = []
        artworkOptionsAppid = id
        artworkOptionsLoading = true

        artworkOptionsProcess.start(
            "python3",
            [
                scriptPath,
                "--list-artwork-appid",
                String(id)
            ]
        )
    }

    function selectArtwork(
        appid,
        artworkType,
        url
    ) {
        if (artworkSelectionSaving) {
            return
        }

        var id = Number(appid)

        if (
            !isFinite(id)
            || id <= 0
            || !url
        ) {
            return
        }

        artworkSelectionOutput = ""
        artworkSelectionAppid = id
        artworkSelectionType = artworkType
        artworkSelectionSaving = true

        artworkSelectionProcess.start(
            "python3",
            [
                scriptPath,
                "--select-artwork",
                String(id),
                                      artworkType,
                                      url
            ]
        )
    }

    function scanGame(appid) {
        if (scanning) {
            console.log(
                "### SCAN ALREADY RUNNING ###"
            )
            return
        }

        var id = Number(appid)

        if (!isFinite(id) || id <= 0) {
            console.log(
                "### INVALID APPID:",
                appid
            )
            return
        }

        console.log(
            "### REFRESHING SINGLE GAME:",
            id
        )

        processOutput = ""
        scanning = true
        refreshingArtwork = true
        refreshingAppid = id

        process.start(
            "python3",
            [
                scriptPath,
                "--refresh-appid",
                String(id)
            ]
        )
    }

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

        processOutput = ""
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
