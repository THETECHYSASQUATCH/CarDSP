import SwiftUI
import CarDSPCore

@MainActor
final class DSPViewModel: ObservableObject {
    @Published var configuration: DSPConfiguration {
        didSet { configuration.save() }
    }

    let dsp: RealTimeDSPEngine

    init() {
        let saved = DSPConfiguration.load() ?? DSPConfiguration()
        configuration = saved
        dsp = RealTimeDSPEngine(configuration: saved)
    }

    func apply(_ newConfiguration: DSPConfiguration) {
        configuration = newConfiguration
        dsp.setConfiguration(newConfiguration)
    }

    func update(_ transform: (inout DSPConfiguration) -> Void) {
        var updated = configuration
        transform(&updated)
        apply(updated)
    }

    func resetFlat() {
        apply(DSPConfiguration())
    }
}

struct ContentView: View {
    @StateObject private var viewModel = DSPViewModel()
    @StateObject private var micAnalyzer = MicrophoneAnalyzer()
    @StateObject private var music = MusicPlaybackCoordinator()
    @StateObject private var audio = AudioEngineController()

    var body: some View {
        TabView {
            NavigationStack {
                VStack(spacing: 18) {
                    Image(systemName: "car.fill").font(.system(size: 44))
                    Text("CarDSP").font(.largeTitle.bold())
                    Text("Real-time car audio DSP")
                        .foregroundStyle(.secondary)

                    GroupBox("Audio Route") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(AudioSessionController.shared.currentRouteDescription)
                                .font(.footnote)
                            Text(audio.status)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Button("Request Apple Music Access") {
                        Task { await music.requestAccess() }
                    }
                    .buttonStyle(.borderedProminent)

                    Button(audio.isRunning ? "Stop DSP Test Engine" : "Start DSP Test Engine") {
                        if audio.isRunning { audio.stop() }
                        else { audio.start(dsp: viewModel.dsp) }
                    }
                    .buttonStyle(.bordered)

                    Text(music.status).font(.footnote)
                }
                .padding()
                .navigationTitle("Player")
            }
            .tabItem { Label("Player", systemImage: "play.circle") }

            EQScreen(viewModel: viewModel)
                .tabItem { Label("EQ", systemImage: "slider.horizontal.3") }

            MicrophoneAnalyzerView(analyzer: micAnalyzer)
                .tabItem { Label("Analyzer", systemImage: "waveform") }
        }
        .task {
            try? AudioSessionController.shared.configurePlayback()
        }
    }
}
