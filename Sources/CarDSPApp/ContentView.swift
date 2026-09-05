
import SwiftUI

@MainActor
final class DSPViewModel: ObservableObject {
    @Published var configuration: DSPConfiguration {
        didSet {
            configuration.save()
        }
    }

    @Published var selectedProfile: VehicleProfile? = .kiaSportageLX
    private let dsp: RealTimeDSPEngine

    init() {
        let saved = DSPConfiguration.load() ?? DSPConfiguration()
        self.configuration = saved
        self.dsp = RealTimeDSPEngine(configuration: saved)
        self.selectedProfile = .kiaSportageLX
    }

    func applyPreset(_ preset: DSPConfiguration) {
        configuration = preset
        syncEngine()
    }

    func applyProfile(_ profile: VehicleProfile) {
        selectedProfile = profile
        var updated = configuration
        profile.apply(to: &updated)
        configuration = updated
        syncEngine()
    }

    func updateConfiguration(_ transform: (inout DSPConfiguration) -> Void) {
        var updated = configuration
        transform(&updated)
        configuration = updated
        syncEngine()
    }

    func resetFlat() {
        configuration = DSPConfiguration()
        syncEngine()
    }

    private func syncEngine() {
        dsp.setConfiguration(configuration)
    }
}

struct ContentView: View {
    @StateObject private var music = MusicPlaybackCoordinator()
    @StateObject private var viewModel = DSPViewModel()
    @StateObject private var engine = AudioEngineController.shared

    var body: some View {
        TabView {
            VStack(spacing: 20) {
                Text("CarDSP")
                    .font(.largeTitle.bold())
                Text("iPhone car-audio DSP")
                    .foregroundStyle(.secondary)
                Text(AudioSessionController.shared.currentRouteDescription)
                    .font(.footnote)
                    .multilineTextAlignment(.center)

                Button("Request Apple Music Access") {
                    Task { await music.requestAccess() }
                }
                .buttonStyle(.borderedProminent)

                Button(engine.isRunning ? "Stop Engine" : "Start Engine") {
                    if engine.isRunning {
                        engine.stop()
                    } else {
                        try? engine.start()
                    }
                }
                .buttonStyle(.bordered)

                Text(music.status)
                    .font(.footnote)
                Text(engine.status)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .tabItem { Label("Player", systemImage: "play.circle") }

            EQScreen(viewModel: viewModel)
                .tabItem { Label("EQ", systemImage: "slider.horizontal.3") }

            SignalTestScreen()
                .tabItem { Label("Analyzer", systemImage: "waveform") }
        }
        .task {
            try? AudioSessionController.shared.configure()
        }
    }
}

struct EQScreen: View {
    @ObservedObject var viewModel: DSPViewModel

    var body: some View {
        NavigationStack {
            List {
                Section("Vehicle profile") {
                    Picker("Profile", selection: Binding(
                        get: { viewModel.selectedProfile ?? .kiaSportageLX },
                        set: { viewModel.applyProfile($0) }
                    )) {
                        Text(VehicleProfile.kiaSportageLX.name).tag(VehicleProfile.kiaSportageLX)
                    }
                    .pickerStyle(.menu)

                    if let profile = viewModel.selectedProfile {
                        Text(profile.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("31-Band EQ") {
                    ForEach(viewModel.configuration.eq.indices, id: \.self) { i in
                        VStack(alignment: .leading) {
                            HStack {
                                Text(label(viewModel.configuration.eq[i].frequency))
                                Spacer()
                                Text(String(format: "%.1f dB", viewModel.configuration.eq[i].gainDB))
                                    .monospacedDigit()
                            }
                            Slider(value: Binding(
                                get: { viewModel.configuration.eq[i].gainDB },
                                set: { value in
                                    viewModel.updateConfiguration { config in
                                        config.eq[i].gainDB = value
                                    }
                                }
                            ), in: -12...12)
                        }
                    }
                }

                Section("Car DSP") {
                    HStack {
                        Text("Sub LPF")
                        Spacer()
                        Text("\(Int(viewModel.configuration.lowPassHz)) Hz")
                    }
                    Slider(value: Binding(
                        get: { viewModel.configuration.lowPassHz },
                        set: { value in
                            viewModel.updateConfiguration { config in
                                config.lowPassHz = value
                            }
                        }
                    ), in: 40...200)

                    HStack {
                        Text("Subsonic")
                        Spacer()
                        Text("\(Int(viewModel.configuration.subsonicHz)) Hz")
                    }
                    Slider(value: Binding(
                        get: { viewModel.configuration.subsonicHz },
                        set: { value in
                            viewModel.updateConfiguration { config in
                                config.subsonicHz = value
                            }
                        }
                    ), in: 10...40)

                    HStack {
                        Text("Master gain")
                        Spacer()
                        Text(String(format: "%.1f dB", viewModel.configuration.masterGainDB))
                    }
                    Slider(value: Binding(
                        get: { viewModel.configuration.masterGainDB },
                        set: { value in
                            viewModel.updateConfiguration { config in
                                config.masterGainDB = value
                            }
                        }
                    ), in: -12...12)
                }

                Section {
                    Button("Flat") {
                        viewModel.resetFlat()
                    }
                    Button("Car Bass") {
                        viewModel.applyPreset(.carBass())
                    }
                    Button("Sportage LX") {
                        viewModel.applyProfile(.kiaSportageLX)
                    }
                }
            }
            .navigationTitle("DSP")
        }
    }

    private func label(_ frequency: Float) -> String {
        frequency >= 1000
            ? String(format: "%.1fk", frequency / 1000)
            : String(format: "%.1f", frequency)
    }
}

struct SignalTestScreen: View {
    private let sampledBands = RTAAnalyzer.measure(
        from: Array(repeating: 0.5, count: 2048),
        sampleRate: 48_000
    )

    var body: some View {
        NavigationStack {
            List(sampledBands, id: \ .frequency) { band in
                HStack {
                    Text(String(format: "%.0f Hz", band.frequency))
                    Spacer()
                    Text(String(format: "%.1f dB", band.levelDB))
                        .monospacedDigit()
                }
            }
            .navigationTitle("Analyzer")
        }
    }
}
