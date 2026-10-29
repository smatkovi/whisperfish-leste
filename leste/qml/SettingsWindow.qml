// The few settings of the Leste user interface.
import QtQuick 2.6
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.3
import be.rubdos.whisperfish 1.0
import "components"

Rectangle {
    id: root
    color: pal.window

    property int windowId: -1
    SystemPalette { id: pal; colorGroup: SystemPalette.Active }

    function hildonMenuTriggered(index) {}

    SetupPane {
        title: qsTr("Settings")
        description: qsTr("Notifications of new messages show:")

        ExclusiveGroup { id: privacy }
        Repeater {
            model: [
                { value: "complete", text: qsTr("The sender and the message") },
                { value: "sender-only", text: qsTr("Only the sender") },
                { value: "minimal", text: qsTr("Only “New message”") },
                { value: "off", text: qsTr("Nothing (no notifications)") }
            ]
            delegate: RadioButton {
                Layout.fillWidth: true
                exclusiveGroup: privacy
                text: modelData.text
                checked: SettingsBridge.notification_privacy.toString() === modelData.value
                onClicked: SettingsBridge.notification_privacy = modelData.value
            }
        }

        CheckBox {
            Layout.fillWidth: true
            Layout.topMargin: 16
            text: qsTr("The Return key sends the message (Shift+Return: new line)")
            checked: SettingsBridge.enable_enter_send
            onClicked: SettingsBridge.enable_enter_send = checked
        }
    }
}
