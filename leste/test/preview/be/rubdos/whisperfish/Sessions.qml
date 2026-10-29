import QtQuick 2.6
// Made-up conversations for the screenshots (no Signal data).
QtObject {
    property var app
    property ListModel sessions: ListModel {}
    // ListElement cannot have an "id" role; append can
    Component.onCompleted: {
        var m = sessions
        m.append({ id: 1, isGroup: false, groupName: "", recipientId: 1, recipientUuid: "a", read: false, isPinned: true, draft: "", message: "Are we still on for the concert tonight?", timestamp: "2026-10-29T18:42:00" })
        m.append({ id: 2, isGroup: true, groupName: "Choir", recipientId: -1, recipientUuid: "", read: false, isPinned: false, draft: "", message: "Rehearsal moved to Thursday, 19:00", timestamp: "2026-10-29T16:05:00" })
        m.append({ id: 3, isGroup: false, groupName: "", recipientId: 2, recipientUuid: "b", read: true, isPinned: false, draft: "I'll bring the", message: "Thanks!", timestamp: "2026-10-28T21:17:00" })
        m.append({ id: 4, isGroup: false, groupName: "", recipientId: 0, recipientUuid: "self", read: true, isPinned: false, draft: "", message: "Shopping: bread, milk, batteries", timestamp: "2026-10-27T09:30:00" })
        m.append({ id: 5, isGroup: false, groupName: "", recipientId: 3, recipientUuid: "c", read: true, isPinned: false, draft: "", message: "See you at the station", timestamp: "2026-10-25T12:00:00" })
    }
}
