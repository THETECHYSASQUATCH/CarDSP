import SwiftUI

@MainActor
final class DSPViewModel: ObservableObject {
    @Published var configuration: DSPConfiguration {
        didSet {
            configuration.save()
        }
    }

    private let dsp: RealTimeDSPEngine

    // expose engine to the UI
    public var engine: RealTimeDSPEngine { dsp }

    init() {
        let saved = DSPConfiguration.load() ?? DSPConfiguration()
        self.configuration = saved
        self.dsp = RealTimeDSPEngine(configuration: saved)
    }

    func applyPreset(_ preset: DSPConfiguration) {
        configuration = preset
        syncEngine()
    }

    func updateConfiguration(_ transform: (inout DSPConfiguration) -> Void) {
        var updated = configuration
        transform(&updated)
        configuration = updated
        syncEngine()
    }

    func resetFlat() {
        updateConfiguration { config in
            for i in config.eq.indices {
                config.eq[i].gainDB = 0
            }
            config.masterGainDB = 0
            config.highPassHz = 20
            config.subsonicHz = 20
            config.lowPassHz = 90
            config.limiterThresholdDB = -1
            config.limiterEnabled = true
            config.timeAlignmentMs = 0
            config.polarityInverted = false
            config.compressorThresholdDB = -6
            config.compressorRatio = 3.0
            config.compressorAttackSeconds = 0.01
            config.compressorReleaseSeconds = 0.12
        }
    }

    private func syncEngine() {
        dsp.setConfiguration(configuration)
    }
}

struct ContentView: View {
    @StateObject private var viewModel = DSPViewModel()
    @StateObject private var micAnalyzer = MicrophoneAnalyzer()
    @StateObject private var music = MusicPlaybackCoordinator()

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

                Button(viewModel.engine.isRunning ? "Stop Engine" : "Start Engine") {
                    if viewModel.engine.isRunning {
                        viewModel.engine.stop()
                    } else {
                        try? viewModel.engine.start()
                    }
                }
                .buttonStyle(.bordered)

                Text(music.status)
                    .font(.footnote)
                Text(viewModel.engine.status)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .tabItem { Label("Player", systemImage: "play.circle") }

            EQScreen(viewModel: viewModel)
                .tabItem { Label("EQ", systemImage: "slider.horizontal.3") }

            MicrophoneAnalyzerView(analyzer: micAnalyzer)
                .tabItem { Label("Analyzer", systemImage: "waveform") }
        }
        .task {
            try? AudioSessionController.shared.configure()
        }
    }
}
