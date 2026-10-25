import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: window

    width: 1280
    height: 800
    minimumWidth: 950
    minimumHeight: 650

    visible: true
    title: "CarDSP — Professional Audio Processor"

    color: "#101820"

    property int selectedChannel: 0
    property string selectedLayout: "6.1 Active"
    property bool eqEnabled: true

    readonly property color accent: "#39d6c1"
    readonly property color panel: "#192530"
    readonly property color foreground: "#edf5f8"

    property var channels: [
        "Front Left Tweeter",
        "Front Right Tweeter",
        "Front Left Woofer",
        "Front Right Woofer",
        "Rear Left Door",
        "Rear Right Door",
        "Mono Subwoofer"
    ]

    property var bandFrequencies: [
        20, 25, 31.5, 40, 50, 63, 80, 100,
        125, 160, 200, 250, 315, 400, 500, 630,
        800, 1000, 1250, 1600, 2000, 2500, 3150, 4000,
        5000, 6300, 8000, 10000, 12500, 14000, 16000, 20000
    ]

    ListModel {
        id: eqBands
    }

    Component.onCompleted: {
        for (let i = 0; i < 32; ++i) {
            eqBands.append({
                frequency: bandFrequencies[i],
                gain: 0.0,
                q: 1.41,
                enabled: true
            })
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.preferredWidth: 230
            Layout.fillHeight: true
            color: "#131e27"

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 22
                spacing: 14

                Label {
                    text: "CarDSP"
                    font.pixelSize: 30
                    font.bold: true
                    color: window.accent
                }

                Label {
                    text: "PRO AUDIO PROCESSOR"
                    font.pixelSize: 11
                    color: "#8ca2b3"
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: "#34424e"
                }

                Repeater {
                    model: [
                        "Dashboard",
                        "32-Band Equalizer",
                        "Channel Routing",
                        "Crossovers",
                        "Time Alignment",
                        "Presets",
                        "Settings"
                    ]

                    delegate: Button {
                        required property string modelData
                        required property int index

                        Layout.fillWidth: true
                        text: modelData
                        highlighted: navigation.currentIndex === index

                        onClicked: navigation.currentIndex = index
                    }
                }

                Item {
                    Layout.fillHeight: true
                }

                Label {
                    text: "CarDSP v0.1 UI Preview"
                    color: "#8ca2b3"
                    font.pixelSize: 11
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 25
                spacing: 16

                RowLayout {
                    Layout.fillWidth: true

                    Label {
                        text: navigation.currentIndex === 1
                              ? "32-Band Parametric Equalizer"
                              : navigation.currentIndex === 2
                                ? "Channel Routing"
                                : "CarDSP Dashboard"

                        font.pixelSize: 25
                        font.bold: true
                        color: window.foreground
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Switch {
                        text: "EQ Enabled"
                        checked: window.eqEnabled
                        onToggled: window.eqEnabled = checked
                    }
                }

                RowLayout {
                    Layout.fillWidth: true

                    Label {
                        text: "Speaker Layout"
                        color: window.foreground
                    }

                    ComboBox {
                        id: layoutBox

                        model: [
                            "5.1", "5.2",
                            "6.1", "6.2",
                            "7.1", "7.2",
                            "6.1 Active"
                        ]

                        currentIndex: 6

                        onActivated: {
                            window.selectedLayout = currentText
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Label {
                        text: "Channel"
                        color: window.foreground
                    }

                    ComboBox {
                        id: channelBox
                        Layout.preferredWidth: 230

                        model: window.channels

                        onActivated: window.selectedChannel = currentIndex
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 260

                    radius: 12
                    color: window.panel

                    Canvas {
                        id: responseGraph
                        anchors.fill: parent
                        anchors.margins: 20

                        onPaint: {
                            const ctx = getContext("2d")
                            ctx.reset()

                            const w = width
                            const h = height

                            ctx.strokeStyle = "#354755"
                            ctx.lineWidth = 1

                            for (let i = 0; i <= 8; i++) {
                                let x = i * w / 8
                                ctx.beginPath()
                                ctx.moveTo(x, 0)
                                ctx.lineTo(x, h)
                                ctx.stroke()
                            }

                            for (let i = 0; i <= 6; i++) {
                                let y = i * h / 6
                                ctx.beginPath()
                                ctx.moveTo(0, y)
                                ctx.lineTo(w, y)
                                ctx.stroke()
                            }

                            ctx.strokeStyle = window.accent
                            ctx.lineWidth = 3
                            ctx.beginPath()

                            for (let x = 0; x <= w; x++) {
                                let y = h / 2

                                // Flat reference response until
                                // the actual DSP response is connected.
                                if (x === 0)
                                    ctx.moveTo(x, y)
                                else
                                    ctx.lineTo(x, y)
                            }

                            ctx.stroke()
                        }
                    }

                    Label {
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.margins: 12
                        text: "Frequency Response — Flat Reference"
                        color: "#9cb2bf"
                    }
                }

                Label {
                    text: "32 PARAMETRIC EQ BANDS — " +
                          window.channels[window.selectedChannel]

                    color: window.accent
                    font.bold: true
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 12
                    color: window.panel

                    ScrollView {
                        anchors.fill: parent
                        anchors.margins: 12
                        clip: true

                        GridLayout {
                            width: parent.width
                            columns: 4
                            columnSpacing: 12
                            rowSpacing: 12

                            Repeater {
                                model: eqBands

                                delegate: Rectangle {
                                    required property int index

                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 155
                                    color: "#243542"
                                    radius: 8

                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.margins: 10
                                        spacing: 5

                                        Label {
                                            text: "Band " + (index + 1)
                                            color: window.accent
                                            font.bold: true
                                        }

                                        Label {
                                            text: eqBands.get(index).frequency + " Hz"
                                            color: window.foreground
                                        }

                                        Slider {
                                            id: gainSlider
                                            Layout.fillWidth: true

                                            from: -12
                                            to: 12
                                            stepSize: 0.5
                                            value: eqBands.get(index).gain

                                            onMoved: {
                                                eqBands.setProperty(
                                                    index, "gain", value
                                                )
                                            }
                                        }

                                        Label {
                                            text: "Gain: " +
                                                  gainSlider.value.toFixed(1) +
                                                  " dB"
                                            color: window.foreground
                                        }

                                        Label {
                                            text: "Q: 1.41"
                                            color: "#a7bac6"
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Item {
        id: navigation
        property int currentIndex: 1
    }
}