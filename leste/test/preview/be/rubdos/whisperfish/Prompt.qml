pragma Singleton
import QtQuick 2.6
QtObject {
    signal promptPassword
    signal promptRegistrationType
    signal showLinkQR
    signal promptPhoneNumber
    signal promptCaptcha
    signal promptVerificationCode
    property string linkingQR: ""
    function password(p) {}
    function registerAsPrimary(p) {}
    function phoneNumber(n) {}
    function captcha(c) {}
    function verificationCode(c) {}
    function startCaptcha() {}
}
