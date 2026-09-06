import Foundation
import AVFAudio

@MainActor
public final class AudioEngineController: ObservableObject {
    public static let shared = AudioEngineController()

    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private let mixer = AVAudioMixerNode()

    @Published public private(set) var isRunning = false
    @Published public private(set) var status = "Idle"
    @Published public private(set) var outputRoute = "No output"

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

    public func start() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default, options: [.allowBluetoothA2DP])
        try session.setActive(true)
        refreshRoute()

        if !engine.isRunning {
            try engine.start()
        }
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

    public func schedule(_ buffer: AVAudioPCMBuffer, completion: (() -> Void)? = nil) {
        playerNode.scheduleBuffer(buffer, completionCallbackType: .dataPlayedBack) { _ in
            completion?()
        }
        if !isRunning { try? start() }
    }

    public func refreshRoute() {
        let outputs = AVAudioSession.sharedInstance().currentRoute.outputs
        outputRoute = outputs.map { "\($0.portName) • \($0.portType.rawValue)" }.joined(separator: ", ")
        if outputRoute.isEmpty { outputRoute = "No output" }
    }
}
