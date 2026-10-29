// About Whisperfish for Maemo Leste.
import QtQuick 2.6
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.3
import be.rubdos.whisperfish 1.0
import "components"

Rectangle {
    id: root
    color: pal.window

    property int windowId: -1
    SystemPalette { id: pal; colorGroup: SystemPalette.Active }

    function hildonMenuTriggered(index) {}

    SetupPane {
        title: "Whisperfish " + LongAppVersion
        description: qsTr("An unofficial Signal client.\n\n"
                          + "Whisperfish is made by Ruben De Smet and the Whisperfish contributors "
                          + "for Sailfish OS; this is its port to Maemo Leste with a Hildon user "
                          + "interface. Licensed under the GNU AGPL v3.\n\n"
                          + "Signal is a trademark of Signal Messenger, LLC; Whisperfish is not "
                          + "affiliated with it.")
        Button {
            text: qsTr("Whisperfish")
            Layout.fillWidth: true
            onClicked: Qt.openUrlExternally("https://gitlab.com/whisperfish/whisperfish")
        }
        Button {
            text: qsTr("This port")
            Layout.fillWidth: true
            onClicked: Qt.openUrlExternally("https://github.com/smatkovi/whisperfish-leste")
        }
        Label {
            Layout.fillWidth: true
            visible: SetupWorker.registered
            color: pal.windowText
            opacity: 0.8
            wrapMode: Text.Wrap
            text: qsTr("Linked as device %1 of %2").arg(SetupWorker.deviceId).arg(SetupWorker.phoneNumber)
        }
    }
}
