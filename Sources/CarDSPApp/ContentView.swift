
import SwiftUI

@MainActor
final class DSPViewModel: ObservableObject {
    @Published var configuration: DSPConfiguration {
        didSet {
            configuration.save()
        }
    }

    private let dsp: RealTimeDSPEngine

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

            MicrophoneAnalyzerView(analyzer: micAnalyzer)
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
                        Text("High-pass")
                        Spacer()
                        Text("\(Int(viewModel.configuration.highPassHz)) Hz")
                    }
                    Slider(value: Binding(
                        get: { viewModel.configuration.highPassHz },
                        set: { value in
                            viewModel.updateConfiguration { config in
                                config.highPassHz = value
                            }
                        }
                    ), in: 10...100)

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

                    HStack {
                        Text("Time alignment")
                        Spacer()
                        Text(String(format: "%.1f ms", viewModel.configuration.timeAlignmentMs))
                    }
                    Slider(value: Binding(
                        get: { viewModel.configuration.timeAlignmentMs },
                        set: { value in
                            viewModel.updateConfiguration { config in
                                config.timeAlignmentMs = value
                            }
                        }
                    ), in: 0...10)

                    HStack {
                        Text("Limiter threshold")
                        Spacer()
                        Text(String(format: "%.1f dB", viewModel.configuration.limiterThresholdDB))
                    }
                    Slider(value: Binding(
                        get: { viewModel.configuration.limiterThresholdDB },
                        set: { value in
                            viewModel.updateConfiguration { config in
                                config.limiterThresholdDB = value
                            }
                        }
                    ), in: -12...0)

                    HStack {
                        Text("Compressor threshold")
                        Spacer()
                        Text(String(format: "%.1f dB", viewModel.configuration.compressorThresholdDB))
                    }
                    Slider(value: Binding(
                        get: { viewModel.configuration.compressorThresholdDB },
                        set: { value in
                            viewModel.updateConfiguration { config in
                                config.compressorThresholdDB = value
                            }
                        }
                    ), in: -30...0)

                    HStack {
                        Text("Compressor ratio")
                        Spacer()
                        Text(String(format: "%.1f:1", viewModel.configuration.compressorRatio))
                    }
                    Slider(value: Binding(
                        get: { viewModel.configuration.compressorRatio },
                        set: { value in
                            viewModel.updateConfiguration { config in
                                config.compressorRatio = value
                            }
                        }
                    ), in: 1...10)

                    Toggle("Polarity invert", isOn: Binding(
                        get: { viewModel.configuration.polarityInverted },
                        set: { value in
                            viewModel.updateConfiguration { config in
                                config.polarityInverted = value
                            }
                        }
                    ))

                    Toggle("Limiter enabled", isOn: Binding(
                        get: { viewModel.configuration.limiterEnabled },
                        set: { value in
                            viewModel.updateConfiguration { config in
                                config.limiterEnabled = value
                            }
                        }
                    ))
                }

                Section {
                    Button("Flat") {
                        viewModel.resetFlat()
                    }
                    Button("Bass Boost") {
                        viewModel.applyPreset(.bassBoost())
                    }
                    Button("Treble Boost") {
                        viewModel.applyPreset(.trebleBoost())
                    }
                    Button("Vocal") {
                        viewModel.applyPreset(.vocal())
                    }
                    Button("Rock") {
                        viewModel.applyPreset(.rock())
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

struct MicrophoneAnalyzerView: View {
    @ObservedObject var analyzer: MicrophoneAnalyzer

    var body: some View {
        NavigationStack {
            VStack {
                Button(analyzer.isRunning ? "Stop Analysis" : "Start Analysis") {
                    if analyzer.isRunning {
                        analyzer.stop()
                    } else {
                        try? analyzer.start()
                    }
                }
                .buttonStyle(.borderedProminent)
                .padding()

                Text(analyzer.status)
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                List(analyzer.bands, id: \ .frequency) { band in
                    HStack {
                        Text(String(format: "%.0f Hz", band.frequency))
                        Spacer()
                        Text(String(format: "%.1f dB", band.levelDB))
                            .monospacedDigit()
                    }
                }
            }
            .navigationTitle("Analyzer")
        }
    }
}
