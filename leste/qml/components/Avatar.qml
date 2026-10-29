// A round placeholder picture with the first letter of the name.
import QtQuick 2.6

Rectangle {
    property string name
    property bool group: false

    radius: width / 2
    color: Qt.hsla((hash(name) % 360) / 360, 0.45, 0.45, 1)

    function hash(s) {
        var h = 0
        for (var i = 0; i < s.length; i++) {
            h = (h * 31 + s.charCodeAt(i)) & 0xffff
        }
        return h
    }

    Text {
        anchors.centerIn: parent
        text: group ? "#" : (name.length > 0 ? name.charAt(0).toUpperCase() : "?")
        color: "white"
        font.pixelSize: parent.height * 0.5
        font.bold: true
    }
}
