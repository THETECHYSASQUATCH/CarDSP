import Foundation

public struct RTAFrequencyBand: Identifiable, Sendable {
    public let frequency: Float
    public let levelDB: Float
    public var id: Float { frequency }

    public init(frequency: Float, levelDB: Float) {
        self.frequency = frequency
        self.levelDB = levelDB
    }
}

public enum RTAAnalyzer {
    public static let standardBands: [Float] = [
        20, 25, 31.5, 40, 50, 63, 80, 100, 125, 160, 200, 250, 315, 400, 500,
        630, 800, 1000, 1250, 1600, 2000, 2500, 3150, 4000, 5000, 6300, 8000,
        10000, 12500, 16000, 20000
    ]

    /// Measures each standard RTA band using a real band-pass filter and RMS.
    public static func measure(from samples: [Float], sampleRate: Float) -> [RTAFrequencyBand] {
        guard !samples.isEmpty, sampleRate > 0 else { return [] }

        return standardBands.map { frequency in
            let center = min(max(frequency, 20), sampleRate * 0.45)
            var filter = Biquad()
            filter.setBandPass(sampleRate: sampleRate, frequency: center, q: 1.4)

            var sumSquares: Double = 0
            var left: Float = 0
            var right: Float = 0

            for sample in samples {
                left = sample
                right = sample
                filter.process(left: &left, right: &right)
                let value = Double(left)
                sumSquares += value * value
            }

            let rms = sqrt(sumSquares / Double(samples.count))
            let db = 20 * log10(max(rms, 1.0e-8))
            return RTAFrequencyBand(frequency: frequency, levelDB: Float(db))
        }
    }
}
