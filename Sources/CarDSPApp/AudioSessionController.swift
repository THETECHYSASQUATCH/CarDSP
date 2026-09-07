import AVFAudio

@MainActor
final class AudioSessionController {
    static let shared = AudioSessionController()

    private init() {}

    /// Playback uses the system-selected output route. This intentionally does not
    /// force Bluetooth so iOS can use wired Lightning/USB-C adapters, USB audio
    /// interfaces, headphones, line-out/AUX adapters, AirPlay, or Bluetooth A2DP.
    func configureForPlayback() throws {
#if os(iOS) || os(tvOS) || os(watchOS)
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default, options: [.allowBluetoothA2DP])
        try session.setPreferredSampleRate(48_000)
        try session.setActive(true)
#endif
    }

    /// Measurement keeps input available for the RTA while allowing iOS to choose
    /// the connected output route, including Lightning/USB-C wired audio and Bluetooth.
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

    var currentSampleRateDescription: String {
#if os(iOS) || os(tvOS) || os(watchOS)
        let rate = AVAudioSession.sharedInstance().sampleRate
        if rate >= 1_000 {
            return String(format: "%.1f kHz", rate / 1_000)
        }
        return String(format: "%.0f Hz", rate)
#else
        return "Unavailable"
#endif
    }

    /// Human-readable description for common iPhone audio outputs. Wired routes are
    /// handled by AVAudioSession/iOS and require no private accessory APIs.
    var currentOutputTypeDescription: String {
#if os(iOS) || os(tvOS) || os(watchOS)
        let outputs = AVAudioSession.sharedInstance().currentRoute.outputs
        guard !outputs.isEmpty else { return "No audio output" }

        return outputs.map { output in
            switch output.portType {
            case .headphones:
                return "Wired headphones / Lightning or USB-C to AUX"
            case .usbAudio:
                return "USB audio / USB-C audio interface or adapter"
            case .lineOut:
                return "Wired line out / AUX"
            case .bluetoothA2DP:
                return "Bluetooth high-quality audio (A2DP)"
            case .bluetoothHFP:
                return "Bluetooth hands-free audio"
            case .airPlay:
                return "AirPlay"
            case .builtInSpeaker:
                return "iPhone speaker"
            case .builtInReceiver:
                return "iPhone receiver"
            default:
                return "\(output.portName) (\(output.portType.rawValue))"
            }
        }.joined(separator: ", ")
#else
        return "Audio output unavailable on macOS test host"
#endif
    }
}
