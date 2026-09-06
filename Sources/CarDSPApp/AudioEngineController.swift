import AVFoundation
import CarDSPCore
import Combine

@MainActor
final class AudioEngineController: ObservableObject {
    @Published private(set) var isRunning = false
    @Published private(set) var status = "Stopped"

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let mixer = AVAudioMixerNode()

    init() {
        engine.attach(player)
        engine.attach(mixer)
        engine.connect(player, to: mixer, format: nil)
        engine.connect(mixer, to: engine.mainMixerNode, format: nil)
    }

    func start(dsp: RealTimeDSPEngine) {
        do {
            try AudioSessionController.shared.configurePlayback()
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
        status = "Stopped"
    }
}
