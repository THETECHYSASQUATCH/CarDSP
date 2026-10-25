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

    palette.window: "#101820"
    palette.windowText: "#edf5f8"
    palette.base: "#192530"
    palette.alternateBase: "#243542"
    palette.text: "#edf5f8"
    palette.button: "#243542"
    palette.buttonText: "#edf5f8"
    palette.highlight: "#39d6c1"
    palette.highlightedText: "#101820"
    property int selectedChannel: 0
    property string selectedLayout: "6.1 Active"
    property bool eqEnabled: true
    property bool liveEqGraphInstalled: true

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

    property var bandNames: [
        "Sub-Bass - Infrasonic",
        "Sub-Bass - Deep Rumble",
        "Sub-Bass - Deep Bass",
        "Sub-Bass - Bass Impact",
        "Bass - Subwoofer Punch",
        "Bass - Kick Drum",
        "Bass - Bass Weight",
        "Bass - Upper Bass",
        "Bass - Warmth",
        "Bass - Fullness",
        "Low Mids - Body",
        "Low Mids - Mud",
        "Low Mids - Resonance",
        "Low Mids - Boxiness",
        "Midrange - Instrument Body",
        "Midrange - Vocal Body",
        "Midrange - Vocal Presence",
        "Midrange - Vocal Clarity",
        "Midrange - Definition",
        "Upper Mids - Articulation",
        "Upper Mids - Vocal Detail",
        "Upper Mids - Presence",
        "Upper Mids - Attack",
        "Presence - Detail",
        "Presence - Clarity",
        "Treble - Brightness",
        "Treble - Sibilance",
        "Treble - Sparkle",
        "Treble - Air",
        "High Treble - Brilliance",
        "High Treble - Airiness",
        "High Treble - Extreme Highs"
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

    function refreshBands() {
        eqBands.clear()

        const source = eqController.bands

        for (let i = 0; i < source.length; ++i) {
            eqBands.append({
                name: source[i].name,
                defaultName: source[i].defaultName,
                frequency: source[i].frequency,
                gain: source[i].gain,
                q: source[i].q,
                enabled: source[i].enabled,
                type: source[i].type
            })
        }

        responseGraph.requestPaint()
    }

    Component.onCompleted: {
        eqController.channel = selectedChannel
        refreshBands()
    }

    Connections {
        target: eqController

        function onBandsChanged() {
            window.refreshBands()
        }

        function onResponseChanged() {
            responseGraph.requestPaint()
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
                        onToggled: { window.eqEnabled = checked; responseGraph.requestPaint() }
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

                        onActivated: { window.selectedChannel = currentIndex; eqController.channel = currentIndex }
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

                            const response = eqController.response

                            for (let i = 0; i < response.length; ++i) {
                                const frequency = response[i].frequency
                                const gain = window.eqEnabled
                                           ? response[i].gain : 0.0

                                const x = Math.log(frequency / 20.0)
                                          / Math.log(1000.0) * w

                                const y = h / 2 - (gain / 24.0) * h

                                if (i === 0)
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
                        text: "Frequency Response — Live Parametric EQ"
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
                        id: eqScrollView
                        anchors.fill: parent
                        anchors.margins: 12
                        clip: true

                        GridLayout {
                            width: Math.max(eqScrollView.availableWidth, 4 * 200 + 3 * 12)
                            columns: 4
                            columnSpacing: 12
                            rowSpacing: 12

                            Repeater {
                                model: eqBands

                                delegate: Rectangle {
                                    required property int index

                                    Layout.fillWidth: true
                                    Layout.preferredWidth: 200
                                    Layout.minimumWidth: 180
                                    Layout.preferredHeight: 535
                                    color: "#243542"
                                    radius: 8

                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.margins: 10
                                        spacing: 5

                                        Label {
                                            text: window.bandNames[index]
                                            color: window.accent
                                            font.bold: true
                                        }

                                        RowLayout {
                                            Layout.fillWidth: true

                                            Label {
                                                text: "Enabled"
                                                color: window.foreground
                                            }

                                            Switch {
                                                id: bandEnabledSwitch
                                                checked: eqBands.get(index).enabled

                                                onToggled: {
                                                    const band = eqBands.get(index)
                                                    eqController.setBand(
                                                        index,
                                                        band.frequency,
                                                        band.gain,
                                                        band.q,
                                                        checked
                                                    )
                                                }
                                            }
                                        }

                                        Label {
                                            text: "Frequency (Hz)"
                                            color: window.foreground
                                        }

                                        Label {
                                            text: "Filter Type"
                                            color: window.foreground
                                        }

                                        Label {
                                            text: "Custom Band Name"
                                            color: window.foreground
                                        }

                                        TextField {
                                            id: bandCustomNameInput
                                            Layout.fillWidth: true
                                            maximumLength: 64

                                            text: eqBands.get(index).name
                                            placeholderText: eqBands.get(index).defaultName

                                            function saveName() {
                                                const newName = text.trim()

                                                if (newName !== eqBands.get(index).name) {
                                                    eqController.setBandName(index, newName)
                                                }
                                            }

                                            onAccepted: saveName()
                                            onEditingFinished: saveName()
                                        }

                                        Button {
                                            text: "Reset Name"
                                            Layout.fillWidth: true
                                            onClicked: eqController.resetBandName(index)
                                        }
                                        ComboBox {
                                            id: bandFilterTypeBox
                                            Layout.fillWidth: true

                                            model: [
                                                "Peaking",
                                                "Low Shelf",
                                                "High Shelf",
                                                "Low Pass",
                                                "High Pass",
                                                "Notch"
                                            ]

                                            currentIndex: eqBands.get(index).type

                                            onActivated: {
                                                eqController.setBandType(index, currentIndex)
                                            }
                                        }
                                        TextField {
                                            id: bandFrequencyInput
                                            Layout.fillWidth: true
                                            text: String(eqBands.get(index).frequency)

                                            validator: DoubleValidator {
                                                bottom: 20
                                                top: 20000
                                                decimals: 1
                                            }

                                            onEditingFinished: {
                                                if (!acceptableInput)
                                                    return

                                                const band = eqBands.get(index)

                                                eqController.setBand(
                                                    index,
                                                    Number(text),
                                                    band.gain,
                                                    band.q,
                                                    band.enabled
                                                )
                                            }
                                        }

                                        Label {
                                            text: "Gain: " +
                                                  gainSlider.value.toFixed(1) +
                                                  " dB"
                                            color: window.foreground
                                        }

                                        Slider {
                                            id: gainSlider
                                            Layout.fillWidth: true
                                            from: -18
                                            to: 18
                                            stepSize: 0.5
                                            value: eqBands.get(index).gain

                                            onMoved: {
                                                const band = eqBands.get(index)

                                                eqController.setBand(
                                                    index,
                                                    band.frequency,
                                                    value,
                                                    band.q,
                                                    band.enabled
                                                )
                                            }
                                        }

                                        Label {
                                            text: "Q Factor"
                                            color: window.foreground
                                        }

                                        TextField {
                                            id: bandQInput
                                            Layout.fillWidth: true
                                            text: String(eqBands.get(index).q)

                                            validator: DoubleValidator {
                                                bottom: 0.1
                                                top: 30
                                                decimals: 2
                                            }

                                            onEditingFinished: {
                                                if (!acceptableInput)
                                                    return

                                                const band = eqBands.get(index)

                                                eqController.setBand(
                                                    index,
                                                    band.frequency,
                                                    band.gain,
                                                    Number(text),
                                                    band.enabled
                                                )
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
    }

    Item {
        id: navigation
        property int currentIndex: 1
    }
}
