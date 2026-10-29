// Start a conversation with a Signal username.
import QtQuick 2.6
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.3
import be.rubdos.whisperfish 1.0
import "components"

Rectangle {
    id: root
    color: pal.window

    property int windowId: -1
    readonly property int unit: fm.height

    SystemPalette { id: pal; colorGroup: SystemPalette.Active }
    FontMetrics { id: fm }

    function hildonMenuTriggered(index) {}

    CreateConversation {
        id: conversation
        app: AppState
        onSessionIdChanged: {
            if (sessionId >= 0) {
                Hildon.openWindow(Qt.resolvedUrl("ConversationWindow.qml"), { sessionId: sessionId },
                                  conversation.hasName ? conversation.name : username.text)
                Hildon.closeWindow(root.windowId)
            }
        }
        onBusyChanged: Hildon.setBusy(root.windowId, busy)
    }

    SetupPane {
        title: qsTr("New conversation")
        description: qsTr("Enter the Signal username of the person, for example “name.42”.")
        TextField {
            id: username
            Layout.fillWidth: true
            inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText
            placeholderText: qsTr("Username")
            onAccepted: startButton.clicked()
        }
        HButton {
            id: startButton
            text: qsTr("Start")
            Layout.fillWidth: true
            enabled: username.text.indexOf(".") > 0 && !conversation.busy
            onClicked: conversation.query = username.text.trim().replace(/^@/, "")
        }
        Label {
            Layout.fillWidth: true
            visible: conversation.error !== "" || conversation.invalid
            color: pal.windowText
            wrapMode: Text.Wrap
            text: conversation.error.indexOf("unavailable") >= 0
                  ? qsTr("Not ready yet. Please try again in a moment.")
                  : qsTr("This username was not found.")
        }
    }
}
