// Whisperfish for Maemo Leste: the main window.
//
// Shows the setup steps (database password, linking QR code, or the
// registration of a new account) and then the list of conversations.
// Conversations and the other pages open as Hildon stacked windows
// (Hildon.openWindow), the entries of the application menu come from
// Hildon.setMenu.
import QtQuick 2.6
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.3
import be.rubdos.whisperfish 1.0
import "components"

Rectangle {
    id: root
    color: pal.window

    property int windowId: 0
    // setup step: starting, newPassword, unlock, registrationType,
    // link, phoneNumber, captcha, verificationCode, main, error
    property string step: "starting"
    property string errorText: ""
    property int conversationWindow: -1
    property int conversationSession: -1
    property var notifications: ({})

    readonly property int unit: fm.height

    SystemPalette { id: pal; colorGroup: SystemPalette.Active }
    FontMetrics { id: fm }

    Sessions {
        id: sessions
        app: AppState
    }

    function setStep(s) {
        step = s
        Hildon.setBusy(windowId, s === "starting")
        if (s === "main") {
            Hildon.setMenu(windowId, [qsTr("New conversation"), qsTr("About")])
        } else {
            Hildon.setMenu(windowId, [qsTr("About")])
        }
    }

    function hildonMenuTriggered(index) {
        var entry = step === "main" ? index : index + 1
        if (entry === 0) {
            Hildon.openWindow(Qt.resolvedUrl("NewConversationWindow.qml"), {}, qsTr("New conversation"))
        } else if (entry === 1) {
            Hildon.openWindow(Qt.resolvedUrl("AboutWindow.qml"), {}, qsTr("About Whisperfish"))
        }
    }

    // One conversation at a time, like the Maemo 5 conversations app.
    function openConversation(sessionId, title) {
        if (conversationWindow >= 0) {
            Hildon.closeWindow(conversationWindow)
        }
        conversationSession = sessionId
        conversationWindow = Hildon.openWindow(Qt.resolvedUrl("ConversationWindow.qml"),
                                               { sessionId: sessionId }, title)
        closeNotification(sessionId)
    }

    function closeNotification(sessionId) {
        var id = notifications[sessionId]
        if (id !== undefined) {
            Hildon.closeNotification(id)
            delete notifications[sessionId]
        }
    }

    function notifyMessage(data) {
        var privacy = SettingsBridge.notification_privacy.toString()
        if (privacy === "off") {
            return
        }
        if (Qt.application.state === Qt.ApplicationActive && conversationSession === data.sessionId) {
            return
        }
        var sender = data.senderName ? data.senderName : (data.senderE164 ? data.senderE164 : qsTr("Signal"))
        var title = data.isGroup ? data.sessionName : sender
        var body = qsTr("New message")
        if (privacy === "complete") {
            body = data.isGroup ? sender + ": " + data.message : data.message
        }
        if (privacy === "minimal") {
            title = "Whisperfish"
        }
        var old = notifications[data.sessionId]
        notifications[data.sessionId] = Hildon.notify(old !== undefined ? old : 0, title, body)
    }

    Connections {
        target: Prompt
        function onPromptPassword() { setStep(SetupWorker.registered ? "unlock" : "newPassword") }
        function onPromptRegistrationType() { setStep("registrationType") }
        function onShowLinkQR() { setStep("link") }
        function onPromptPhoneNumber() { setStep("phoneNumber") }
        function onPromptCaptcha() { setStep("captcha") }
        function onPromptVerificationCode() { setStep("verificationCode") }
    }

    Connections {
        target: SetupWorker
        function onSetupComplete() { setStep(SetupWorker.registered ? "main" : "error") }
        function onInvalidDatastore() {
            errorText = qsTr("The database could not be opened. Was the password wrong?")
            setStep("error")
        }
        function onInvalidPhoneNumber() {
            errorText = qsTr("The phone number is not valid.")
            setStep("phoneNumber")
        }
        function onClientFailed() {
            errorText = qsTr("Setting up failed: a wrong password, or no connection to Signal. Start Whisperfish again to retry.")
            setStep("error")
        }
    }

    Connections {
        target: ClientWorker
        function onNotifyMessage(data) {
            if (data.message !== undefined) {
                notifyMessage(data)
            }
        }
    }

    Component.onCompleted: setStep("starting")

    // ---- setup steps ------------------------------------------------------

    Column {
        anchors.centerIn: parent
        spacing: unit
        visible: step === "starting"
        BusyIndicator { anchors.horizontalCenter: parent.horizontalCenter; running: parent.visible }
        Label { text: qsTr("Starting…"); color: pal.windowText }
    }

    SetupPane {
        visible: step === "newPassword"
        title: qsTr("Protect the database")
        description: qsTr("Whisperfish keeps your messages in an encrypted database. Choose a password, or continue without one.")
        TextField {
            id: newPassword1
            Layout.fillWidth: true
            echoMode: TextInput.Password
            placeholderText: qsTr("Password")
        }
        TextField {
            id: newPassword2
            Layout.fillWidth: true
            echoMode: TextInput.Password
            placeholderText: qsTr("Repeat the password")
            onAccepted: savePassword.clicked()
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: unit
            Button {
                text: qsTr("No password")
                Layout.fillWidth: true
                onClicked: { Prompt.password(""); setStep("starting") }
            }
            Button {
                id: savePassword
                text: qsTr("Save")
                Layout.fillWidth: true
                enabled: newPassword1.text.length >= 6 && newPassword1.text === newPassword2.text
                onClicked: { Prompt.password(newPassword1.text); setStep("starting") }
            }
        }
        Label {
            visible: newPassword1.text.length > 0 && newPassword1.text.length < 6
            text: qsTr("At least 6 characters.")
            color: pal.windowText
        }
    }

    SetupPane {
        visible: step === "unlock"
        title: qsTr("Unlock")
        description: qsTr("Enter the password of the Whisperfish database.")
        TextField {
            id: unlockPassword
            Layout.fillWidth: true
            echoMode: TextInput.Password
            placeholderText: qsTr("Password")
            onAccepted: unlockButton.clicked()
        }
        Button {
            id: unlockButton
            text: qsTr("Unlock")
            Layout.fillWidth: true
            enabled: unlockPassword.text.length > 0
            onClicked: {
                Prompt.password(unlockPassword.text)
                unlockPassword.text = ""
                setStep("starting")
            }
        }
    }

    SetupPane {
        visible: step === "registrationType"
        title: qsTr("Welcome to Whisperfish")
        description: qsTr("Whisperfish works best as a linked device of the Signal app on your phone, like Signal Desktop.")
        Button {
            text: qsTr("Link to my Signal account")
            Layout.fillWidth: true
            onClicked: { Prompt.registerAsPrimary(false); setStep("starting") }
        }
        Button {
            text: qsTr("Register a new account")
            Layout.fillWidth: true
            onClicked: { Prompt.registerAsPrimary(true); setStep("starting") }
        }
    }

    SetupPane {
        id: linkPane
        visible: step === "link"
        title: qsTr("Link this device")
        description: qsTr("On your phone, open Signal → Settings → Linked devices → Link new device, and scan this code.")
        Rectangle {
            // a white quiet zone around the code, whatever the theme
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: Math.min(root.width - 4 * unit, root.height - 12 * unit)
            Layout.preferredHeight: Layout.preferredWidth
            color: "white"
            Image {
                anchors.fill: parent
                anchors.margins: unit
                source: Prompt.linkingQR
                fillMode: Image.PreserveAspectFit
                smooth: false
                cache: false
            }
        }
    }

    SetupPane {
        visible: step === "phoneNumber"
        title: qsTr("Register")
        description: errorText !== "" ? errorText : qsTr("Your phone number in international format, e.g. +43 660 1234567.")
        TextField {
            id: phoneNumber
            Layout.fillWidth: true
            inputMethodHints: Qt.ImhDialableCharactersOnly
            placeholderText: "+"
            onAccepted: phoneButton.clicked()
        }
        Button {
            id: phoneButton
            text: qsTr("Continue")
            Layout.fillWidth: true
            enabled: phoneNumber.text.length > 4
            onClicked: {
                errorText = ""
                Prompt.phoneNumber(phoneNumber.text.replace(/[^+0-9]/g, ""))
                setStep("starting")
            }
        }
    }

    SetupPane {
        visible: step === "captcha"
        title: qsTr("Captcha")
        description: qsTr("Signal wants a captcha. Solve it in the browser, then copy the address of the “Open Signal” link (signalcaptcha://…) and paste it here.")
        Button {
            text: qsTr("Open the captcha page")
            Layout.fillWidth: true
            onClicked: Prompt.startCaptcha()
        }
        TextField {
            id: captchaToken
            Layout.fillWidth: true
            placeholderText: "signalcaptcha://"
        }
        Button {
            text: qsTr("Continue")
            Layout.fillWidth: true
            enabled: captchaToken.text.indexOf("signalcaptcha://") === 0
            onClicked: { Prompt.captcha(captchaToken.text.trim()); setStep("starting") }
        }
    }

    SetupPane {
        visible: step === "verificationCode"
        title: qsTr("Verification")
        description: qsTr("Enter the code Signal sent to your phone.")
        TextField {
            id: verificationCode
            Layout.fillWidth: true
            inputMethodHints: Qt.ImhDigitsOnly
            onAccepted: verifyButton.clicked()
        }
        Button {
            id: verifyButton
            text: qsTr("Verify")
            Layout.fillWidth: true
            enabled: verificationCode.text.replace(/[^0-9]/g, "").length === 6
            onClicked: { Prompt.verificationCode(verificationCode.text.replace(/[^0-9]/g, "")); setStep("starting") }
        }
    }

    SetupPane {
        visible: step === "error"
        title: qsTr("Whisperfish cannot start")
        description: errorText !== "" ? errorText : qsTr("This device is not registered.")
        Button {
            text: qsTr("Close")
            Layout.fillWidth: true
            onClicked: Qt.quit()
        }
    }

    // ---- conversations ----------------------------------------------------

    ListView {
        id: sessionList
        anchors.fill: parent
        visible: step === "main"
        clip: true
        model: sessions.sessions
        delegate: SessionItem {
            width: sessionList.width
            onClicked: openConversation(model.id, name)
        }

        Label {
            anchors.centerIn: parent
            visible: sessionList.count === 0
            width: parent.width - 4 * unit
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            color: pal.windowText
            text: ClientWorker.connected
                  ? qsTr("No conversations yet. Messages sent to you from now on appear here.")
                  : qsTr("Connecting to Signal…")
        }
    }
}
