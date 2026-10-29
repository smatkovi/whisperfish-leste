import QtQuick 2.6
// A made-up group conversation for the screenshots (no Signal data).
QtObject {
    property var app
    property int sessionId: -1
    readonly property bool valid: sessionId > 0
    readonly property bool isGroup: true
    readonly property bool isRegistered: true
    readonly property bool isAnnouncementOnlyBlocked: false
    readonly property string groupName: "Choir"
    property string draft: ""
    // newest first, as the Rust model
    property ListModel messages: ListModel {}
    // ListElement cannot have an "id" role; append can
    Component.onCompleted: {
        var m = messages
        m.append({ id: 16, outgoing: false, isRead: false, senderRecipientId: 2, message: "Rehearsal moved to Thursday, 19:00", timestamp: "2026-10-29T16:05:00", sent: true, hasDeliveries: false, hasReads: false, failed: false, remoteDeleted: false, attachments: 0, messageType: "", isEdited: false })
        m.append({ id: 15, outgoing: true, isRead: true, senderRecipientId: 0, message: "Same room as last week?", timestamp: "2026-10-29T15:58:00", sent: true, hasDeliveries: true, hasReads: true, failed: false, remoteDeleted: false, attachments: 0, messageType: "", isEdited: false })
        m.append({ id: 14, outgoing: false, isRead: true, senderRecipientId: 3, message: "I can bring the new scores for the alto part, they arrived today.", timestamp: "2026-10-29T15:40:00", sent: true, hasDeliveries: false, hasReads: false, failed: false, remoteDeleted: false, attachments: 0, messageType: "", isEdited: true })
        m.append({ id: 13, outgoing: false, isRead: true, senderRecipientId: 2, message: "Does Thursday work for everyone?", timestamp: "2026-10-29T15:31:00", sent: true, hasDeliveries: false, hasReads: false, failed: false, remoteDeleted: false, attachments: 0, messageType: "", isEdited: false })
        m.append({ id: 12, outgoing: true, isRead: true, senderRecipientId: 0, message: "Hi all, I will be a bit late on Tuesday.", timestamp: "2026-10-28T20:10:00", sent: true, hasDeliveries: true, hasReads: false, failed: false, remoteDeleted: false, attachments: 0, messageType: "", isEdited: false })
    }
}
