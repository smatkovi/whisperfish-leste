// A conversation in the main window: picture, name, last message, time.
import QtQuick 2.6
import QtQuick.Controls 1.4
import be.rubdos.whisperfish 1.0

Item {
    id: item
    signal clicked

    readonly property int unit: fm.height
    readonly property bool isGroup: model.isGroup
    readonly property bool unread: !model.read
    readonly property string name: {
        if (isGroup) {
            return model.groupName ? model.groupName : qsTr("Group")
        }
        if (model.recipientUuid === SetupWorker.uuid) {
            return qsTr("Note to self")
        }
        if (recipient.valid) {
            if (recipient.name) return recipient.name
            if (recipient.phoneNumber) return recipient.phoneNumber
            if (recipient.username) return recipient.username
        }
        return qsTr("Unknown")
    }

    height: 4 * unit
    SystemPalette { id: pal; colorGroup: SystemPalette.Active }
    FontMetrics { id: fm }

    Recipient {
        id: recipient
        app: AppState
        recipientId: item.isGroup ? -1 : model.recipientId
    }

    Rectangle {
        anchors.fill: parent
        color: pal.highlight
        visible: mouse.pressed
    }

    Avatar {
        id: avatar
        anchors.left: parent.left
        anchors.leftMargin: unit
        anchors.verticalCenter: parent.verticalCenter
        width: 3 * unit
        height: width
        name: item.name
        group: item.isGroup
    }

    Label {
        id: time
        anchors.right: parent.right
        anchors.rightMargin: unit
        anchors.top: avatar.top
        color: pal.windowText
        opacity: 0.7
        text: {
            if (!model.timestamp) return ""
            var d = new Date(model.timestamp)
            var now = new Date()
            return d.toDateString() === now.toDateString()
                   ? Qt.formatTime(d, Qt.locale().timeFormat(Locale.ShortFormat).replace(/:ss/, ""))
                   : Qt.formatDate(d, Qt.DefaultLocaleShortDate)
        }
    }

    Label {
        anchors.left: avatar.right
        anchors.leftMargin: unit
        anchors.right: time.left
        anchors.rightMargin: unit
        anchors.top: avatar.top
        elide: Text.ElideRight
        color: pal.windowText
        font.bold: item.unread
        text: (model.isPinned ? "★ " : "") + item.name
    }

    Label {
        anchors.left: avatar.right
        anchors.leftMargin: unit
        anchors.right: parent.right
        anchors.rightMargin: unit
        anchors.bottom: avatar.bottom
        elide: Text.ElideRight
        color: pal.windowText
        opacity: item.unread ? 1 : 0.6
        text: model.draft.length > 0
              ? qsTr("Draft: %1").arg(model.draft)
              : (model.message ? model.message.replace(/\n/g, " ") : "")
    }

    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: unit
        anchors.rightMargin: unit
        height: 1
        color: pal.mid
        opacity: 0.4
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        onClicked: item.clicked()
    }
}
