import Foundation

public struct LinearCongruentialRNG: RandomNumberGenerator {
    private var state: UInt64

    public init(seed: UInt64 = 0x9E3779B97F4A7C15) {
        self.state = seed == 0 ? 0x9E3779B97F4A7C15 : seed
    }

    public mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}

public enum SignalGenerator {
    public static func sineWave(frequency: Float, sampleRate: Float, phase: inout Float) -> Float {
        let phaseStep = 2 * Float.pi * frequency / sampleRate
        let sample = sinf(phase)
        phase = phase + phaseStep
        if phase >= 2 * Float.pi {
            phase = phase - 2 * Float.pi
        }
        return sample
    }

    public static func pinkNoise(using generator: inout LinearCongruentialRNG) -> Float {
        let nextSample: Float = {
            let raw = UInt32(generator.next() & 0xFFFF)
            return Float(Int(raw) - 32768) / 32768.0
        }()

        let b0 = 0.99886 * nextSample
        let b1 = 0.055517 * Float(Int(UInt32(generator.next() & 0xFFFF)) - 32768) / 32768.0
        let b2 = 0.056554 * Float(Int(UInt32(generator.next() & 0xFFFF)) - 32768) / 32768.0
        let b3 = -0.31531 * Float(Int(UInt32(generator.next() & 0xFFFF)) - 32768) / 32768.0
        let b4 = -0.010631 * Float(Int(UInt32(generator.next() & 0xFFFF)) - 32768) / 32768.0
        let output = b0 + b1 + b2 + b3 + b4
        return max(-1, min(1, output))
    }

    public static func sineSweep(startHz: Float, endHz: Float, durationSeconds: Float, elapsed: Float) -> Float {
        let t = min(max(elapsed, 0), durationSeconds)
        let divisor = max(durationSeconds, 0.0001)
        let frequency = startHz * powf(endHz / max(startHz, 0.0001), t / divisor)
        let samplePhase = 2 * Float.pi * frequency * t
        return sinf(samplePhase)
    }
}
