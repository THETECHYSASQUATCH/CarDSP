import SwiftUI
import CarDSPCore

@MainActor
final class DSPViewModel: ObservableObject {
    @Published var configuration: DSPConfiguration {
        didSet { configuration.save() }
    }

    private let dsp: RealTimeDSPEngine
    public var engine: RealTimeDSPEngine { dsp }

    init() {
        let saved = DSPConfiguration.load() ?? DSPConfiguration()
        configuration = saved
        dsp = RealTimeDSPEngine(configuration: saved)
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
        applyPreset(.flat())
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
                Text(AudioSessionController.shared.currentRouteDescription.isEmpty
                     ? "No output route"
                     : AudioSessionController.shared.currentRouteDescription)
                    .font(.footnote)
                    .multilineTextAlignment(.center)

                Button("Request Apple Music Access") {
                    Task { await music.requestAccess() }
                }
                .buttonStyle(.borderedProminent)

                Text("MusicKit playback is app-owned. The system Music app cannot be transparently routed through this custom DSP on iOS.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Text(music.status)
                    .font(.footnote)
            }
            .padding()
            .tabItem { Label("Player", systemImage: "play.circle") }

            EQScreen(viewModel: viewModel)
                .tabItem { Label("EQ", systemImage: "slider.horizontal.3") }

            MicrophoneAnalyzerView(analyzer: micAnalyzer)
                .tabItem { Label("Analyzer", systemImage: "waveform") }
        }
        .task {
            try? AudioSessionController.shared.configureForPlayback()
        }
    }
}
