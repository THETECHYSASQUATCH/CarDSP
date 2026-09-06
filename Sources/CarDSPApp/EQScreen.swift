import SwiftUI
import CarDSPCore

struct EQScreen: View {
    @ObservedObject var viewModel: DSPViewModel
    @State private var selectedPreset = "Flat"

    private let presets: [(String, DSPConfiguration)] = [
        ("Flat", .flat()),
        ("Bass", .bassBoost()),
        ("Rock", .rock()),
        ("Vocal", .vocal()),
        ("Treble", .trebleBoost())
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Preset") {
                    Picker("Preset", selection: $selectedPreset) {
                        ForEach(presets.map(\.0), id: \.self) { Text($0).tag($0) }
                    }
                    .onChange(of: selectedPreset) { _, name in
                        if let preset = presets.first(where: { $0.0 == name })?.1 {
                            viewModel.applyPreset(preset)
                        }
                    }
                    Button("Kia Sportage Sub Setup") {
                        viewModel.applyPreset(CarAudioProfile.kiaSportage2017.defaultConfiguration)
                        selectedPreset = "Flat"
                    }
                    Button("Reset Flat", role: .destructive) {
                        viewModel.resetFlat()
                        selectedPreset = "Flat"
                    }
                }

                Section("31-Band EQ") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .bottom, spacing: 12) {
                            ForEach(viewModel.configuration.eq.indices, id: \.self) { index in
                                VStack(spacing: 6) {
                                    Text(String(format: "%.1f", viewModel.configuration.eq[index].frequency))
                                        .font(.caption2)
                                        .frame(width: 42)
                                    Slider(
                                        value: Binding(
                                            get: { Double(viewModel.configuration.eq[index].gainDB) },
                                            set: { value in
                                                viewModel.updateConfiguration { config in
                                                    config.eq[index].gainDB = Float(value)
                                                }
                                            }
                                        ),
                                        in: -12...12
                                    )
                                    .frame(width: 42, height: 180)
                                    .rotationEffect(.degrees(-90))
                                    Text(String(format: "%+.1f", viewModel.configuration.eq[index].gainDB))
                                        .font(.caption2.monospacedDigit())
                                        .frame(width: 42)
                                }
                            }
                        }
                        .padding(.vertical)
                    }
                }

                Section("Crossover") {
                    valueSlider("High-pass", value: FloatBinding(value: viewModel.configuration.highPassHz) { value in
                        viewModel.updateConfiguration { $0.highPassHz = value }
                    }, range: 10...300, format: "%.0f Hz")
                    valueSlider("Subsonic", value: FloatBinding(value: viewModel.configuration.subsonicHz) { value in
                        viewModel.updateConfiguration { $0.subsonicHz = value }
                    }, range: 10...80, format: "%.0f Hz")
                    valueSlider("Low-pass", value: FloatBinding(value: viewModel.configuration.lowPassHz) { value in
                        viewModel.updateConfiguration { $0.lowPassHz = value }
                    }, range: 40...250, format: "%.0f Hz")
                }

                Section("Output") {
                    valueSlider("Master gain", value: FloatBinding(value: viewModel.configuration.masterGainDB) { value in
                        viewModel.updateConfiguration { $0.masterGainDB = value }
                    }, range: -12...6, format: "%+.1f dB")
                    Toggle("Limiter", isOn: Binding(
                        get: { viewModel.configuration.limiterEnabled },
                        set: { enabled in viewModel.updateConfiguration { $0.limiterEnabled = enabled } }
                    ))
                    Toggle("Invert polarity", isOn: Binding(
                        get: { viewModel.configuration.polarityInverted },
                        set: { inverted in viewModel.updateConfiguration { $0.polarityInverted = inverted } }
                    ))
                }
            }
            .navigationTitle("DSP EQ")
        }
    }

    private func valueSlider(_ title: String, value: Binding<Float>, range: ClosedRange<Float>, format: String) -> some View {
        VStack(alignment: .leading) {
            HStack {
                Text(title)
                Spacer()
                Text(String(format: format, value.wrappedValue))
                    .font(.caption.monospacedDigit())
            }
            Slider(value: value, in: range)
        }
    }
}

private struct FloatBinding: DynamicProperty {
    private let binding: Binding<Float>

    init(value: Float, set: @escaping (Float) -> Void) {
        self.binding = Binding(get: { value }, set: set)
    }

    var wrappedValue: Float { binding.wrappedValue }
}
