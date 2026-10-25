import AVFoundation
import CarDSPCore
import Combine

@MainActor
final class AudioEngineController: ObservableObject {
    @Published private(set) var isRunning = false
    @Published private(set) var status = "Choose a local audio file to use DSP"
    @Published private(set) var peakDBFS: Float = -120
    @Published private(set) var isClipping = false
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private var file: AVAudioFile?
    private var dsp: RealTimeDSPEngine?
    private var streamFormat: AVAudioFormat?
    private var scopedURL: URL?
    private var generation = UUID()
    private var queuedBuffers = 0
    private var reachedEnd = false

    init() { engine.attach(player) }

    // Small buffers are decoded and processed on the control thread, never in
    // a render callback. Three queued buffers bound memory and tuning latency.
    func load(url: URL, dsp: RealTimeDSPEngine) {
        stop()
        file = nil
        scopedURL?.stopAccessingSecurityScopedResource()
        scopedURL = url.startAccessingSecurityScopedResource() ? url : nil
        do {
            let source = try AVAudioFile(forReading: url, commonFormat: .pcmFormatFloat32, interleaved: false)
            guard source.length > 0, (1...2).contains(source.processingFormat.channelCount),
                  dsp.prepare(sampleRate: Float(source.processingFormat.sampleRate)),
                  let format = AVAudioFormat(standardFormatWithSampleRate: source.processingFormat.sampleRate, channels: 2)
            else {
                scopedURL?.stopAccessingSecurityScopedResource(); scopedURL = nil
                status = "Choose a nonempty mono or stereo file at 8–384 kHz"
                return
            }
            file = source
            self.dsp = dsp
            streamFormat = format
            engine.disconnectNodeOutput(player)
            engine.connect(player, to: engine.mainMixerNode, format: format)
            status = "Ready: \(url.lastPathComponent)"
        } catch {
            scopedURL?.stopAccessingSecurityScopedResource(); scopedURL = nil
            status = "Cannot open audio: \(error.localizedDescription)"
        }
    }

    func start(dsp: RealTimeDSPEngine) {
        guard !isRunning else { return }
        guard let file else { status = "Choose a local audio file first. Apple Music streams cannot be imported for DSP."; return }
        do {
            try AudioSessionController.shared.configureForPlayback()
            guard dsp.prepare(sampleRate: Float(file.processingFormat.sampleRate)) else { return }
            self.dsp = dsp
            file.framePosition = 0
            reachedEnd = false
            queuedBuffers = 0
            generation = UUID()
            isRunning = true
            for _ in 0..<3 { try enqueueBuffer() }
            try engine.start()
            player.play()
            status = "Playing local audio through DSP"
        } catch {
            stop()
            status = "Audio error: \(error.localizedDescription)"
        }
    }

    private func enqueueBuffer() throws {
        guard !reachedEnd, let file, let dsp, let streamFormat else { return }
        guard let input = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: 4096),
              let output = AVAudioPCMBuffer(pcmFormat: streamFormat, frameCapacity: 4096) else {
            throw CocoaError(.fileReadUnknown)
        }
        try file.read(into: input, frameCount: 4096)
        guard input.frameLength > 0 else { reachedEnd = true; return }
        output.frameLength = input.frameLength
        guard let src = input.floatChannelData, let dst = output.floatChannelData else {
            throw CocoaError(.fileReadCorruptFile)
        }
        let count = Int(input.frameLength)
        dst[0].update(from: src[0], count: count)
        dst[1].update(from: src[file.processingFormat.channelCount == 1 ? 0 : 1], count: count)
        dsp.processNonInterleavedStereo(dst[0], dst[1], frameCount: count)
        var peak: Float = 0
        for i in 0..<count { peak = max(peak, max(abs(dst[0][i]), abs(dst[1][i]))) }
        // This is the latest queued processed buffer's peak, not a DAC meter.
        peakDBFS = max(-120, 20 * log10f(max(peak, 0.000001)))
        isClipping = peak >= 0.999
        queuedBuffers += 1
        let token = generation
        player.scheduleBuffer(output, completionCallbackType: .dataPlayedBack) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, self.generation == token, self.isRunning else { return }
                self.queuedBuffers -= 1
                do {
                    try self.enqueueBuffer()
                    if self.reachedEnd && self.queuedBuffers == 0 {
                        self.stop()
                        self.status = "Playback finished"
                    }
                } catch {
                    self.stop()
                    self.status = "Playback error: \(error.localizedDescription)"
                }
            }
        }
    }

    func stop() {
        generation = UUID()
        player.stop()
        engine.stop()
        isRunning = false
        queuedBuffers = 0
        peakDBFS = -120
        isClipping = false
        status = "Stopped"
    }

    func routeChanged() {
        if isRunning {
            stop()
            status = "Audio route changed. Press Start to restart playback."
        }
    }
}
