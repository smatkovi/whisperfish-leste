// The few settings of the Leste user interface.
import QtQuick 2.6
import QtQuick.Controls 1.4
import QtQuick.Controls.Styles 1.4
import QtQuick.Layouts 1.3
import be.rubdos.whisperfish 1.0
import "components"

Rectangle {
    id: root
    color: pal.window

    property int windowId: -1
    SystemPalette { id: pal; colorGroup: SystemPalette.Active }

    function hildonMenuTriggered(index) {}

    // The Maemo 5 Qt style draws the labels dark on the dark theme: own
    // indicators and labels in the theme's text colour.
    FontMetrics { id: fm }
    Component {
        id: radioStyle
        RadioButtonStyle {
            spacing: fm.height / 2
            indicator: Rectangle {
                implicitWidth: fm.height * 1.4
                implicitHeight: implicitWidth
                radius: width / 2
                color: "#2e2e2e"
                border.color: "#8a8a8a"
                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width / 2
                    height: width
                    radius: width / 2
                    color: pal.highlight
                    visible: control.checked
                }
            }
            label: Text { text: control.text; color: pal.windowText; font: fm.font; height: fm.height * 1.4; verticalAlignment: Text.AlignVCenter }
        }
    }
    Component {
        id: checkStyle
        CheckBoxStyle {
            spacing: fm.height / 2
            indicator: Rectangle {
                implicitWidth: fm.height * 1.4
                implicitHeight: implicitWidth
                radius: 3
                color: "#2e2e2e"
                border.color: "#8a8a8a"
                Text {
                    anchors.centerIn: parent
                    text: "✓"
                    color: pal.highlight
                    font.pixelSize: parent.height * 0.8
                    visible: control.checked
                }
            }
            label: Text { text: control.text; color: pal.windowText; font: fm.font; height: fm.height * 1.4; verticalAlignment: Text.AlignVCenter }
        }
    }

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
                style: radioStyle
                checked: SettingsBridge.notification_privacy.toString() === modelData.value
                onClicked: SettingsBridge.notification_privacy = modelData.value
            }
        }

        CheckBox {
            Layout.fillWidth: true
            Layout.topMargin: 16
            text: qsTr("The Return key sends the message (Shift+Return: new line)")
            style: checkStyle
            checked: SettingsBridge.enable_enter_send
            onClicked: SettingsBridge.enable_enter_send = checked
        }
    }
}
