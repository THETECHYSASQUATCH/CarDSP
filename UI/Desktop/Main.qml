import QtQuick.Dialogs
import CarDSP
import QtQuick.Window
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    // Phase 4D - Native audio file picker
    FileDialog {
        id: pcmFileDialog
        title: "Select Audio File"
        fileMode: FileDialog.OpenFile
        nameFilters: ["Audio (*.wav *.mp3 *.flac *.pcm *.raw)", "WAV (*.wav)", "MP3 (*.mp3)", "FLAC (*.flac)", "Raw PCM (*.pcm *.raw)"]
        onAccepted: {
            window.selectedPcmFile = audioPlaybackEngine.localFilePath(selectedFile)
        }
    }

    function configurePlaybackEq() {
        if (!audioPlaybackEngine) {
            console.error("CarDSP: Audio playback engine unavailable")
            return false
        }

        const bands = []

        for (let i = 0; i < eqBands.count; ++i) {
            const band = eqBands.get(i)

            bands.push({
                enabled: band.enabled,
                frequency: band.frequency,
                gain: band.gain,
                q: band.q,
                type: band.type
            })
        }

        const success = audioPlaybackEngine.configureEq(bands)

        console.log("CarDSP: EQ configuration:", success,
                    "Bands:", bands.length)

        if (!success) {
            console.error("CarDSP:", audioPlaybackEngine.lastError)
        }

        return success
    }
    function formatTime(milliseconds) {
        const seconds = Math.floor(milliseconds / 1000)
        return Math.floor(seconds / 60) + ":" + (seconds % 60).toString().padStart(2, "0")
    }
    // Audio playback controls
    property string selectedPcmFile: ""

    header: Rectangle {
        id: playbackToolbar
        objectName: "playbackToolbar"
        height: 154
        color: "#172631"

        ScrollView {
            id: playbackScroll
            anchors.fill: parent
            clip: true
            contentWidth: Math.max(availableWidth, 1120)
            contentHeight: availableHeight
            ScrollBar.vertical.policy: ScrollBar.AlwaysOff

        ColumnLayout {
            x: 10
            y: 6
            width: playbackScroll.contentWidth - 20
            height: playbackScroll.availableHeight - 20
            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Label { text: "Audio Playback"; color: "white"; font.bold: true }

                TextField {
                    id: pcmPath
                    Layout.fillWidth: true
                    placeholderText: "WAV, MP3, FLAC, or 48 kHz stereo Float32 PCM"
                    text: window.selectedPcmFile
                    onEditingFinished: window.selectedPcmFile = text
                }

                Button {
                    text: "Browse..."
                    onClicked: pcmFileDialog.open()
                }

                ComboBox {
                    id: outputSelector
                    Layout.preferredWidth: 200
                    model: audioPlaybackEngine ? audioPlaybackEngine.outputDevices : []
                    textRole: "name"
                    enabled: audioPlaybackEngine && !audioPlaybackEngine.playing && !audioPlaybackEngine.loading
                }

                Button {
                    text: "Play"
                    enabled: audioPlaybackEngine && !audioPlaybackEngine.playing && !audioPlaybackEngine.loading
                             && window.selectedPcmFile.length > 0
                    onClicked: {
                        if (window.configurePlaybackEq()) {
                            console.log("CarDSP: Starting playback:",
                                        window.selectedPcmFile)

                            const started = audioPlaybackEngine.playFile(
                                window.selectedPcmFile,
                                outputSelector.currentIndex
                            )

                            console.log("CarDSP: Playback started:", started)

                            if (!started) {
                                console.error("CarDSP playback error:",
                                              audioPlaybackEngine.lastError)
                            }
                        }
                    }
                }

                Button {
                    text: audioPlaybackEngine && audioPlaybackEngine.paused ? "Resume" : "Pause"
                    enabled: audioPlaybackEngine && audioPlaybackEngine.playing
                    onClicked: {
                        if (audioPlaybackEngine.paused) audioPlaybackEngine.resume()
                        else audioPlaybackEngine.pause()
                    }
                }
                Button {
                    text: "Stop"
                    enabled: audioPlaybackEngine && (audioPlaybackEngine.playing || audioPlaybackEngine.loading)
                    onClicked: audioPlaybackEngine.stop()
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Label {
                    text: audioPlaybackEngine && audioPlaybackEngine.loading ? "Preparing audio…" : window.formatTime(audioPlaybackEngine ? audioPlaybackEngine.position : 0)
                    color: "white"
                }
                Slider {
                    id: playbackPosition
                    Layout.fillWidth: true
                    from: 0
                    to: Math.max(1, audioPlaybackEngine ? audioPlaybackEngine.duration : 0)
                    enabled: audioPlaybackEngine ? audioPlaybackEngine.playing : false
                    Binding { target: playbackPosition; property: "value"; value: audioPlaybackEngine ? audioPlaybackEngine.position : 0; when: !playbackPosition.pressed }
                    onPressedChanged: { if (!pressed && enabled) audioPlaybackEngine.seek(Math.round(value)) }
                    Keys.onReleased: function(event) {
                        if (event.key === Qt.Key_Left || event.key === Qt.Key_Right) audioPlaybackEngine.seek(Math.round(value))
                    }
                }
                EditableValue {
                    Layout.preferredWidth: 110
                    parameterName: "Playback position"
                    unit: "s"
                    minimumValue: 0
                    maximumValue: audioPlaybackEngine ? audioPlaybackEngine.duration / 1000 : 0
                    decimals: 3
                    value: audioPlaybackEngine ? audioPlaybackEngine.position / 1000 : 0
                    enabled: audioPlaybackEngine ? audioPlaybackEngine.playing : false
                    onValueCommitted: function(newValue) {
                        audioPlaybackEngine.seek(Math.round(newValue * 1000))
                    }
                }
                Label { text: window.formatTime(audioPlaybackEngine ? audioPlaybackEngine.duration : 0); color: "white" }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Label { text: "Volume"; color: "white" }
                Slider {
                    id: volumeSlider
                    Layout.preferredWidth: 180
                    from: 0
                    to: 1
                    value: audioPlaybackEngine ? audioPlaybackEngine.volume : 0.25
                    onMoved: audioPlaybackEngine.volume = value
                }

                EditableValue {
                    Layout.preferredWidth: 90
                    parameterName: "Master volume"
                    unit: "%"
                    decimals: 1
                    minimumValue: volumeSlider.from * 100
                    maximumValue: volumeSlider.to * 100
                    value: (audioPlaybackEngine ? audioPlaybackEngine.volume : 0.25) * 100
                    onValueCommitted: function(newValue) {
                        if (audioPlaybackEngine) audioPlaybackEngine.volume = newValue / 100
                    }
                }

                CheckBox {
                    text: "Bypass EQ"
                    checked: audioPlaybackEngine ? audioPlaybackEngine.bypass : false
                    onToggled: audioPlaybackEngine.bypass = checked
                }

                Button {
                    text: "Refresh Outputs"
                    onClicked: audioPlaybackEngine.refreshOutputDevices()
                }

                Label {
                    Layout.fillWidth: true
                    color: "#ff8888"
                    elide: Text.ElideRight
                    text: audioPlaybackEngine ? audioPlaybackEngine.lastError : ""
                }
            }
        }
        }
    }

    // Phase 3A.3 - Microphone capture controls
    footer: Rectangle {
        id: microphonePanel
        objectName: "microphonePanel"

        height: 92
        color: "#131e27"

        ScrollView {
            id: microphoneScroll
            anchors.fill: parent
            clip: true
            contentWidth: Math.max(availableWidth, 850)
            contentHeight: availableHeight
            ScrollBar.vertical.policy: ScrollBar.AlwaysOff

        RowLayout {
            x: 12
            y: 6
            width: microphoneScroll.contentWidth - 24
            height: microphoneScroll.availableHeight - 20
            spacing: 12

            Label {
                text: "Microphone"
                color: "white"
                font.bold: true
            }

            ComboBox {
                id: microphoneSelector

                Layout.preferredWidth: 270

                model: microphoneManager ? microphoneManager.devices : []
                textRole: "name"

                enabled: microphoneManager ? !microphoneManager.capturing : false

                onActivated: function(index) {
                    microphoneManager.stopCapture()
                }
            }

            Button {
                text: "Refresh"

                enabled: microphoneManager ? !microphoneManager.capturing : false

                onClicked: microphoneManager.refreshDevices()
            }

            Button {
                text: "Start"

                enabled: microphoneManager ? !microphoneManager.capturing : false
                         && microphoneSelector.currentIndex >= 0

                onClicked: {
                    microphoneManager.startCapture(
                        microphoneSelector.currentIndex
                    )
                }
            }

            Button {
                text: "Stop"

                enabled: microphoneManager ? microphoneManager.capturing : false

                onClicked: microphoneManager.stopCapture()
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Label {
                    text: "Input Level"
                    color: "white"
                }

                ProgressBar {
                    Layout.fillWidth: true
                    from: 0
                    to: 1
                    value: microphoneManager ? microphoneManager.level : 0
                }

                Label {
                    text: (microphoneManager && microphoneManager.lastError.length > 0)
                          ? microphoneManager.lastError
                          : (microphoneManager && microphoneManager.capturing)
                            ? "Recording input..."
                            : "Stopped"

                    color: (microphoneManager && microphoneManager.lastError.length > 0)
                           ? "#ff7777"
                           : "#aabbcc"
                }
            }
        }
        }
    }

    id: window

    width: 1100
    height: 600
    minimumWidth: 640
    minimumHeight: 480

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
    property bool eqEnabled: audioPlaybackEngine ? !audioPlaybackEngine.bypass : true
    property bool liveEqGraphInstalled: true
    property string graphMode: "eq"

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
        objectName: "eqBandsModel"
    }

    function refreshBands() {
        const source = eqController.bands

        if (!source)
            return

        for (let i = 0; i < source.length; ++i) {
            const band = {
                name: source[i].name,
                defaultName: source[i].defaultName,
                frequency: source[i].frequency,
                gain: source[i].gain,
                q: source[i].q,
                enabled: source[i].enabled,
                type: source[i].type
            }

            if (i < eqBands.count) {
                eqBands.set(i, band)
            } else {
                eqBands.append(band)
            }
        }

        while (eqBands.count > source.length) {
            eqBands.remove(eqBands.count - 1)
        }

        responseGraph.requestPaint()
    }
    Component.onCompleted: {
        console.log("CarDSP QML controller diagnostics:")
        console.log("eqController:", eqController)
        console.log("microphoneManager:", microphoneManager)
        console.log("spectrumAnalyzer:", spectrumAnalyzer)
        console.log("audioPlaybackEngine:", audioPlaybackEngine)

        if (eqController) {
            eqController.channel = selectedChannel
            refreshBands()
        }
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

    PageShell {
        id: navigation
        objectName: "navigationShell"
        anchors.fill: parent
        anchors.margins: 12

        ColumnLayout {
            objectName: "dashboardPage"
            Label { text: "Your audio workspace"; font.pixelSize: 22; color: window.accent }
            Label {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                color: window.foreground
                text: audioPlaybackEngine && audioPlaybackEngine.loading ? "Preparing audio"
                      : audioPlaybackEngine && audioPlaybackEngine.playing
                        ? (audioPlaybackEngine.paused ? "Playback paused" : "Playback active")
                        : "Ready to open a local audio file"
            }
            Label { text: eqBands.count + " EQ bands · Stereo playback"; color: window.foreground }
            Label {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                text: "Playback controls stay above every page. Microphone capture stays below. Multichannel routing, crossovers and time alignment are previews."
                color: "#9cb2bf"
            }
            Button { text: "Open equalizer"; onClicked: navigation.selectPage(1) }
            Button { text: "View response and spectrum"; onClicked: navigation.selectPage(2) }
            Item { Layout.fillHeight: true }
        }

        ColumnLayout {
            objectName: "equalizerPage"
            RowLayout {
                Layout.fillWidth: true
                Label { text: "EQ channel"; color: window.foreground }
                ComboBox {
                    id: channelBox
                    Layout.fillWidth: true
                    model: window.channels
                    onActivated: { window.selectedChannel = currentIndex; eqController.channel = currentIndex }
                }
                Switch {
                    text: "EQ"
                    checked: window.eqEnabled
                    onToggled: { audioPlaybackEngine.bypass = !checked; responseGraph.requestPaint() }
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

                        contentWidth: eqGrid.implicitWidth
                        contentHeight: Math.max(availableHeight, eqGrid.implicitHeight)

                        ScrollBar.vertical.policy: ScrollBar.AsNeeded
                        ScrollBar.horizontal.policy: ScrollBar.AlwaysOn

                        RowLayout {
                            id: eqGrid
                            spacing: 12

                            Repeater {
                                model: eqBands

                                delegate: Rectangle {
                                    required property int index

                                    Layout.fillWidth: false
                                    Layout.preferredWidth: 190
                                    Layout.minimumWidth: 190
                                    Layout.maximumWidth: 190
                                    Layout.preferredHeight: 535
                                    color: "#243542"
                                    radius: 8

                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.margins: 10
                                        spacing: 5

                                        Label {
                                            text: index < window.bandNames.length ? window.bandNames[index] : "Band " + (index + 1)
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
                                        EditableValue {
                                            id: bandFrequencyInput
                                            Layout.fillWidth: true
                                            parameterName: "Frequency"
                                            unit: "Hz"
                                            minimumValue: 20
                                            maximumValue: 20000
                                            decimals: 1
                                            value: eqBands.get(index).frequency
                                            onValueCommitted: function(newValue) {
                                                const band = eqBands.get(index)
                                                eqController.setBand(index, newValue, band.gain, band.q, band.enabled)
                                            }
                                        }

                                        EditableValue {
                                            Layout.fillWidth: true
                                            parameterName: "Gain"
                                            unit: "dB"
                                            minimumValue: gainSlider.from
                                            maximumValue: gainSlider.to
                                            stepSize: gainSlider.stepSize
                                            decimals: 1
                                            value: eqBands.get(index).gain
                                            onValueCommitted: function(newValue) {
                                                const band = eqBands.get(index)
                                                eqController.setBand(index, band.frequency, newValue, band.q, band.enabled)
                                            }
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

                                        EditableValue {
                                            id: bandQInput
                                            Layout.fillWidth: true
                                            parameterName: "Bandwidth Q factor"
                                            unit: "Q"
                                            minimumValue: 0.1
                                            maximumValue: 30
                                            decimals: 2
                                            value: eqBands.get(index).q
                                            onValueCommitted: function(newValue) {
                                                const band = eqBands.get(index)
                                                eqController.setBand(index, band.frequency, band.gain, newValue, band.enabled)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

        }

        ColumnLayout {
            objectName: "spectrumPage"
                RowLayout {
                    Layout.fillWidth: true

                    Button {
                        text: "EQ Response"
                        checkable: true
                        checked: window.graphMode === "eq"
                        onClicked: window.graphMode = "eq"
                    }

                    Button {
                        text: "Live Spectrum"
                        checkable: true
                        checked: window.graphMode === "spectrum"
                        onClicked: window.graphMode = "spectrum"
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Label {
                        text: (microphoneManager && microphoneManager.capturing) ? "MIC LIVE" : "MIC STOPPED"
                        color: (microphoneManager && microphoneManager.capturing) ? window.accent : "#9cb2bf"
                    }
                }
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 260
                    Layout.fillHeight: true

                    radius: 12
                    color: window.panel

                    Canvas {
                        id: responseGraph
                        visible: window.graphMode === "eq"
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
                        visible: window.graphMode === "eq"
                        text: "Frequency Response — Live Parametric EQ"
                        color: "#9cb2bf"
                    }

                    SpectrumView {
                        id: spectrumGraphView
                        anchors.fill: parent
                        anchors.margins: 10
                        visible: window.graphMode === "spectrum"
                        spectrumData: spectrumAnalyzer ? spectrumAnalyzer.bands : []
                    }
                }


        }

        ColumnLayout {
                Label { text: "Channel Routing preview"; color: window.accent; font.pixelSize: 20 }
                Label { Layout.fillWidth: true; wrapMode: Text.WordWrap; text: "Current playback is stereo. Channel labels select stored EQ settings; they do not route physical outputs. Mono, stereo, 2.1, 3.1, 4.2 and 4.4 routing remain unimplemented. The 4.2 and 4.4 speaker/subwoofer mappings need confirmation before routing is built."; color: window.foreground }
                Item { Layout.fillHeight: true }
            }
        ColumnLayout {
                Label { text: "Crossovers preview"; color: window.accent; font.pixelSize: 20 }
                Label { Layout.fillWidth: true; wrapMode: Text.WordWrap; text: "Dedicated crossover routing is not implemented. The equalizer page retains its existing low-pass and high-pass band filters."; color: window.foreground }
                Item { Layout.fillHeight: true }
            }
        ColumnLayout {
                Label { text: "Time Alignment preview"; color: window.accent; font.pixelSize: 20 }
                Label { Layout.fillWidth: true; wrapMode: Text.WordWrap; text: "Per-output delay and speaker alignment are not implemented."; color: window.foreground }
                Item { Layout.fillHeight: true }
            }

        ColumnLayout {
            objectName: "presetsPage"
                // CarDSP preset management
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 112
                    radius: 10
                    color: "#1b2a36"

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true

                            Label {
                                text: "DSP Presets"
                                font.bold: true
                                color: window.foreground
                            }

                            ComboBox {
                                id: presetSelector
                                Layout.preferredWidth: 240
                                model: presetManager ? presetManager.presets : []
                            }

                            TextField {
                                id: presetName
                                Layout.fillWidth: true
                                placeholderText: "Preset name"
                                maximumLength: 64
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true

                            Button {
                                text: "Save"
                                onClicked: {
                                    const name = presetName.text.trim()
                                    if (!name) return

                                    if (eqController.saveSettings()) {
                                        presetManager.savePreset(
                                            name,
                                            eqController.settingsFilePath()
                                        )
                                    }
                                }
                            }

                            Button {
                                text: "Load"
                                enabled: presetSelector.currentIndex >= 0
                                onClicked: {
                                    eqController.activatePreset(
                                        presetSelector.currentText,
                                        presetManager
                                    )
                                }
                            }

                            Button {
                                text: "Duplicate"
                                enabled: presetSelector.currentIndex >= 0
                                onClicked: {
                                    presetManager.duplicatePreset(
                                        presetSelector.currentText,
                                        presetName.text.trim()
                                    )
                                }
                            }

                            Button {
                                text: "Rename"
                                enabled: presetSelector.currentIndex >= 0
                                onClicked: {
                                    presetManager.renamePreset(
                                        presetSelector.currentText,
                                        presetName.text.trim()
                                    )
                                }
                            }

                            Button {
                                text: "Delete"
                                enabled: presetSelector.currentIndex >= 0
                                onClicked: {
                                    presetManager.deletePreset(
                                        presetSelector.currentText
                                    )
                                }
                            }

                            Item {
                                Layout.fillWidth: true
                            }

                            Button {
                                text: "Refresh"
                                onClicked: presetManager.refresh()
                            }
                        }
                    }
                }

            Item { Layout.fillHeight: true }
        }

        ColumnLayout {
                Label { text: "Settings"; color: window.accent; font.pixelSize: 20 }
                Label { Layout.fillWidth: true; wrapMode: Text.WordWrap; text: "Choose playback outputs, volume and bypass in the persistent playback toolbar. Device capture controls remain in the microphone toolbar. Raw PCM input must be 48 kHz stereo Float32."; color: window.foreground }
                Item { Layout.fillHeight: true }
            }
    }
}
