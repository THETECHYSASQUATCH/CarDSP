import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: shell
    default property alias pages: stack.data
    property alias currentIndex: stack.currentIndex
    readonly property var pageNames: [
        "Dashboard", "32-Band Equalizer", "Response & Spectrum",
        "Channel Routing", "Crossovers", "Time Alignment", "Presets", "Settings"
    ]
    readonly property bool compact: width < 850
    function selectPage(index) {
        if (index >= 0 && index < pageNames.length)
            currentIndex = index
    }
    RowLayout {
        anchors.fill: parent
        spacing: 12
        ScrollView {
            visible: !shell.compact
            Layout.preferredWidth: 200
            Layout.fillHeight: true
            contentWidth: availableWidth
            ColumnLayout {
                width: parent.width
                Label { text: "CarDSP"; font.pixelSize: 28; color: "#39d6c1" }
                Repeater {
                    model: shell.pageNames
                    delegate: Button {
                        required property string modelData
                        required property int index
                        Layout.fillWidth: true
                        text: modelData
                        highlighted: shell.currentIndex === index
                        Accessible.name: "Open " + modelData
                        onClicked: shell.selectPage(index)
                    }
                }
            }
        }
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            ComboBox {
                objectName: "compactNavigation"
                visible: shell.compact
                Layout.fillWidth: true
                model: shell.pageNames
                currentIndex: shell.currentIndex
                Accessible.name: "Page"
                onActivated: shell.selectPage(currentIndex)
            }
            Label {
                text: shell.pageNames[shell.currentIndex]
                font.pixelSize: 24
                font.bold: true
                color: "#edf5f8"
            }
            StackLayout {
                id: stack
                objectName: "pageStack"
                currentIndex: 0
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }
    }
}
