import Foundation
import AVFAudio

@MainActor
final class AudioSessionController {
    static let shared = AudioSessionController()

#if os(iOS) || os(tvOS) || os(watchOS)
    static let routeChangeNotification = AVAudioSession.routeChangeNotification
#elseif os(macOS)
    static let routeChangeNotification = Notification.Name("CarDSP.AudioRouteChange")
#else
    static let routeChangeNotification = Notification.Name("CarDSP.AudioRouteChange")
#endif

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

    func routeChangeReasonDescription(_ notification: Notification) -> String {
#if os(iOS) || os(tvOS) || os(watchOS)
        guard
            let raw = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt,
            let reason = AVAudioSession.RouteChangeReason(rawValue: raw)
        else { return "Audio route changed" }
        switch reason {
        case .newDeviceAvailable: return "New audio device connected"
        case .oldDeviceUnavailable: return "Audio device disconnected"
        case .categoryChange: return "Audio session category changed"
        case .override: return "Audio route overridden"
        case .wakeFromSleep: return "Audio route restored after wake"
        case .noSuitableRouteForCategory: return "No suitable audio route"
        case .routeConfigurationChange: return "Audio route configuration changed"
        case .unknown: return "Audio route changed"
        @unknown default: return "Audio route changed"
        }
#elseif os(macOS)
        return "macOS audio device configuration changed"
#else
        return "Audio route changed"
#endif
    }

    var currentRouteDescription: String {
#if os(iOS) || os(tvOS) || os(watchOS)
        let outputs = AVAudioSession.sharedInstance().currentRoute.outputs
        return outputs.map { "\($0.portName) (\($0.portType.rawValue))" }.joined(separator: ", ")
#elseif os(macOS)
        return "System-selected Core Audio output"
#else
        return "Audio route unavailable"
#endif
    }

    var currentRouteProfileKey: String {
#if os(iOS) || os(tvOS) || os(watchOS)
        let outputs = AVAudioSession.sharedInstance().currentRoute.outputs
        guard !outputs.isEmpty else { return "no-output" }
        return outputs.map { "\($0.portType.rawValue)|\($0.portName)" }.joined(separator: "+")
#elseif os(macOS)
        return "macos-default-output"
#else
        return "unknown-output"
#endif
    }

    var currentRouteProfileName: String {
#if os(iOS) || os(tvOS) || os(watchOS)
        let outputs = AVAudioSession.sharedInstance().currentRoute.outputs
        guard !outputs.isEmpty else { return "No Audio Output" }
        return outputs.map(\.portName).joined(separator: " + ")
#elseif os(macOS)
        return "macOS Default Output"
#else
        return "Audio Output"
#endif
    }

    var currentSampleRateDescription: String {
#if os(iOS) || os(tvOS) || os(watchOS)
        return formatSampleRate(AVAudioSession.sharedInstance().sampleRate)
#elseif os(macOS)
        return "Core Audio managed"
#else
        return "Unavailable"
#endif
    }

    var currentChannelCountDescription: String {
#if os(iOS) || os(tvOS) || os(watchOS)
        let channels = AVAudioSession.sharedInstance().currentRoute.outputs.first?.channels?.count ?? 0
        if channels == 1 { return "Mono" }
        if channels == 2 { return "Stereo" }
        return channels > 0 ? "\(channels) channels" : "Unavailable"
#elseif os(macOS)
        return "Determined by output device"
#else
        return "Unavailable"
#endif
    }

    var currentOutputTypeDescription: String {
#if os(iOS) || os(tvOS) || os(watchOS)
        let outputs = AVAudioSession.sharedInstance().currentRoute.outputs
        guard !outputs.isEmpty else { return "No audio output" }
        return outputs.map { output in
            switch output.portType {
            case .headphones: return "Wired headphones / Lightning or USB-C to AUX"
            case .usbAudio: return "USB audio / USB-C audio interface or adapter"
            case .lineOut: return "Wired line out / AUX"
            case .bluetoothA2DP: return "Bluetooth high-quality audio (A2DP)"
            case .bluetoothHFP: return "Bluetooth hands-free audio"
            case .airPlay: return "AirPlay"
            case .builtInSpeaker: return "iPhone speaker"
            case .builtInReceiver: return "iPhone receiver"
            default: return "\(output.portName) (\(output.portType.rawValue))"
            }
        }.joined(separator: ", ")
#elseif os(macOS)
        return "macOS Core Audio output"
#else
        return "Audio output unavailable"
#endif
    }

    private func formatSampleRate(_ rate: Double) -> String {
        if rate >= 1_000 { return String(format: "%.1f kHz", rate / 1_000) }
        return String(format: "%.0f Hz", rate)
    }
}
