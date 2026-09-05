
import SwiftUI

struct ContentView: View {
    @StateObject private var music = MusicPlaybackCoordinator()
    @State private var config = DSPConfiguration()
    private let dsp = RealTimeDSPEngine()

    var body: some View {
        TabView {
            VStack(spacing: 20) {
                Text("CarDSP")
                    .font(.largeTitle.bold())
                Text("Phase 2 DSP Engine")
                    .foregroundStyle(.secondary)
                Text(AudioSessionController.shared.currentRouteDescription)
                    .font(.footnote)
                    .multilineTextAlignment(.center)

                Button("Request Apple Music Access") {
                    Task { await music.requestAccess() }
                }
                .buttonStyle(.borderedProminent)

                Text(music.status)
                    .font(.footnote)
            }
            .padding()
            .tabItem { Label("Player", systemImage: "play.circle") }

            EQScreen(configuration: $config, dsp: dsp)
                .tabItem { Label("EQ", systemImage: "slider.horizontal.3") }
        }
        .task {
            try? AudioSessionController.shared.configure()
        }
    }
}

struct EQScreen: View {
    @Binding var configuration: DSPConfiguration
    let dsp: RealTimeDSPEngine

    var body: some View {
        NavigationStack {
            List {
                Section("31-Band EQ") {
                    ForEach(configuration.eq.indices, id: \.self) { i in
                        VStack(alignment: .leading) {
                            HStack {
                                Text(label(configuration.eq[i].frequency))
                                Spacer()
                                Text(String(format: "%.1f dB", configuration.eq[i].gainDB))
                                    .monospacedDigit()
                            }
                            Slider(value: Binding(
                                get: { configuration.eq[i].gainDB },
                                set: {
                                    configuration.eq[i].gainDB = $0
                                    dsp.setConfiguration(configuration)
                                }
                            ), in: -12...12)
                        }
                    }
                }

                Section("Car DSP") {
                    HStack {
                        Text("Sub LPF")
                        Spacer()
                        Text("\(Int(configuration.lowPassHz)) Hz")
                    }
                    Slider(value: Binding(
                        get: { configuration.lowPassHz },
                        set: {
                            configuration.lowPassHz = $0
                            dsp.setConfiguration(configuration)
                        }
                    ), in: 40...200)

                    HStack {
                        Text("Subsonic")
                        Spacer()
                        Text("\(Int(configuration.subsonicHz)) Hz")
                    }
                    Slider(value: Binding(
                        get: { configuration.subsonicHz },
                        set: {
                            configuration.subsonicHz = $0
                            dsp.setConfiguration(configuration)
                        }
                    ), in: 10...40)
                }

                Section {
                    Button("Flat") {
                        configuration = DSPConfiguration()
                        dsp.setConfiguration(configuration)
                    }
                    Button("Car Bass") {
                        configuration = .carBass()
                        dsp.setConfiguration(configuration)
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
