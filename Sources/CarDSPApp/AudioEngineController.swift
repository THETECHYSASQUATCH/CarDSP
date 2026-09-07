import AVFoundation
import CarDSPCore
import Combine

@MainActor
final class AudioEngineController: ObservableObject {
    @Published private(set) var isRunning = false
    @Published private(set) var status = "Stopped"
    @Published private(set) var peakDBFS: Float = -120
    @Published private(set) var isClipping = false

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let mixer = AVAudioMixerNode()

    init() {
        engine.attach(player)
        engine.attach(mixer)
        engine.connect(player, to: mixer, format: nil)
        engine.connect(mixer, to: engine.mainMixerNode, format: nil)

        mixer.installTap(onBus: 0, bufferSize: 1024, format: nil) { [weak self] buffer, _ in
            guard let channels = buffer.floatChannelData else { return }
            let frameCount = Int(buffer.frameLength)
            let channelCount = Int(buffer.format.channelCount)
            guard frameCount > 0, channelCount > 0 else { return }

            var peak: Float = 0
            for channel in 0..<channelCount {
                let samples = channels[channel]
                for frame in 0..<frameCount {
                    peak = max(peak, abs(samples[frame]))
                }
            }

            let safePeak = max(peak, 0.000001)
            let dbfs = max(-120, 20 * log10f(safePeak))
            let clipping = peak >= 0.999

            Task { @MainActor [weak self] in
                self?.peakDBFS = dbfs
                self?.isClipping = clipping
            }
        }
    }

    func start(dsp: RealTimeDSPEngine) {
        do {
            try AudioSessionController.shared.configureForPlayback()
            let format = engine.outputNode.inputFormat(forBus: 0)
            guard format.sampleRate > 0, format.channelCount > 0 else {
                status = "No valid audio output"
                return
            }
            try engine.start()
            isRunning = true
            status = "DSP engine running (app-owned audio path)"
        } catch {
            isRunning = false
            status = "Audio error: \(error.localizedDescription)"
        }
    }

    func stop() {
        player.stop()
        engine.stop()
        isRunning = false
        peakDBFS = -120
        isClipping = false
        status = "Stopped"
    }
}
