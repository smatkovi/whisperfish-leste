pragma Singleton
import QtQuick 2.6
// Stand-in for the Rust SetupWorker: a linked device, set up after a moment.
Item {
    id: w
    signal setupComplete
    signal invalidDatastore
    signal invalidPhoneNumber
    signal clientFailed
    property bool registered: true
    property string uuid: "self"
    property string phoneNumber: "+43 660 0000000"
    property int deviceId: 2
    Timer { running: true; interval: 300; onTriggered: w.setupComplete() }
}
