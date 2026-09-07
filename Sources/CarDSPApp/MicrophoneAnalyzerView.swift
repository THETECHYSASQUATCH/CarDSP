import SwiftUI
import CarDSPCore

struct MicrophoneAnalyzerView: View {
    @ObservedObject var analyzer: MicrophoneAnalyzer
    @ObservedObject var viewModel: DSPViewModel
    @State private var targetCurve: EQTargetCurve = .carSQ
    @State private var correctionStrength: Double = 0.35
    @State private var autoEQStatus = "Measure the cabin before applying Auto-EQ"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    HStack {
                        Circle()
                            .fill(analyzer.isRunning ? .green : .gray)
                            .frame(width: 10, height: 10)
                        Text(analyzer.status)
                        Spacer()
                        Button(analyzer.isRunning ? "Stop" : "Start") {
                            if analyzer.isRunning {
                                analyzer.stop()
                            } else {
                                try? analyzer.start()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }

                    GroupBox("Auto-EQ Target") {
                        VStack(alignment: .leading, spacing: 12) {
                            Picker("Target Curve", selection: $targetCurve) {
                                ForEach(EQTargetCurve.allCases, id: \.self) { curve in
                                    Text(curve.rawValue).tag(curve)
                                }
                            }

                            HStack {
                                Text("Correction Strength")
                                Spacer()
                                Text(String(format: "%.0f%%", correctionStrength * 100))
                                    .monospacedDigit()
                            }

                            Slider(value: $correctionStrength, in: 0.15...0.65, step: 0.05)

                            Button("Apply Auto-EQ to Current Tuning") {
                                applyAutoEQ()
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(analyzer.bands.isEmpty)

                            Text(autoEQStatus)
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text("Car SQ adds a moderate low-frequency lift and gentle high-frequency roll-off. All corrections are capped and the DSP preamp is reduced when boosts are introduced.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if analyzer.bands.isEmpty {
                        ContentUnavailableView(
                            "No measurement",
                            systemImage: "waveform",
                            description: Text("Start the microphone analyzer to measure the cabin response.")
                        )
                        .frame(minHeight: 260)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(alignment: .bottom, spacing: 4) {
                                ForEach(analyzer.bands) { band in
                                    VStack(spacing: 3) {
                                        RoundedRectangle(cornerRadius: 2)
                                            .frame(width: 8, height: CGFloat(max(2, min(160, (band.levelDB + 80) * 1.6))))
                                        Text(shortFrequency(band.frequency))
                                            .font(.system(size: 8))
                                            .rotationEffect(.degrees(-55))
                                            .frame(width: 24, height: 28)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, minHeight: 220, alignment: .bottom)
                            .padding(.horizontal)
                        }
                    }

                    Text("RTA levels are relative microphone measurements. For better results, measure from the listening position and repeat measurements from several nearby positions before committing to large EQ changes.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                }
                .padding()
            }
            .navigationTitle("RTA Analyzer")
        }
    }

    private func applyAutoEQ() {
        guard !analyzer.bands.isEmpty else {
            autoEQStatus = "No RTA measurement is available"
            return
        }

        let corrected = AutoEQ.correctedConfiguration(
            base: viewModel.configuration,
            measured: analyzer.bands,
            targetCurve: targetCurve,
            smoothing: Float(correctionStrength)
        )
        viewModel.apply(corrected)
        autoEQStatus = "Applied \(targetCurve.rawValue) target at \(Int(correctionStrength * 100))% correction strength"
    }

    private func shortFrequency(_ frequency: Float) -> String {
        frequency >= 1000
            ? String(format: "%.0fk", frequency / 1000)
            : String(format: "%.0f", frequency)
    }
}
