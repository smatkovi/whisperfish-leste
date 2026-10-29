pragma Singleton
import QtQuick 2.6
QtObject { function createMessage(sid, text, att, quote, add, voice) { console.log("send", sid, text) } }
