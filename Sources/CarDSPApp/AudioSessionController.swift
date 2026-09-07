import Foundation
import AVFAudio

@MainActor
final class AudioSessionController {
    static let shared = AudioSessionController()

#if os(iOS) || os(tvOS) || os(watchOS)
    static let routeChangeNotification = AVAudioSession.routeChangeNotification
#else
    static let routeChangeNotification = Notification.Name("CarDSP.AudioRouteChange")
#endif

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
#else
        return "Audio route changed"
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

    /// Stable-enough local key for remembering a DSP profile for the currently
    /// selected output. It is never transmitted and contains only the route names/types
    /// reported to this app by AVAudioSession.
    var currentRouteProfileKey: String {
#if os(iOS) || os(tvOS) || os(watchOS)
        let outputs = AVAudioSession.sharedInstance().currentRoute.outputs
        guard !outputs.isEmpty else { return "no-output" }
        return outputs.map { "\($0.portType.rawValue)|\($0.portName)" }.joined(separator: "+")
#else
        return "macOS-test-host"
#endif
    }

    var currentRouteProfileName: String {
#if os(iOS) || os(tvOS) || os(watchOS)
        let outputs = AVAudioSession.sharedInstance().currentRoute.outputs
        guard !outputs.isEmpty else { return "No Audio Output" }
        return outputs.map(\.portName).joined(separator: " + ")
#else
        return "macOS Test Host"
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

    var currentChannelCountDescription: String {
#if os(iOS) || os(tvOS) || os(watchOS)
        let channels = AVAudioSession.sharedInstance().currentRoute.outputs.first?.channels?.count ?? 0
        if channels == 1 { return "Mono" }
        if channels == 2 { return "Stereo" }
        return channels > 0 ? "\(channels) channels" : "Unavailable"
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
