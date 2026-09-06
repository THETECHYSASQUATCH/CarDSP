import Foundation

public enum AutoEQ {
    /// Returns a configuration with measured band errors corrected toward the target.
    /// The correction is deliberately conservative so microphone/room errors do not
    /// cause extreme boosts. This is measurement assistance, not a calibrated SPL EQ.
    public static func correctedConfiguration(
        base: DSPConfiguration,
        measured: [RTAFrequencyBand],
        targetDB: Float = -18,
        maxCorrectionDB: Float = 6,
        smoothing: Float = 0.35
    ) -> DSPConfiguration {
        guard !measured.isEmpty else { return base }
        var result = base
        let clampedSmoothing = min(max(smoothing, 0), 1)

        for index in result.eq.indices {
            let frequency = result.eq[index].frequency
            guard let measurement = nearestBand(to: frequency, in: measured) else { continue }
            let error = targetDB - measurement.levelDB
            let correction = min(max(error * clampedSmoothing, -maxCorrectionDB), maxCorrectionDB)
            result.eq[index].gainDB = min(max(result.eq[index].gainDB + correction, -12), 12)
        }

        // Reduce overall gain when the EQ contains positive boosts.
        let maxBoost = result.eq.map(\.gainDB).max() ?? 0
        if maxBoost > 0 {
            result.masterGainDB = min(result.masterGainDB, -min(maxBoost * 0.5, 3))
        }
        return result
    }

    private static func nearestBand(to frequency: Float, in bands: [RTAFrequencyBand]) -> RTAFrequencyBand? {
        bands.min { abs($0.frequency - frequency) < abs($1.frequency - frequency) }
    }
}
