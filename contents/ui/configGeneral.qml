import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import SteamBanners.Process

Kirigami.FormLayout {
    id: root

    property alias cfg_columns: columnsSpinBox.value
    property alias cfg_cardHeight: cardHeightSpinBox.value
    property alias cfg_sortMode: sortCombo.currentIndex

    property bool apiKeyVisible: false
    property bool apiKeyLoaded: false
    property bool updateChecking: false
    property string updateOutput: ""
    property string installedVersion: ""
    property string latestVersion: ""
    property bool updateAvailable: false
    property string updateReleaseUrl: ""
    property string updateAssetUrl: ""
    property bool updateInstalling: false
    property string installOutput: ""
    property bool updateInstalled: false
    property bool cacheLoading: false
    property string cacheOutput: ""
    property int cacheArtworkSize: 0
    property int cacheArtworkFiles: 0
    property int cacheLogoFiles: 0
    property int cacheHeroFiles: 0
    property int cacheMetadataSize: 0
    property int cacheTotalSize: 0
    property bool cacheActionRunning: false
    property string cacheActionOutput: ""
    property string cacheAction: ""

    property bool confirmClearArtwork: false
    property bool confirmClearMetadata: false

    property string cacheScriptPath: {
        var url = Qt.resolvedUrl(
            "../scripts/cache_manage.py"
        ).toString()

        if (url.startsWith("file://")) {
            url = url.substring(7)
        }

        return decodeURIComponent(url)
    }

    property string updateScriptPath: {
        var url = Qt.resolvedUrl(
            "../scripts/update_check.py"
        ).toString()

        if (url.startsWith("file://")) {
            url = url.substring(7)
        }

        return decodeURIComponent(url)
    }

    property string updateInstallScriptPath: {
        var url = Qt.resolvedUrl(
            "../scripts/update_install.py"
        ).toString()

        if (url.startsWith("file://")) {
            url = url.substring(7)
        }

        return decodeURIComponent(url)
    }

    Process {
        id: keyLoader

        onOutputReady: function(output) {
            apiKeyField.text = output.trim()
            root.apiKeyLoaded = true
        }

        onErrorOccurred: function(error) {
            console.log("### API KEY LOAD ERROR:", error)
            root.apiKeyLoaded = true
        }

        onFinished: function(exitCode) {
            console.log("### API KEY LOAD FINISHED:", exitCode)

            if (!root.apiKeyLoaded) {
                root.apiKeyLoaded = true
            }
        }
    }

    Process {
        id: keySaver

        onErrorOccurred: function(error) {
            console.log("### API KEY SAVE ERROR:", error)
            saveStatus.text = i18n("Could not save API key.")
        }

        onFinished: function(exitCode) {
            console.log("### API KEY SAVE FINISHED:", exitCode)

            if (exitCode === 0) {
                saveStatus.text = i18n("API key saved.")
            } else {
                saveStatus.text = i18n("Could not save API key.")
            }
        }
    }

    Process {
        id: updateChecker

        onOutputReady: function(output) {
            root.updateOutput += output
        }

        onErrorOccurred: function(error) {
            console.log(
                "### UPDATE CHECK ERROR:",
                error
            )

            root.updateChecking = false
            updateStatus.text =
            i18n("Could not check for updates.")
        }

        onFinished: function(exitCode) {
            console.log(
                "### UPDATE CHECK FINISHED:",
                exitCode
            )

            root.updateChecking = false

            try {
                var result = JSON.parse(
                    root.updateOutput
                )

                if (!result.success) {
                    updateStatus.text =
                    i18n("Could not check for updates.")
                    return
                }

                root.installedVersion =
                result.installed || ""

                root.latestVersion =
                result.latest || ""

                root.updateAvailable =
                result.update_available === true

                root.updateReleaseUrl =
                result.release_url || ""

                root.updateAssetUrl =
                result.asset_url || ""

                if (root.updateAvailable) {
                    updateStatus.text =
                    i18n(
                        "Version %1 is available.",
                         root.latestVersion
                    )
                } else {
                    updateStatus.text =
                    i18n(
                        "Steam Banners is up to date."
                    )
                }

            } catch (error) {
                console.log(
                    "### UPDATE JSON ERROR:",
                    error
                )

                updateStatus.text =
                i18n("Could not check for updates.")
            }
        }
    }

    Process {
        id: updateInstaller

        onOutputReady: function(output) {
            root.installOutput += output
        }

        onErrorOccurred: function(error) {
            console.log(
                "### UPDATE INSTALL ERROR:",
                error
            )

            root.updateInstalling = false

            updateStatus.text =
            i18n("Update failed.")
        }

        onFinished: function(exitCode) {
            console.log(
                "### UPDATE INSTALL FINISHED:",
                exitCode
            )

            root.updateInstalling = false

            try {
                var result = JSON.parse(
                    root.installOutput
                )

                if (!result.success) {
                    updateStatus.text =
                    result.error
                    || i18n("Update failed.")

                    return
                }

                root.updateInstalled = true
                root.updateAvailable = false
                root.installedVersion =
                result.installed_version || ""

                updateStatus.text =
                i18n(
                    "Updated to version %1. Restart Plasma to finish.",
                     root.installedVersion
                )

            } catch (error) {
                console.log(
                    "### UPDATE INSTALL JSON ERROR:",
                    error
                )

                updateStatus.text =
                i18n("Update failed.")
            }
        }
    }

    Process {
        id: plasmaRestarter

        onErrorOccurred: function(error) {
            console.log(
                "### PLASMA RESTART ERROR:",
                error
            )

            updateStatus.text =
            i18n("Could not restart Plasma.")
        }
    }

    Process {
        id: cacheStatusProcess

        onOutputReady: function(output) {
            root.cacheOutput += output
        }

        onErrorOccurred: function(error) {
            console.log(
                "### CACHE STATUS ERROR:",
                error
            )

            root.cacheLoading = false
            cacheStatus.text =
            i18n("Could not read cache information.")
        }

        onFinished: function(exitCode) {
            root.cacheLoading = false

            try {
                var result = JSON.parse(
                    root.cacheOutput
                )

                if (!result.success) {
                    cacheStatus.text =
                    result.error
                    || i18n(
                        "Could not read cache information."
                    )
                    return
                }

                root.cacheArtworkSize =
                result.artwork.size || 0

                root.cacheArtworkFiles =
                result.artwork.files || 0

                root.cacheLogoFiles =
                result.artwork.logos.files || 0

                root.cacheHeroFiles =
                result.artwork.heroes.files || 0

                root.cacheMetadataSize =
                result.metadata.size || 0

                root.cacheTotalSize =
                result.total_size || 0

                cacheStatus.text = ""
            } catch (error) {
                console.log(
                    "### CACHE STATUS JSON ERROR:",
                    error
                )

                cacheStatus.text =
                i18n("Could not read cache information.")
            }
        }
    }

    Process {
        id: cacheActionProcess

        onOutputReady: function(output) {
            root.cacheActionOutput += output
        }

        onErrorOccurred: function(error) {
            console.log(
                "### CACHE ACTION ERROR:",
                error
            )

            root.cacheActionRunning = false
            root.confirmClearArtwork = false
            root.confirmClearMetadata = false

            cacheStatus.text =
            i18n("Could not clear cache.")
        }

        onFinished: function(exitCode) {
            root.cacheActionRunning = false
            root.confirmClearArtwork = false
            root.confirmClearMetadata = false

            try {
                var result = JSON.parse(
                    root.cacheActionOutput
                )

                if (!result.success) {
                    cacheStatus.text =
                    result.error
                    || i18n("Could not clear cache.")
                    return
                }

                if (result.cleared === "artwork") {
                    cacheStatus.text =
                    i18n(
                        "Artwork cache cleared."
                    )
                } else if (
                    result.cleared === "metadata"
                ) {
                    cacheStatus.text =
                    i18n(
                        "Metadata cache cleared."
                    )
                }

                root.loadCacheStatus()

                plasmoid.configuration.cacheRevision =
                    plasmoid.configuration.cacheRevision + 1

            } catch (error) {
                console.log(
                    "### CACHE ACTION JSON ERROR:",
                    error
                )

                cacheStatus.text =
                i18n("Could not clear cache.")
            }
        }
    }

    Timer {
        id: cacheConfirmTimer

        interval: 5000
        repeat: false

        onTriggered: {
            root.confirmClearArtwork = false
            root.confirmClearMetadata = false
        }
    }

    QQC2.SpinBox {
        id: columnsSpinBox

        Kirigami.FormData.label: i18n("Columns:")

        from: 1
        to: 5
    }

    QQC2.SpinBox {
        id: cardHeightSpinBox

        Kirigami.FormData.label: i18n("Card height:")

        from: 80
        to: 300
        stepSize: 10

        textFromValue: function(value) {
            return value + " px"
        }

        valueFromText: function(text) {
            return parseInt(text)
        }
    }

    QQC2.ComboBox {
        id: sortCombo

        Kirigami.FormData.label: i18n("View:")

        model: [
            i18n("Alphabetical (A–Z)"),
            i18n("Favorites first"),
            i18n("Favorites only")
        ]
    }

    Kirigami.Separator {
        Kirigami.FormData.isSection: true
        Kirigami.FormData.label: i18n("SteamGridDB")
    }

    Column {
        Kirigami.FormData.isSection: true

        spacing: 2

        QQC2.Label {
            width: 420

            text: i18n(
                "Steam Banners uses SteamGridDB to download game artwork."
            )

            wrapMode: Text.WordWrap
        }

        QQC2.Label {
            width: 420

            text: i18n(
                "Sign in to SteamGridDB, open your API settings and generate an API key."
            )

            wrapMode: Text.WordWrap
            opacity: 0.75
        }

        QQC2.Label {
            text: '<a href="https://www.steamgriddb.com/profile/preferences/api">' +
            i18n("Get a SteamGridDB API key") +
            '</a>'

            textFormat: Text.RichText

            onLinkActivated: function(link) {
                Qt.openUrlExternally(link)
            }

            HoverHandler {
                cursorShape: Qt.PointingHandCursor
            }
        }
    }

    Row {
        spacing: Kirigami.Units.smallSpacing

        Kirigami.FormData.label: i18n("API key:")

        QQC2.TextField {
            id: apiKeyField

            width: 300

            placeholderText: i18n("Enter your SteamGridDB API key")

            echoMode: root.apiKeyVisible
                ? TextInput.Normal
                : TextInput.Password
        }

        QQC2.ToolButton {
            icon.name: root.apiKeyVisible
                ? "visibility"
                : "hint"

            text: root.apiKeyVisible
                ? i18n("Hide API key")
                : i18n("Show API key")

            display: QQC2.AbstractButton.IconOnly

            onClicked: {
                root.apiKeyVisible = !root.apiKeyVisible
            }

            QQC2.ToolTip.visible: hovered
            QQC2.ToolTip.text: text
        }
    }

    QQC2.Button {
        text: i18n("Save API key")

        enabled: root.apiKeyLoaded

        onClicked: {
            saveStatus.text = i18n("Saving...")

            keySaver.start(
                "python3",
                [
                    "-c",
                    "import pathlib,sys; " +
                    "p=pathlib.Path.home()/'.config'/'steambanners'/'steamgriddb.key'; " +
                    "p.parent.mkdir(parents=True,exist_ok=True); " +
                    "p.write_text(sys.argv[1].strip(),encoding='utf-8'); " +
                    "p.chmod(0o600)",
                    apiKeyField.text
                ]
            )
        }
    }

    QQC2.Label {
        id: saveStatus

        text: ""
        opacity: 0.75
    }

    Kirigami.Separator {
        Kirigami.FormData.isSection: true
        Kirigami.FormData.label:
            i18n("Cache")
    }

    Column {
        Kirigami.FormData.isSection: true

        spacing: 2

        QQC2.Label {
            text: i18n(
                "Artwork: %1 (%2 files)",
                       root.formatBytes(
                           root.cacheArtworkSize
                       ),
                       root.cacheArtworkFiles
            )
        }

        QQC2.Label {
            text: i18n(
                "Logos: %1   Heroes: %2",
                root.cacheLogoFiles,
                root.cacheHeroFiles
            )

            opacity: 0.75
        }

        QQC2.Label {
            text: i18n(
                "Metadata: %1",
                root.formatBytes(
                    root.cacheMetadataSize
                )
            )
        }

        QQC2.Label {
            text: i18n(
                "Total cache size: %1",
                root.formatBytes(
                    root.cacheTotalSize
                )
            )

            font.bold: true
        }

        QQC2.Button {
            text: root.cacheLoading
            ? i18n("Refreshing...")
            : i18n("Refresh cache information")

            enabled: !root.cacheLoading

            onClicked: {
                root.loadCacheStatus()
            }
        }

        Row {
            spacing: Kirigami.Units.smallSpacing

            QQC2.Button {
                text: root.confirmClearArtwork
                ? i18n("Confirm clear artwork")
                : i18n("Clear artwork cache")

                enabled:
                !root.cacheActionRunning
                && root.cacheArtworkFiles > 0

                onClicked: {
                    if (!root.confirmClearArtwork) {
                        root.confirmClearArtwork = true
                        root.confirmClearMetadata = false

                        cacheStatus.text =
                        i18n(
                            "Click again to clear all cached artwork."
                        )

                        cacheConfirmTimer.restart()
                        return
                    }

                    cacheConfirmTimer.stop()

                    root.runCacheAction(
                        "clear-artwork"
                    )
                }
            }

            QQC2.Button {
                text: root.confirmClearMetadata
                ? i18n("Confirm clear metadata")
                : i18n("Clear metadata cache")

                enabled:
                !root.cacheActionRunning
                && root.cacheMetadataSize > 0

                onClicked: {
                    if (!root.confirmClearMetadata) {
                        root.confirmClearMetadata = true
                        root.confirmClearArtwork = false

                        cacheStatus.text =
                        i18n(
                            "Click again to clear cached game metadata."
                        )

                        cacheConfirmTimer.restart()
                        return
                    }

                    cacheConfirmTimer.stop()

                    root.runCacheAction(
                        "clear-metadata"
                    )
                }
            }
        }

        QQC2.Label {
            id: cacheStatus

            text: ""
            opacity: 0.75
        }
    }

    Kirigami.Separator {
        Kirigami.FormData.isSection: true
        Kirigami.FormData.label:
        i18n("Steam Banners")
    }

    Column {
        Kirigami.FormData.isSection: true

        spacing: Kirigami.Units.smallSpacing

        QQC2.Label {
            text: root.installedVersion !== ""
            ? i18n(
                "Installed version: %1",
                root.installedVersion
            )
            : i18n(
                "Check for updates to see version information."
            )

            opacity: 0.85
        }

        QQC2.Label {
            visible: root.latestVersion !== ""

            text: i18n(
                "Latest version: %1",
                root.latestVersion
            )

            opacity: 0.85
        }

        Row {
            spacing: Kirigami.Units.smallSpacing

            QQC2.Button {
                text: root.updateChecking
                ? i18n("Checking...")
                : i18n("Check for updates")

                enabled: !root.updateChecking

                onClicked: {
                    root.updateChecking = true
                    root.updateOutput = ""
                    root.updateAvailable = false

                    updateStatus.text =
                    i18n("Checking for updates...")

                    updateChecker.start(
                        "python3",
                        [
                            root.updateScriptPath
                        ]
                    )
                }
            }

            QQC2.Button {
                visible:
                root.updateAvailable
                && root.updateAssetUrl !== ""

                text: root.updateInstalling
                ? i18n("Updating...")
                : i18n(
                    "Update to %1",
                    root.latestVersion
                )

                enabled:
                !root.updateChecking
                && !root.updateInstalling

                onClicked: {
                    root.updateInstalling = true
                    root.installOutput = ""
                    root.updateInstalled = false

                    updateStatus.text =
                    i18n(
                        "Downloading and installing version %1...",
                         root.latestVersion
                    )

                    updateInstaller.start(
                        "python3",
                        [
                            root.updateInstallScriptPath
                        ]
                    )
                }
            }

            QQC2.Button {
                visible:
                root.updateAvailable
                && root.updateReleaseUrl !== ""

                text: i18n("View release")

                onClicked: {
                    Qt.openUrlExternally(
                        root.updateReleaseUrl
                    )
                }
            }
        }

        QQC2.Button {
            visible: root.updateInstalled

            text: i18n("Restart Plasma")

            onClicked: {
                plasmaRestarter.start(
                    "sh",
                    [
                        "-c",
                        "nohup plasmashell --replace > /tmp/plasmashell.log 2>&1 &"
                    ]
                )
            }
        }

        QQC2.Label {
            id: updateStatus

            text: ""
            opacity: 0.75
        }
    }

    function formatBytes(bytes) {
        if (bytes < 1024) {
            return bytes + " B"
        }

        if (bytes < 1024 * 1024) {
            return (
                bytes / 1024
            ).toFixed(1) + " KiB"
        }

        return (
            bytes / (1024 * 1024)
        ).toFixed(1) + " MiB"
    }

    function loadCacheStatus() {
        root.cacheLoading = true
        root.cacheOutput = ""

        cacheStatusProcess.start(
            "python3",
            [
                root.cacheScriptPath,
                "status"
            ]
        )
    }

    function runCacheAction(action) {
        root.cacheActionRunning = true
        root.cacheActionOutput = ""
        root.cacheAction = action

        cacheStatus.text =
        i18n("Clearing cache...")

        cacheActionProcess.start(
            "python3",
            [
                root.cacheScriptPath,
                action
            ]
        )
    }

    Component.onCompleted: {
        root.loadCacheStatus()
        keyLoader.start(
            "python3",
            [
                "-c",
                "import pathlib; " +
                "p=pathlib.Path.home()/'.config'/'steambanners'/'steamgriddb.key'; " +
                "print(p.read_text(encoding='utf-8').strip() if p.exists() else '',end='')"
            ]
        )
    }
}
