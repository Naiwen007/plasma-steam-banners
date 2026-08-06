import QtQuick
import QtQuick.Controls
import org.kde.plasma.plasmoid

PlasmoidItem {

    implicitWidth: 400
    implicitHeight: 400

    Text {
        anchors.centerIn: parent
        color: "white"
        text: "Testar JSON..."
    }

    Component.onCompleted: {

        var xhr = new XMLHttpRequest()

        xhr.onreadystatechange = function() {

            if (xhr.readyState === XMLHttpRequest.DONE) {

                console.log("STATUS:", xhr.status)
                console.log("DATA:", xhr.responseText)

            }
        }

        xhr.open(
            "GET",
            Qt.resolvedUrl("../data/games.json")
        )

        xhr.send()
    }
}
