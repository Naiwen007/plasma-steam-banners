import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import SteamBanners.Process

Kirigami.FormLayout {
    id: root

    property alias cfg_columns: columnsSpinBox.value
    property alias cfg_cardHeight: cardHeightSpinBox.value
    property alias cfg_sortMode: sortCombo.currentIndex

    property bool apiKeyVisible: false
    property bool apiKeyLoaded: false

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

        spacing: Kirigami.Units.smallSpacing

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

    Component.onCompleted: {
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
