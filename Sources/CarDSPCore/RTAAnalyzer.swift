import Foundation

public struct RTAFrequencyBand {
    public let frequency: Float
    public let levelDB: Float

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

    public static func measure(from samples: [Float], sampleRate: Float) -> [RTAFrequencyBand] {
        guard !samples.isEmpty, sampleRate > 0 else { return [] }

        var bandLevels = Array(repeating: Float.leastNonzeroMagnitude, count: standardBands.count)
        var bandGains = Array(repeating: Float(0), count: standardBands.count)

        for sample in samples {
            var running = sample
            for index in standardBands.indices {
                var filter = Biquad()
                filter.setPeakingEQ(sampleRate: sampleRate,
                                    frequency: standardBands[index],
                                    q: 1.0,
                                    gainDB: 0)
                var left = running
                var right = running
                filter.process(left: &left, right: &right)
                let magnitude = abs(left)
                let smoothing: Float = 0.9
                bandGains[index] = max(bandGains[index] * smoothing, magnitude)
                bandLevels[index] = max(bandLevels[index], bandGains[index])
                running = left
            }
        }

        let dbValues = bandLevels.map { level in
            let amplitude = max(level, 1.0e-8)
            return 20 * log10(amplitude)
        }

        return zip(standardBands, dbValues).map { frequency, levelDB in
            RTAFrequencyBand(frequency: frequency, levelDB: levelDB)
        }
    }
}
