// A button in the look of Maemo 5 (Fremantle): dark, rounded, white text,
// the theme's selection colour while pressed. QtQuick.Controls 1 draws
// buttons through the Qt style, which under Leste's Maemo 5 style comes
// out light with white text; this keeps them readable on the dark theme.
import QtQuick 2.6
import QtQuick.Controls 1.4
import QtQuick.Controls.Styles 1.4

Button {
    id: button
    readonly property int unit: fm.height
    implicitHeight: 2.6 * unit
    SystemPalette { id: pal; colorGroup: SystemPalette.Active }
    FontMetrics { id: fm }

    style: ButtonStyle {
        background: Rectangle {
            implicitWidth: 6 * button.unit
            implicitHeight: 2.6 * button.unit
            radius: button.unit / 2
            border.width: 1
            border.color: control.pressed ? Qt.darker(pal.highlight, 1.3) : "#6a6a6a"
            gradient: Gradient {
                GradientStop { position: 0; color: control.pressed ? Qt.lighter(pal.highlight, 1.2) : "#5c5c5c" }
                GradientStop { position: 1; color: control.pressed ? pal.highlight : "#2e2e2e" }
            }
            opacity: control.enabled ? 1 : 0.5
        }
        label: Text {
            text: control.text
            color: "white"
            font: fm.font
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            opacity: control.enabled ? 1 : 0.6
        }
    }
}
