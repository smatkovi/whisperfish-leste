pragma Singleton
import QtQuick 2.6
QtObject {
    function openWindow(url, props, title) { console.log("openWindow", url, title); return 1 }
    function closeWindow(id) {}
    function setTitle(id, title) {}
    function setMenu(id, items) { console.log("menu", items) }
    function setBusy(id, busy) {}
    function banner(text) {}
    function notify(replaces, summary, body) { return 1 }
    function closeNotification(id) {}
}
