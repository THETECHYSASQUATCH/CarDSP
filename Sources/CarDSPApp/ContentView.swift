import SwiftUI
import CarDSPCore

@MainActor
final class DSPViewModel: ObservableObject {
    @Published var configuration: DSPConfiguration { didSet { configuration.save() } }
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

    func resetFlat() { apply(.flat()) }
}

struct ContentView: View {
    @StateObject private var viewModel = DSPViewModel()
    @StateObject private var micAnalyzer = MicrophoneAnalyzer()
    @StateObject private var music = MusicPlaybackCoordinator()
    @StateObject private var audio = AudioEngineController()
    @State private var routeRefreshToken = UUID()

    var body: some View {
        TabView {
            NavigationStack {
                ScrollView {
                    VStack(spacing: 18) {
                        Image(systemName: "car.fill").font(.system(size: 44))
                        Text("CarDSP").font(.largeTitle.bold())
                        Text("Real-time car audio DSP").foregroundStyle(.secondary)

                        GroupBox("Audio Output") {
                            VStack(alignment: .leading, spacing: 10) {
                                Label(AudioSessionController.shared.currentOutputTypeDescription,
                                      systemImage: "speaker.wave.2.fill")
                                    .font(.headline)

                                Text(AudioSessionController.shared.currentRouteDescription)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)

                                HStack {
                                    Text("Sample Rate")
                                    Spacer()
                                    Text(AudioSessionController.shared.currentSampleRateDescription)
                                        .monospacedDigit()
                                }
                                .font(.footnote)

                                HStack {
                                    Text("DSP Engine")
                                    Spacer()
                                    Text(audio.isRunning ? "Running" : "Stopped")
                                        .fontWeight(.semibold)
                                }
                                .font(.footnote)

                                Text("Supports Bluetooth, AirPlay, Lightning-to-AUX, USB-C-to-AUX, wired headphones, line-out, and compatible USB audio interfaces. iOS chooses the active physical route.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                Button("Refresh Audio Route") {
                                    routeRefreshToken = UUID()
                                }
                                .buttonStyle(.bordered)
                            }
                            .id(routeRefreshToken)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Button("Request Apple Music Access") { Task { await music.requestAccess() } }
                            .buttonStyle(.borderedProminent)

                        Button(audio.isRunning ? "Stop DSP Engine" : "Start DSP Engine") {
                            if audio.isRunning { audio.stop() } else { audio.start(dsp: viewModel.dsp) }
                            routeRefreshToken = UUID()
                        }
                        .buttonStyle(.bordered)

                        Text(audio.status).font(.caption).foregroundStyle(.secondary)
                        Text(music.status).font(.footnote)
                    }
                    .padding()
                }
                .navigationTitle("Player")
            }
            .tabItem { Label("Player", systemImage: "play.circle") }

            EQScreen(viewModel: viewModel)
                .tabItem { Label("EQ", systemImage: "slider.horizontal.3") }

            MicrophoneAnalyzerView(analyzer: micAnalyzer)
                .tabItem { Label("Analyzer", systemImage: "waveform") }
        }
        .task {
            try? AudioSessionController.shared.configureForPlayback()
            routeRefreshToken = UUID()
        }
    }
}
