pragma Singleton
import QtQuick 2.6
QtObject {
    signal notifyMessage(var data)
    property bool connected: true
    function mark_messages_read(ids) { console.log("mark read", ids) }
    function fetchAttachment(id) {}
}
