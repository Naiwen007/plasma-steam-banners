import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    property alias cfg_columns: columnsSpinBox.value

    QQC2.SpinBox {
        id: columnsSpinBox

        Kirigami.FormData.label: i18n("Antal kolumner:")

        from: 1
        to: 5
    }
}
