// One step of the setup: a title, an explanation and the controls
// (the children), centred and scrollable.
import QtQuick 2.6
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.3

Item {
    id: pane
    anchors.fill: parent

    property string title
    property string description
    default property alias content: layout.data

    readonly property int unit: fm.height
    SystemPalette { id: pal; colorGroup: SystemPalette.Active }
    FontMetrics { id: fm }

    ScrollView {
        id: scroll
        anchors.fill: parent

        Item {
            width: scroll.viewport.width
            height: Math.max(scroll.viewport.height, layout.implicitHeight + 4 * pane.unit)

            ColumnLayout {
                id: layout
                anchors.centerIn: parent
                width: Math.min(parent.width - 4 * pane.unit, 40 * pane.unit)
                spacing: pane.unit

                Label {
                    Layout.fillWidth: true
                    text: pane.title
                    color: pal.windowText
                    font.pixelSize: pane.unit * 1.5
                    wrapMode: Text.Wrap
                }
                Label {
                    Layout.fillWidth: true
                    text: pane.description
                    color: pal.windowText
                    opacity: 0.8
                    wrapMode: Text.Wrap
                    visible: text !== ""
                }
            }
        }
    }
}
