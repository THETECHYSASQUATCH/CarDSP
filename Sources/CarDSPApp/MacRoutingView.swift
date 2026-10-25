#if os(macOS)
import SwiftUI
import AVFoundation
import AudioToolbox
import CoreAudio
import CarDSPCore
import Combine

struct RoutingDevice: Identifiable {
    let id: AudioDeviceID
    let name: String
    let isVirtual: Bool
    let hasInput: Bool
    let hasOutput: Bool
}

@MainActor
final class MacRoutingController: ObservableObject {
    @Published var devices: [RoutingDevice] = []
    @Published var inputID: AudioDeviceID = 0
    @Published var outputID: AudioDeviceID = 0
    @Published private(set) var running = false
    @Published private(set) var status = "Select a virtual input and a physical output"
    private var engine: AVAudioEngine?
    private var startToken = UUID()

    func refresh() {
        guard !running else { return }
        var address = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)
        var size: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size) == noErr else { return }
        var ids = [AudioDeviceID](repeating: 0, count: Int(size) / MemoryLayout<AudioDeviceID>.size)
        let result = ids.withUnsafeMutableBytes {
            AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, $0.baseAddress!)
        }
        guard result == noErr else { return }
        devices = ids.map { id in
            var name: CFString = "Audio device" as CFString
            var nameSize = UInt32(MemoryLayout<CFString>.size)
            var nameAddress = AudioObjectPropertyAddress(mSelector: kAudioObjectPropertyName,
                mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)
            _ = AudioObjectGetPropertyData(id, &nameAddress, 0, nil, &nameSize, &name)
            var transport: UInt32 = 0
            var transportSize = UInt32(MemoryLayout<UInt32>.size)
            var transportAddress = AudioObjectPropertyAddress(mSelector: kAudioDevicePropertyTransportType,
                mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)
            _ = AudioObjectGetPropertyData(id, &transportAddress, 0, nil, &transportSize, &transport)
            return RoutingDevice(id: id, name: name as String,
                isVirtual: transport == kAudioDeviceTransportTypeVirtual,
                hasInput: hasStreams(id, scope: kAudioDevicePropertyScopeInput),
                hasOutput: transport != kAudioDeviceTransportTypeAggregate && hasStreams(id, scope: kAudioDevicePropertyScopeOutput))
        }
        if !devices.contains(where: { $0.id == inputID && $0.isVirtual && $0.hasInput }) { inputID = 0 }
        if !devices.contains(where: { $0.id == outputID && !$0.isVirtual && $0.hasOutput }) { outputID = 0 }
    }

    private func hasStreams(_ id: AudioDeviceID, scope: AudioObjectPropertyScope) -> Bool {
        var address = AudioObjectPropertyAddress(mSelector: kAudioDevicePropertyStreams,
            mScope: scope, mElement: kAudioObjectPropertyElementMain)
        var size: UInt32 = 0
        return AudioObjectGetPropertyDataSize(id, &address, 0, nil, &size) == noErr && size > 0
    }

    func start(configuration: DSPConfiguration) async {
        guard !running else { return }
        let token = UUID()
        startToken = token
        guard devices.contains(where: { $0.id == inputID && $0.isVirtual && $0.hasInput }),
              devices.contains(where: { $0.id == outputID && !$0.isVirtual && $0.hasOutput }), inputID != outputID else {
            status = "Choose a virtual input and a separate physical output"
            return
        }
        let granted = await AVCaptureDevice.requestAccess(for: .audio)
        guard startToken == token else { return }
        guard granted else { status = "Audio input permission is required"; return }
        let graph = AVAudioEngine()
        do {
            try setDevice(inputID, node: graph.inputNode)
            try setDevice(outputID, node: graph.outputNode)
            let format = graph.inputNode.outputFormat(forBus: 0)
            guard format.sampleRate >= 8000, format.channelCount == 2 else {
                status = "The virtual input must provide stereo PCM at a valid sample rate"
                return
            }
            // Native EQ is an explicit, limited routing mode. It does not claim
            // to implement the Swift engine's dynamics, delay or subwoofer bus.
            let eq = AVAudioUnitEQ(numberOfBands: configuration.eq.count + 2)
            let maxHz = Float(format.sampleRate * 0.45)
            for (index, band) in configuration.eq.enumerated() {
                let filter = eq.bands[index]
                filter.filterType = .parametric
                filter.frequency = min(max(band.frequency, 20), maxHz)
                filter.gain = min(max(band.gainDB, -24), 24)
                filter.bandwidth = min(max(2 * asinhf(1 / (2 * max(band.q, 0.05))) / logf(2), 0.05), 5)
                filter.bypass = false
            }
            for (offset, frequency) in [configuration.highPassHz, configuration.subsonicHz].enumerated() {
                let filter = eq.bands[configuration.eq.count + offset]
                filter.filterType = .highPass
                filter.frequency = min(max(frequency, 20), maxHz)
                filter.bypass = frequency <= 10
            }
            eq.globalGain = min(max(configuration.masterGainDB, -96), 24)
            graph.attach(eq)
            graph.connect(graph.inputNode, to: eq, format: format)
            graph.connect(eq, to: graph.mainMixerNode, format: format)
            try graph.start()
            engine = graph
            running = true
            status = "Virtual input → EQ and preamp → selected output. Restart routing after changing tuning."
        } catch {
            graph.stop()
            status = "Routing error: \(error.localizedDescription)"
        }
    }

    private func setDevice(_ id: AudioDeviceID, node: AVAudioIONode) throws {
        guard let unit = node.audioUnit else { throw CocoaError(.featureUnsupported) }
        var device = id
        let result = AudioUnitSetProperty(unit, kAudioOutputUnitProperty_CurrentDevice,
            kAudioUnitScope_Global, 0, &device, UInt32(MemoryLayout<AudioDeviceID>.size))
        guard result == noErr else { throw NSError(domain: NSOSStatusErrorDomain, code: Int(result)) }
    }

    func stop() {
        startToken = UUID()
        engine?.stop()
        engine = nil
        running = false
        status = "Routing stopped"
    }
}

