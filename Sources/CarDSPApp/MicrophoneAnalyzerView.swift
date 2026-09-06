import SwiftUI
import CarDSPCore

struct MicrophoneAnalyzerView: View {
    @ObservedObject var analyzer: MicrophoneAnalyzer

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
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

                if analyzer.bands.isEmpty {
                    ContentUnavailableView(
                        "No measurement",
                        systemImage: "waveform",
                        description: Text("Start the microphone analyzer to measure the cabin response.")
                    )
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
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                        .padding(.horizontal)
                    }
                }

                Text("RTA levels are relative microphone measurements. Auto-EQ should be used only after placing the microphone at the listening position.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            }
            .padding()
            .navigationTitle("RTA Analyzer")
        }
    }

    private func shortFrequency(_ frequency: Float) -> String {
        frequency >= 1000
            ? String(format: "%.0fk", frequency / 1000)
            : String(format: "%.0f", frequency)
    }
}
