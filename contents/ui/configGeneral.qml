import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    property alias cfg_columns: columnsSpinBox.value
    property alias cfg_cardHeight: cardHeightSpinBox.value
    property alias cfg_sortMode: sortCombo.currentIndex

    QQC2.SpinBox {
        id: columnsSpinBox

        Kirigami.FormData.label: i18n("Antal kolumner:")

        from: 1
        to: 5
    }

    QQC2.SpinBox {
        id: cardHeightSpinBox

        Kirigami.FormData.label: i18n("Korthöjd:")

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

        Kirigami.FormData.label: i18n("Sortering:")

        model: [
            i18n("Alfabetiskt (A–Ö)"),
            i18n("Favoriter först")
        ]
    }
}
