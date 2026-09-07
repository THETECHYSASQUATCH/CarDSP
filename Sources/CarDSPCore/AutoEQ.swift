import Foundation

public enum EQTargetCurve: String, CaseIterable, Codable, Sendable {
    case flat = "Flat"
    case carSQ = "Car SQ"
    case bassLift = "Bass Lift"
    case warm = "Warm"
    case reference = "Reference"

    public func offsetDB(at frequency: Float) -> Float {
        switch self {
        case .flat:
            return 0
        case .carSQ:
            if frequency <= 40 { return 4.0 }
            if frequency <= 80 { return 3.0 }
            if frequency <= 160 { return 1.5 }
            if frequency >= 10_000 { return -1.5 }
            if frequency >= 5_000 { return -0.75 }
            return 0
        case .bassLift:
            if frequency <= 50 { return 6.0 }
            if frequency <= 100 { return 4.0 }
            if frequency <= 200 { return 2.0 }
            return 0
        case .warm:
            if frequency <= 80 { return 2.5 }
            if frequency <= 250 { return 1.5 }
            if frequency >= 8_000 { return -1.0 }
            return 0
        case .reference:
            if frequency <= 40 { return 2.0 }
            if frequency <= 100 { return 1.0 }
            if frequency >= 12_500 { return -1.0 }
            return 0
        }
    }
}

public enum AutoEQ {
    /// Returns a configuration with measured band errors corrected toward the target.
    /// The correction is deliberately conservative so microphone/room errors do not
    /// cause extreme boosts. This is measurement assistance, not a calibrated SPL EQ.
    public static func correctedConfiguration(
        base: DSPConfiguration,
        measured: [RTAFrequencyBand],
        targetDB: Float = -18,
        targetCurve: EQTargetCurve = .flat,
        maxCorrectionDB: Float = 6,
        smoothing: Float = 0.35
    ) -> DSPConfiguration {
        guard !measured.isEmpty else { return base }
        var result = base
        let clampedSmoothing = min(max(smoothing, 0), 1)

        for index in result.eq.indices {
            let frequency = result.eq[index].frequency
            guard let measurement = nearestBand(to: frequency, in: measured) else { continue }
            let desiredLevel = targetDB + targetCurve.offsetDB(at: frequency)
            let error = desiredLevel - measurement.levelDB
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
