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
                        if let preset = presets.first(where: { $0.0 == name })?.1 { viewModel.apply(preset) }
                    }
                    Button("Kia Sportage Sub Setup") {
                        viewModel.apply(CarAudioProfile.kiaSportage2017.defaultConfiguration)
                    }
                    Button("Reset Flat", role: .destructive) {
                        viewModel.resetFlat(); selectedPreset = "Flat"
                    }
                }
                Section("31-Band EQ") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .bottom, spacing: 12) {
                            ForEach(viewModel.configuration.eq.indices, id: \.self) { index in
                                VStack(spacing: 6) {
                                    Text(String(format: "%.0f", viewModel.configuration.eq[index].frequency)).font(.caption2)
                                    Slider(value: Binding(
                                        get: { Double(viewModel.configuration.eq[index].gainDB) },
                                        set: { value in viewModel.update { $0.eq[index].gainDB = Float(value) } }
                                    ), in: -12...12)
                                    .frame(width: 42, height: 180)
                                    .rotationEffect(.degrees(-90))
                                    Text(String(format: "%+.1f", viewModel.configuration.eq[index].gainDB)).font(.caption2.monospacedDigit())
                                }.frame(width: 50)
                            }
                        }.padding(.vertical)
                    }
                }
                Section("Crossover") {
                    valueSlider("High-pass", value: Binding(get: { viewModel.configuration.highPassHz }, set: { v in viewModel.update { $0.highPassHz = v } }), range: 10...300, format: "%.0f Hz")
                    valueSlider("Subsonic", value: Binding(get: { viewModel.configuration.subsonicHz }, set: { v in viewModel.update { $0.subsonicHz = v } }), range: 10...80, format: "%.0f Hz")
                    valueSlider("Low-pass", value: Binding(get: { viewModel.configuration.lowPassHz }, set: { v in viewModel.update { $0.lowPassHz = v } }), range: 40...250, format: "%.0f Hz")
                }
                Section("Output") {
                    valueSlider("Master gain", value: Binding(get: { viewModel.configuration.masterGainDB }, set: { v in viewModel.update { $0.masterGainDB = v } }), range: -12...6, format: "%+.1f dB")
                    Toggle("Limiter", isOn: Binding(get: { viewModel.configuration.limiterEnabled }, set: { v in viewModel.update { $0.limiterEnabled = v } }))
                    Toggle("Invert polarity", isOn: Binding(get: { viewModel.configuration.polarityInverted }, set: { v in viewModel.update { $0.polarityInverted = v } }))
                }
            }.navigationTitle("DSP EQ")
        }
    }

    private func valueSlider(_ title: String, value: Binding<Float>, range: ClosedRange<Float>, format: String) -> some View {
        VStack(alignment: .leading) {
            HStack { Text(title); Spacer(); Text(String(format: format, value.wrappedValue)).font(.caption.monospacedDigit()) }
            Slider(value: value, in: range)
        }
    }
}
