// A conversation, in a stacked window: the messages and a text field.
import QtQuick 2.6
import QtQuick.Controls 1.4
import QtQuick.Dialogs 1.2
import QtQuick.Layouts 1.3
import be.rubdos.whisperfish 1.0
import "components"

Rectangle {
    id: root
    color: pal.window

    property int windowId: -1
    property int sessionId: -1
    property var attachments: []
    property var toMarkRead: ({})

    readonly property int unit: fm.height
    readonly property bool isGroup: session.valid && session.isGroup
    readonly property bool canSend: session.valid && session.isRegistered && !session.isAnnouncementOnlyBlocked

    SystemPalette { id: pal; colorGroup: SystemPalette.Active }
    FontMetrics { id: fm }

    Session {
        id: session
        app: AppState
        sessionId: root.sessionId
        onValidChanged: {
            if (valid && session.draft && input.text === "") {
                input.text = session.draft
            }
        }
    }

    function hildonMenuTriggered(index) {}

    // Incoming messages that are shown get marked as read, in batches.
    function markRead(id) {
        toMarkRead[id] = true
        markReadTimer.restart()
    }
    Timer {
        id: markReadTimer
        interval: 500
        onTriggered: {
            // only what the user can see: wait while the window is not active
            if (Qt.application.state !== Qt.ApplicationActive) {
                return
            }
            var ids = Object.keys(root.toMarkRead)  // strings, as the worker expects
            root.toMarkRead = {}
            if (ids.length > 0) {
                ClientWorker.mark_messages_read(ids)
            }
        }
    }
    Connections {
        target: Qt.application
        function onStateChanged() { markReadTimer.restart() }
    }

    function mimeType(path) {
        var ext = path.toLowerCase().replace(/.*\./, "")
        var types = {
            jpg: "image/jpeg", jpeg: "image/jpeg", png: "image/png", gif: "image/gif",
            webp: "image/webp", mp4: "video/mp4", webm: "video/webm", mkv: "video/x-matroska",
            mp3: "audio/mpeg", ogg: "audio/ogg", opus: "audio/ogg", m4a: "audio/mp4",
            aac: "audio/aac", wav: "audio/wav", pdf: "application/pdf", txt: "text/plain",
            zip: "application/zip", vcf: "text/vcard"
        }
        return types[ext] !== undefined ? types[ext] : "application/octet-stream"
    }

    function send() {
        var text = input.text.trim()
        if (text === "" && attachments.length === 0) {
            return
        }
        MessageModel.createMessage(sessionId, text, attachments, -1, true, false)
        input.text = ""
        attachments = []
        SessionModel.saveDraft(sessionId, "")
    }

    FileDialog {
        id: fileDialog
        title: qsTr("Attach a file")
        folder: shortcuts.pictures
        selectMultiple: true
        onAccepted: {
            var list = root.attachments.slice()
            for (var i = 0; i < fileUrls.length; i++) {
                var path = decodeURIComponent(fileUrls[i].toString().replace(/^file:\/\//, ""))
                list.push({ data: path, type: mimeType(path) })
            }
            root.attachments = list
        }
    }

    ListView {
        id: messages
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: composer.top
        clip: true
        verticalLayoutDirection: ListView.BottomToTop
        spacing: unit / 2
        model: session.valid ? session.messages : null
        header: Item { height: unit / 2 }
        footer: Item { height: unit / 2 }
        delegate: MessageItem {
            width: messages.width
            isGroup: root.isGroup
            Component.onCompleted: {
                if (!model.outgoing && !model.isRead) {
                    root.markRead(model.id)
                }
            }
        }

        Label {
            anchors.centerIn: parent
            visible: messages.count === 0
            color: pal.windowText
            opacity: 0.7
            text: qsTr("No messages")
        }
    }

    Rectangle {
        id: composer
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: composerLayout.implicitHeight + unit
        color: pal.window

        Rectangle {
            anchors.top: parent.top
            width: parent.width
            height: 1
            color: pal.mid
            opacity: 0.5
        }

        ColumnLayout {
            id: composerLayout
            anchors.fill: parent
            anchors.margins: unit / 2
            spacing: unit / 2

            Label {
                Layout.fillWidth: true
                visible: root.attachments.length > 0
                color: pal.windowText
                elide: Text.ElideMiddle
                text: {
                    var names = []
                    for (var i = 0; i < root.attachments.length; i++) {
                        names.push(root.attachments[i].data.replace(/.*\//, ""))
                    }
                    return qsTr("Attached: %1 (tap to remove)").arg(names.join(", "))
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: root.attachments = []
                }
            }

            Label {
                Layout.fillWidth: true
                visible: !root.canSend && session.valid
                color: pal.windowText
                wrapMode: Text.Wrap
                text: session.isAnnouncementOnlyBlocked
                      ? qsTr("Only admins can send messages to this group.")
                      : qsTr("This contact is not on Signal.")
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: unit / 2
                visible: root.canSend

                Button {
                    text: qsTr("Attach")
                    Layout.fillHeight: true
                    onClicked: fileDialog.open()
                }

                TextArea {
                    id: input
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(Math.max(2.5 * unit, contentHeight + unit), 6 * unit)
                    wrapMode: TextEdit.Wrap
                    onTextChanged: draftTimer.restart()
                    Keys.onReturnPressed: {
                        if (SettingsBridge.enable_enter_send && !(event.modifiers & Qt.ShiftModifier)) {
                            root.send()
                        } else {
                            event.accepted = false
                        }
                    }
                }

                Button {
                    text: qsTr("Send")
                    Layout.fillHeight: true
                    enabled: input.text.trim().length > 0 || root.attachments.length > 0
                    onClicked: root.send()
                }
            }
        }
    }

    Timer {
        id: draftTimer
        interval: 2000
        onTriggered: {
            if (root.sessionId >= 0 && session.valid && session.draft !== input.text) {
                SessionModel.saveDraft(root.sessionId, input.text)
            }
        }
    }
}
