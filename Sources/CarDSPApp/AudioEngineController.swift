import Foundation
import AVFAudio
import Combine

@MainActor
final class AudioEngineController: ObservableObject {
    static let shared = AudioEngineController()

    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private let mixer = AVAudioMixerNode()

    @Published private(set) var isRunning = false
    @Published private(set) var status = "Idle"
    @Published private(set) var outputRoute = "No output"

    private init() {
        engine.attach(playerNode)
        engine.attach(mixer)
        engine.connect(playerNode, to: mixer, format: nil)
        engine.connect(mixer, to: engine.mainMixerNode, format: nil)

        NotificationCenter.default.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.refreshRoute() }
        }
    }

    func start() throws {
        try AudioSessionController.shared.configureForPlayback()
        refreshRoute()

        if !engine.isRunning {
            try engine.start()
        }
        playerNode.play()
        isRunning = true
        status = "Audio engine running"
    }

    func stop() {
        playerNode.stop()
        engine.stop()
        isRunning = false
        status = "Audio engine stopped"
        AudioSessionController.shared.deactivate()
    }

    func schedule(_ buffer: AVAudioPCMBuffer, completion: (() -> Void)? = nil) {
        playerNode.scheduleBuffer(buffer, completionCallbackType: .dataPlayedBack) { _ in
            completion?()
        }
        if !isRunning { try? start() }
    }

    func refreshRoute() {
        let outputs = AVAudioSession.sharedInstance().currentRoute.outputs
        outputRoute = outputs.map { "\($0.portName) • \($0.portType.rawValue)" }.joined(separator: ", ")
        if outputRoute.isEmpty { outputRoute = "No output" }
    }
}
