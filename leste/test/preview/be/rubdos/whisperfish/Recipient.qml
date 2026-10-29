import QtQuick 2.6
QtObject {
    property var app
    property int recipientId: -1
    readonly property bool valid: recipientId > 0
    readonly property var names: ({ 1: "Anna Berger", 2: "Ben Huber", 3: "Clara Novak", 4: "Daniel Wagner" })
    readonly property string name: names[recipientId] !== undefined ? names[recipientId] : ""
    readonly property string phoneNumber: ""
    readonly property string username: ""
}