struct MacRoutingView: View {
    let configuration: DSPConfiguration
    let stopLocalPlayback: () -> Void
    @ObservedObject var routing: MacRoutingController
    @State private var starting = false

    var body: some View {
        GroupBox("macOS System Audio — Experimental EQ Routing") {
            VStack(alignment: .leading, spacing: 10) {
                Text("Send system audio to an installed virtual audio device, then select its input here. Choose speakers or headphones as the output. CarDSP does not change the system default device.")
                Picker("Virtual input", selection: $routing.inputID) {
                    Text("Select input").tag(AudioDeviceID(0))
                    ForEach(routing.devices.filter { $0.isVirtual && $0.hasInput }) { Text($0.name).tag($0.id) }
                }
                .disabled(routing.running || starting)
                Picker("Physical output", selection: $routing.outputID) {
                    Text("Select output").tag(AudioDeviceID(0))
                    ForEach(routing.devices.filter { !$0.isVirtual && $0.hasOutput }) { Text($0.name).tag($0.id) }
                }
                .disabled(routing.running || starting)
                Button("Refresh Devices") { routing.refresh() }.disabled(routing.running || starting)
                Button(routing.running ? "Stop Routing" : "Start EQ Routing") {
                    if routing.running { routing.stop() } else {
                        starting = true
                        stopLocalPlayback()
                        Task { await routing.start(configuration: configuration); starting = false }
                    }
                }.disabled(starting)
                Text("This route applies EQ, high-pass filters and preamp only. Limiter, compressor, time alignment, polarity and subwoofer controls do not apply.")
                Text(routing.status)
            }.font(.caption)
        }
        .task { routing.refresh() }
        .onDisappear { routing.stop() }
        .onReceive(NotificationCenter.default.publisher(for: .AVAudioEngineConfigurationChange)) { _ in
            if routing.running { routing.stop() }
        }
    }
}
#endif
