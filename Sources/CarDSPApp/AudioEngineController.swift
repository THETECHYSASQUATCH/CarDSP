import Foundation
import AVFoundation

@MainActor
public final class AudioEngineController: ObservableObject {
    public static let shared = AudioEngineController()

    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private let mixer = AVAudioMixerNode()
    private let dsp = RealTimeDSPEngine()

    @Published public private(set) var isRunning = false
    @Published public private(set) var status = "Idle"

    private init() {
        engine.attach(playerNode)
        engine.attach(mixer)
        engine.connect(playerNode, to: mixer, format: nil)
        engine.connect(mixer, to: engine.mainMixerNode, format: nil)

        mixer.installTap(onBus: 0, bufferSize: 1024, format: nil) { [weak self] buffer, _ in
            guard let self, let channelData = buffer.floatChannelData else { return }
            let frameCount = Int(buffer.frameLength)
            let left = UnsafeMutablePointer<Float>(mutating: channelData[0])
            let right = UnsafeMutablePointer<Float>(mutating: channelData[1])

            var stereo = UnsafeMutablePointer<Float>.allocate(capacity: frameCount * 2)
            defer { stereo.deallocate() }

            for frame in 0..<frameCount {
                stereo[frame * 2] = left[frame]
                stereo[frame * 2 + 1] = right[frame]
            }

            self.dsp.processInterleavedStereo(stereo, frameCount: frameCount)

            for frame in 0..<frameCount {
                left[frame] = stereo[frame * 2]
                right[frame] = stereo[frame * 2 + 1]
            }
        }
    }

    public func start() throws {
        try AudioSessionController.shared.configure()

        let format = AVAudioFormat(standardFormatWithSampleRate: 48_000, channels: 2)
        engine.inputNode.removeTap(onBus: 0)
        engine.mainMixerNode.outputFormat(forBus: 0)
        try engine.setCategory(.playback, mode: .default, options: [.allowBluetoothA2DP])
        try engine.start()
        playerNode.play()
        isRunning = true
        status = "Audio engine running"
    }

    public func stop() {
        playerNode.stop()
        engine.stop()
        isRunning = false
        status = "Audio engine stopped"
    }
}
