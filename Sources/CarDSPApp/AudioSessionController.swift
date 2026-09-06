import AVFAudio

@MainActor
final class AudioSessionController {
    static let shared = AudioSessionController()

    private init() {}

    func configureForPlayback() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default, options: [.allowBluetoothA2DP])
        try session.setPreferredSampleRate(48_000)
        try session.setActive(true)
    }

    func configureForMeasurement() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .measurement, options: [.allowBluetoothA2DP, .allowBluetoothHFP])
        try session.setPreferredSampleRate(48_000)
        try session.setActive(true)
    }

    func deactivate() {
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    var currentRouteDescription: String {
        let outputs = AVAudioSession.sharedInstance().currentRoute.outputs
        return outputs.map { "\($0.portName) (\($0.portType.rawValue))" }.joined(separator: ", ")
    }
}
