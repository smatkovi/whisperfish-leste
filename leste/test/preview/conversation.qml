// Preview of ConversationWindow.qml with made-up data (mock be.rubdos.whisperfish):
//   qmlscene -I leste/test/preview leste/test/preview/conversation.qml
import QtQuick 2.6

Item {
    width: 960
    height: 440
    Loader {
        anchors.fill: parent
        source: "../../qml/ConversationWindow.qml"
        onLoaded: if (item.sessionId !== undefined) item.sessionId = 2
    }
}
