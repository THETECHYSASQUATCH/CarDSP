import AVFAudio

@MainActor
final class AudioSessionController {
    static let shared = AudioSessionController()

    private init() {}

    func configureForPlayback() throws {
#if os(iOS) || os(tvOS) || os(watchOS)
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default, options: [.allowBluetoothA2DP])
        try session.setPreferredSampleRate(48_000)
        try session.setActive(true)
#endif
    }

    func configureForMeasurement() throws {
#if os(iOS) || os(tvOS) || os(watchOS)
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .measurement, options: [.allowBluetoothA2DP, .allowBluetoothHFP])
        try session.setPreferredSampleRate(48_000)
        try session.setActive(true)
#endif
    }

    func deactivate() {
#if os(iOS) || os(tvOS) || os(watchOS)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
#endif
    }

    var currentRouteDescription: String {
#if os(iOS) || os(tvOS) || os(watchOS)
        let outputs = AVAudioSession.sharedInstance().currentRoute.outputs
        return outputs.map { "\($0.portName) (\($0.portType.rawValue))" }.joined(separator: ", ")
#else
        return "Audio route unavailable on macOS test host"
#endif
    }
}
