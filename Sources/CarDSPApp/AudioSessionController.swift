
import AVFAudio

final class AudioSessionController {
    static let shared = AudioSessionController()

    func configure() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord,
                                mode: .measurement,
                                options: [.allowBluetoothA2DP, .allowBluetoothHFP])
        try session.setPreferredSampleRate(48_000)
        try session.setActive(true)
    }

    var currentRouteDescription: String {
        AVAudioSession.sharedInstance().currentRoute.outputs
            .map { "\($0.portName) (\($0.portType.rawValue))" }
            .joined(separator: ", ")
    }
}
