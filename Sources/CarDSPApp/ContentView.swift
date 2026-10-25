import SwiftUI
import Combine
import CarDSPCore
import UniformTypeIdentifiers

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

    var maximumEQBoostDB: Float {
        max(0, configuration.eq.map(\.gainDB).max() ?? 0)
    }

    var recommendedPreampDB: Float { -maximumEQBoostDB }

    var estimatedHeadroomDB: Float {
        -(maximumEQBoostDB + configuration.masterGainDB)
    }

    var headroomStatus: String {
        if estimatedHeadroomDB >= 0 { return "Good" }
        if estimatedHeadroomDB >= -3 { return "Caution" }
        return "Clipping Risk"
    }

    func applySafePreamp() {
        update { $0.masterGainDB = recommendedPreampDB }
    }
}

struct ContentView: View {
    @StateObject private var viewModel = DSPViewModel()
    @StateObject private var micAnalyzer = MicrophoneAnalyzer()
    @StateObject private var music = MusicPlaybackCoordinator()
    @StateObject private var audio = AudioEngineController()
    @StateObject private var outputProfiles = OutputProfileStore()
    @State private var routeRefreshToken = UUID()
    @State private var lastRouteChange = "Monitoring audio route"
    @State private var profileStatus = "No output profile loaded"
    @State private var choosingAudioFile = false
#if os(macOS)
    @StateObject private var macRouting = MacRoutingController()
#endif

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
                                    Text("Channels")
                                    Spacer()
                                    Text(AudioSessionController.shared.currentChannelCountDescription)
                                }
                                .font(.footnote)

                                HStack {
                                    Text("DSP Engine")
                                    Spacer()
                                    Text(audio.isRunning ? "Running" : "Stopped")
                                        .fontWeight(.semibold)
                                }
                                .font(.footnote)

                                Text(lastRouteChange)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                Text("Supports Bluetooth, AirPlay, Lightning-to-AUX, USB-C-to-AUX, wired headphones, line-out, and compatible USB audio interfaces. iOS chooses the active physical route.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .id(routeRefreshToken)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        GroupBox("Output DSP Profile") {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("Current Output")
                                    Spacer()
                                    Text(AudioSessionController.shared.currentRouteProfileName)
                                        .multilineTextAlignment(.trailing)
                                }

                                Toggle("Auto-load saved profile when output connects", isOn: $outputProfiles.autoLoadEnabled)

                                HStack {
                                    Button("Save Current Tuning") {
                                        saveCurrentOutputProfile()
                                    }
                                    .buttonStyle(.borderedProminent)

                                    Button("Load Saved") {
                                        loadCurrentOutputProfile(showMissingStatus: true)
                                    }
                                    .buttonStyle(.bordered)
                                }

                                if outputProfiles.profile(for: AudioSessionController.shared.currentRouteProfileKey) != nil {
                                    Button("Delete Saved Profile", role: .destructive) {
                                        let key = AudioSessionController.shared.currentRouteProfileKey
                                        outputProfiles.delete(routeKey: key)
                                        profileStatus = "Saved profile deleted for this output"
                                    }
                                    .font(.caption)
                                }

                                Text(profileStatus)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                Text("Profiles stay on this device and contain only the DSP configuration associated with the audio route reported by iOS.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .font(.footnote)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        GroupBox("Queued DSP Buffer Level") {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("Peak")
                                    Spacer()
                                    Text(String(format: "%.1f dBFS", audio.peakDBFS))
                                        .monospacedDigit()
                                }

                                ProgressView(value: Double(max(-60, min(0, audio.peakDBFS)) + 60), total: 60)

                                HStack {
                                    Text("Clip Status")
                                    Spacer()
                                    Label(audio.isClipping ? "CLIPPING" : "Clean",
                                          systemImage: audio.isClipping ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                                        .fontWeight(.semibold)
                                }

                                Text("Peak level of the latest processed local-file buffer, which may be queued ahead of playback. This does not meter MusicKit or macOS virtual routing.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .font(.footnote)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        GroupBox("Signal Path") {
                            VStack(alignment: .leading, spacing: 8) {
                                Label("App Audio Source", systemImage: "music.note")
                                Image(systemName: "arrow.down")
                                Text("Time alignment and gain → HPF \(Int(viewModel.configuration.highPassHz)) Hz → Subsonic \(Int(viewModel.configuration.subsonicHz)) Hz → 31-band EQ → Compressor")
                                    .font(.footnote)
                                Text("Time Alignment \(String(format: "%.1f", viewModel.configuration.timeAlignmentMs)) ms; Limiter \(viewModel.configuration.limiterEnabled ? "ON" : "OFF"). LPF is reserved for the separate subwoofer bus.")
                                    .font(.footnote)
                                Image(systemName: "arrow.down")
                                Label(AudioSessionController.shared.currentOutputTypeDescription, systemImage: "cable.connector")
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        GroupBox("Headroom Protection") {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack { Text("Maximum EQ Boost"); Spacer(); Text(String(format: "+%.1f dB", viewModel.maximumEQBoostDB)) }
                                HStack { Text("Master Gain"); Spacer(); Text(String(format: "%.1f dB", viewModel.configuration.masterGainDB)) }
                                HStack { Text("Estimated Headroom"); Spacer(); Text(String(format: "%.1f dB", viewModel.estimatedHeadroomDB)) }
                                HStack { Text("Status"); Spacer(); Text(viewModel.headroomStatus).fontWeight(.semibold) }
                                Text("Positive EQ boosts consume digital headroom. Safe Preamp offsets the largest boost to reduce clipping risk before the limiter.")
                                    .font(.caption).foregroundStyle(.secondary)
                                Button("Apply Safe Preamp (\(String(format: "%.1f", viewModel.recommendedPreampDB)) dB)") {
                                    viewModel.applySafePreamp()
                                }
                                .buttonStyle(.borderedProminent)
                            }
                            .font(.footnote)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Button("Request Apple Music Access") { Task { await music.requestAccess() } }
                            .buttonStyle(.borderedProminent)

                        Text("Apple Music playback is separate and is not processed by this DSP. Choose an unprotected local audio file for EQ and dynamics.")
                            .font(.caption).foregroundStyle(.secondary)
                        Button("Choose Local Audio File") { choosingAudioFile = true }

#if os(macOS)
                        MacRoutingView(configuration: viewModel.configuration, stopLocalPlayback: { audio.stop() }, routing: macRouting)
#endif

                        Button(audio.isRunning ? "Stop DSP Engine" : "Start DSP Engine") {
#if os(macOS)
                            macRouting.stop()
#endif
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

            MicrophoneAnalyzerView(analyzer: micAnalyzer, viewModel: viewModel)
                .tabItem { Label("Analyzer", systemImage: "waveform") }
        }
        .task {
            try? AudioSessionController.shared.configureForPlayback()
            routeRefreshToken = UUID()
            if outputProfiles.autoLoadEnabled {
                loadCurrentOutputProfile(showMissingStatus: false)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: AudioSessionController.routeChangeNotification)) { notification in
            audio.routeChanged()
            lastRouteChange = AudioSessionController.shared.routeChangeReasonDescription(notification)
            routeRefreshToken = UUID()
            if outputProfiles.autoLoadEnabled {
                loadCurrentOutputProfile(showMissingStatus: false)
            }
        }
        .fileImporter(isPresented: $choosingAudioFile, allowedContentTypes: [.audio]) { result in
#if os(macOS)
            macRouting.stop()
#endif
            if case .success(let url) = result { audio.load(url: url, dsp: viewModel.dsp) }
        }
    }

    private func saveCurrentOutputProfile() {
        let session = AudioSessionController.shared
        outputProfiles.saveCurrent(
            configuration: viewModel.configuration,
            routeKey: session.currentRouteProfileKey,
            name: session.currentRouteProfileName
        )
        profileStatus = "Saved tuning for \(session.currentRouteProfileName)"
    }

    private func loadCurrentOutputProfile(showMissingStatus: Bool) {
        let session = AudioSessionController.shared
        let key = session.currentRouteProfileKey
        if let profile = outputProfiles.profile(for: key) {
            viewModel.apply(profile.configuration)
            profileStatus = "Loaded tuning for \(profile.name)"
        } else if showMissingStatus {
            profileStatus = "No saved profile for \(session.currentRouteProfileName)"
        }
    }
}
