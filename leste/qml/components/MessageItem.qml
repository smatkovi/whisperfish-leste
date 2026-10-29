// One message of a conversation: a bubble, right for own messages.
import QtQuick 2.6
import QtQuick.Controls 1.4
import be.rubdos.whisperfish 1.0

Item {
    id: item
    property bool isGroup: false

    readonly property int unit: fm.height
    readonly property bool outgoing: model.outgoing
    readonly property bool service: model.messageType !== undefined && model.messageType !== null && model.messageType !== ""

    height: bubble.height
    // attachments are at most this wide
    readonly property real attachmentWidth: details.status === Loader.Ready ? 15 * unit : 0
    readonly property string timeFormat: Qt.locale().timeFormat(Locale.ShortFormat).replace(/:ss/, "")
    SystemPalette { id: pal; colorGroup: SystemPalette.Active }
    FontMetrics { id: fm }

    Loader {
        id: sender
        active: item.isGroup && !item.outgoing && !item.service
        sourceComponent: Recipient {
            app: AppState
            recipientId: model.senderRecipientId
        }
    }

    Loader {
        id: details
        active: model.attachments > 0
        sourceComponent: Message {
            app: AppState
            messageId: model.id
        }
    }

    function status() {
        if (!outgoing) return ""
        if (model.failed) return qsTr("failed")
        if (model.hasReads) return "✓✓ " + qsTr("read")
        if (model.hasDeliveries) return "✓✓"
        if (model.sent) return "✓"
        return qsTr("sending…")
    }

    Rectangle {
        id: bubble
        x: item.service ? (item.width - width) / 2 : (item.outgoing ? item.width - width - unit : unit)
        // the natural (unwrapped) widths of the parts, at most 80 % of the view
        width: Math.min(Math.max(senderLabel.implicitWidth, textLabel.implicitWidth,
                                 meta.implicitWidth, item.attachmentWidth) + unit,
                        item.width * 0.8)
        height: column.height + unit
        radius: unit / 2
        color: item.service ? "transparent" : (item.outgoing ? pal.highlight : pal.base)
        border.color: pal.mid
        border.width: item.service ? 0 : 1

        Column {
            id: column
            x: unit / 2
            y: unit / 2
            width: bubble.width - unit
            spacing: unit / 4

            Label {
                id: senderLabel
                visible: sender.status === Loader.Ready
                text: sender.item ? (sender.item.name ? sender.item.name : sender.item.phoneNumber) : ""
                font.bold: true
                color: item.outgoing ? pal.highlightedText : pal.text
            }

            Repeater {
                model: details.item ? details.item.thumbsAttachments : null
                delegate: Image {
                    width: Math.min(column.width, 15 * item.unit)
                    height: status === Image.Ready ? width * sourceSize.height / Math.max(1, sourceSize.width) : 3 * item.unit
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    sourceSize.width: 15 * item.unit
                    source: model.data && model.type.indexOf("image/") === 0 ? "file://" + model.data : ""
                    MouseArea {
                        anchors.fill: parent
                        onClicked: if (model.data) Qt.openUrlExternally("file://" + model.data)
                    }
                }
            }

            Repeater {
                model: details.item ? details.item.detailAttachments : null
                delegate: Label {
                    width: column.width
                    elide: Text.ElideMiddle
                    color: item.outgoing ? pal.highlightedText : pal.text
                    font.underline: !!model.data
                    text: model.data ? model.data.replace(/.*\//, "") : qsTr("%1 (tap to download)").arg(model.type)
                    MouseArea {
                        anchors.fill: parent
                        onClicked: model.data ? Qt.openUrlExternally("file://" + model.data)
                                              : ClientWorker.fetchAttachment(model.id)
                    }
                }
            }

            Label {
                id: textLabel
                width: column.width
                visible: text !== ""
                wrapMode: Text.Wrap
                textFormat: Text.PlainText
                color: item.service ? pal.windowText : (item.outgoing ? pal.highlightedText : pal.text)
                font.italic: model.remoteDeleted || item.service
                opacity: item.service ? 0.7 : 1
                text: model.remoteDeleted ? qsTr("This message was deleted.")
                      : (model.message ? model.message : "")
            }

            Label {
                id: meta
                anchors.right: parent.right
                color: item.outgoing ? pal.highlightedText : pal.text
                opacity: 0.7
                font.pixelSize: item.unit * 0.75
                visible: !item.service
                text: {
                    var d = new Date(model.timestamp)
                    var t = d.toDateString() === new Date().toDateString()
                            ? Qt.formatTime(d, item.timeFormat)
                            : Qt.formatDate(d, Qt.DefaultLocaleShortDate) + " " + Qt.formatTime(d, item.timeFormat)
                    var s = item.status()
                    return (model.isEdited ? qsTr("edited") + " · " : "") + t + (s !== "" ? " · " + s : "")
                }
            }
        }
    }
}
