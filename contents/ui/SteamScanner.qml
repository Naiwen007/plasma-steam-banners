import QtQuick
import SteamBanners.Process

QtObject {
    id: scanner

    property var games: []
    property var steamGames: []
    property var heroicGames: []
    property string heroicProcessOutput: ""
    property bool heroicScanning: false
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
    property string artworkOptionsGameId: ""
    property string artworkOptionsTitle: ""
    property string artworkOptionsOutput: ""
    property bool artworkSelectionSaving: false
    property string artworkSelectionOutput: ""
    property int artworkSelectionAppid: 0
    property var artworkSelectionGame: null
    property string artworkSelectionType: ""
    property bool artworkClearRunning: false
    property string artworkClearOutput: ""
    property int artworkClearAppid: 0
    property string artworkClearType: ""

    property string scriptPath: {
        var url = Qt.resolvedUrl(
            "../scripts/steam_scan.py"
        ).toString()

        if (url.startsWith("file://")) {
            url = url.substring(7)
        }

        return decodeURIComponent(url)
    }

    property string heroicScriptPath: {
        var url = Qt.resolvedUrl(
            "../scripts/heroic_scan.py"
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

            scanner.processOutput = ""
            scanner.scanning = false
            scanner.refreshingArtwork = false
            scanner.refreshingAppid = 0

            scanner.loadLibraryStatus()
        }

        onFinished: function(exitCode) {
            console.log(
                "### PROCESS FINISHED:",
                exitCode
            )

            var refreshedAppid =
            scanner.refreshingAppid

            var waitingForHeroic = false

            if (exitCode === 0) {
                try {
                    var result = JSON.parse(
                        scanner.processOutput
                    )

                    console.log(
                        "### STEAM GAMES PARSED:",
                        result.length
                    )

                    if (refreshedAppid > 0) {
                        var refreshedGame = null

                        for (
                            var resultIndex = 0;
                        resultIndex < result.length;
                        resultIndex++
                        ) {
                            if (
                                Number(
                                    result[resultIndex].appid
                                )
                                === refreshedAppid
                            ) {
                                refreshedGame =
                                result[resultIndex]

                                break
                            }
                        }

                        scanner.singleGameRefreshFinished(
                            refreshedAppid,
                            refreshedGame
                            && refreshedGame.hero
                            ? refreshedGame.hero
                            : "",
                            refreshedGame
                            && refreshedGame.logo
                            ? refreshedGame.logo
                            : ""
                        )

                    } else {
                        scanner.steamGames = result
                        waitingForHeroic = true

                        scanner.startHeroicScan()
                    }

                } catch (error) {
                    console.log(
                        "### JSON ERROR:",
                        error
                    )
                }
            }

            scanner.processOutput = ""

            if (!waitingForHeroic) {
                scanner.scanning = false
                scanner.refreshingArtwork = false
                scanner.refreshingAppid = 0

                scanner.loadLibraryStatus()
            }
        }
    }

    property Process heroicProcess: Process {
        onOutputReady: function(output) {
            scanner.heroicProcessOutput += output
        }

        onErrorOccurred: function(error) {
            console.log(
                "### HEROIC PROCESS ERROR:",
                error
            )

            scanner.heroicGames = []
            scanner.finishCombinedScan()
        }

        onFinished: function(exitCode) {
            if (!scanner.heroicScanning) {
                return
            }

            console.log(
                "### HEROIC PROCESS FINISHED:",
                exitCode
            )

            if (exitCode === 0) {
                try {
                    var result = JSON.parse(
                        scanner.heroicProcessOutput
                    )

                    scanner.heroicGames = result

                    console.log(
                        "### HEROIC GAMES PARSED:",
                        result.length
                    )

                } catch (error) {
                    console.log(
                        "### HEROIC JSON ERROR:",
                        error
                    )

                    scanner.heroicGames = []
                }

            } else {
                scanner.heroicGames = []
            }

            scanner.finishCombinedScan()
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
            scanner.artworkOptionsGameId = ""
            scanner.artworkOptionsTitle = ""
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
            scanner.artworkOptionsGameId = ""
            scanner.artworkOptionsTitle = ""
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
            scanner.artworkSelectionGame = null
        }

        onFinished: function(exitCode) {
            var game =
            scanner.artworkSelectionGame

            var artworkType =
            scanner.artworkSelectionType

            if (exitCode === 0) {
                try {
                    var result = JSON.parse(
                        scanner.artworkSelectionOutput
                    )

                    if (result.success === true) {
                        scanner.artworkSelectionFinished(
                            game,
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
            scanner.artworkSelectionGame = null
        }
    }

    property Process artworkClearProcess: Process {
        onOutputReady: function(output) {
            scanner.artworkClearOutput += output
        }

        onErrorOccurred: function(error) {
            scanner.artworkClearRunning = false
            scanner.artworkClearOutput = ""
            scanner.artworkClearAppid = 0
            scanner.artworkClearType = ""
        }

        onFinished: function(exitCode) {
            var appid =
            scanner.artworkClearAppid

            var artworkType =
            scanner.artworkClearType

            if (exitCode === 0) {
                try {
                    var result = JSON.parse(
                        scanner.artworkClearOutput
                    )

                    if (result.success === true) {
                        scanner.artworkClearFinished(
                            appid,
                            artworkType
                        )
                    } else {
                        scanner.artworkClearFailed(
                            result.error || "Unknown error"
                        )
                    }

                } catch (error) {
                    scanner.artworkClearFailed(
                        String(error)
                    )
                }
            } else {
                scanner.artworkClearFailed(
                    "Could not clear artwork selection."
                )
            }

            scanner.artworkClearOutput = ""
            scanner.artworkClearRunning = false
            scanner.artworkClearAppid = 0
            scanner.artworkClearType = ""
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
    signal singleGameRefreshFinished(
        int appid,
        string heroPath,
        string logoPath
    )
    signal artworkOptionsFinished(int appid)
    signal artworkOptionsFailed(string error)
    signal artworkSelectionFinished(
        var game,
        string artworkType,
        string path
    )

    signal artworkSelectionFailed(string error)

    signal artworkClearFinished(
        int appid,
        string artworkType
    )

    signal artworkClearFailed(string error)

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

    function loadArtworkOptions(game) {
        if (artworkOptionsLoading) {
            return
        }

        if (!game) {
            return
        }

        artworkOptionsOutput = ""
        artworkLogos = []
        artworkHeroes = []

        artworkOptionsLoading = true

        if (game.provider === "heroic") {
            artworkOptionsAppid = 0
            artworkOptionsGameId =
            game.gameId || ""
            artworkOptionsTitle =
            game.name || ""

            artworkOptionsProcess.start(
                "python3",
                [
                    heroicScriptPath,
                    "--list-artwork",
                    artworkOptionsGameId,
                    artworkOptionsTitle
                ]
            )

            return
        }

        var id = Number(game.appid)

        if (!isFinite(id) || id <= 0) {
            artworkOptionsLoading = false
            return
        }

        artworkOptionsAppid = id
        artworkOptionsGameId =
        game.gameId || ""
        artworkOptionsTitle =
        game.name || ""

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
        game,
        artworkType,
        url
    ) {
        if (artworkSelectionSaving) {
            return
        }

        if (
            !game
            || !url
            || (
                artworkType !== "logo"
                && artworkType !== "hero"
            )
        ) {
            return
        }

        artworkSelectionOutput = ""
        artworkSelectionGame = game
        artworkSelectionType = artworkType
        artworkSelectionSaving = true

        var provider = game.provider || ""

        if (
            provider === ""
            && game.appid !== undefined
        ) {
            provider = "steam"
        }

        if (provider === "heroic") {
            var gameId = game.gameId || ""
            var store = game.store || ""
            var providerId = game.providerId || ""

            if (
                gameId === ""
                || store === ""
                || providerId === ""
            ) {
                artworkSelectionSaving = false
                artworkSelectionGame = null
                artworkSelectionType = ""
                return
            }

            artworkSelectionProcess.start(
                "python3",
                [
                    heroicScriptPath,
                    "--select-artwork",
                    gameId,
                    store,
                    providerId,
                    artworkType,
                    url
                ]
            )

            return
        }

        var id = Number(game.appid)

        if (!isFinite(id) || id <= 0) {
            artworkSelectionSaving = false
            artworkSelectionGame = null
            artworkSelectionType = ""
            return
        }

        artworkSelectionAppid = id

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

    function clearArtworkSelection(
        appid,
        artworkType
    ) {
        if (
            artworkClearRunning
            || artworkSelectionSaving
        ) {
            return
        }

        var id = Number(appid)

        if (
            !isFinite(id)
            || id <= 0
            || (
                artworkType !== "logo"
                && artworkType !== "hero"
            )
        ) {
            return
        }

        artworkClearOutput = ""
        artworkClearAppid = id
        artworkClearType = artworkType
        artworkClearRunning = true

        artworkClearProcess.start(
            "python3",
            [
                scriptPath,
                "--clear-artwork-selection",
                String(id),
                                  artworkType
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

    function startHeroicScan() {
        heroicProcessOutput = ""
        heroicGames = []
        heroicScanning = true

        console.log(
            "### STARTING HEROIC SCAN ###"
        )

        console.log(
            "### HEROIC SCRIPT:",
            heroicScriptPath
        )

        heroicProcess.start(
            "python3",
            [
                heroicScriptPath
            ]
        )
    }

    function finishCombinedScan() {
        if (!heroicScanning) {
            return
        }

        heroicScanning = false

        games = steamGames.concat(
            heroicGames
        )

        console.log(
            "### COMBINED GAMES:",
            games.length
        )

        heroicProcessOutput = ""
        scanning = false
        refreshingArtwork = false
        refreshingAppid = 0

        scanFinished()
        loadLibraryStatus()
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
