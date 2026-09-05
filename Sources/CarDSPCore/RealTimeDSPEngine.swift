
import Foundation

/// Real-time stereo DSP engine. Audio callbacks should avoid allocation and locks.
/// The engine is intentionally independent of SwiftUI so it can later back an
/// Audio Unit / AVAudioEngine render callback.
public final class RealTimeDSPEngine: @unchecked Sendable {
    private let lock = NSLock()
    private var configuration = DSPConfiguration()
    private var filters: [Biquad] = []
    private var hp = Biquad()
    private var lp = Biquad()
    private var subsonic = Biquad()

    public init(configuration: DSPConfiguration = DSPConfiguration()) {
        self.configuration = configuration
        rebuildFilters()
    }

    public func setConfiguration(_ configuration: DSPConfiguration) {
        lock.lock()
        self.configuration = configuration
        rebuildFilters()
        lock.unlock()
    }

    public func currentConfiguration() -> DSPConfiguration {
        lock.lock(); defer { lock.unlock() }
        return configuration
    }

    private func rebuildFilters() {
        filters = configuration.eq.map { band in
            var f = Biquad()
            f.setPeakingEQ(
                sampleRate: configuration.sampleRate,
                frequency: min(max(band.frequency, 10), configuration.sampleRate * 0.45),
                q: band.q,
                gainDB: band.gainDB
            )
            return f
        }

        hp = Biquad()
        hp.setHighPass(sampleRate: configuration.sampleRate,
                       frequency: min(max(configuration.highPassHz, 10), 1000))

        subsonic = Biquad()
        subsonic.setHighPass(sampleRate: configuration.sampleRate,
                             frequency: min(max(configuration.subsonicHz, 10), 1000))

        lp = Biquad()
        lp.setLowPass(sampleRate: configuration.sampleRate,
                      frequency: min(max(configuration.lowPassHz, 20), configuration.sampleRate * 0.45))
    }

    /// Processes interleaved stereo Float32 samples in-place.
    /// Use this from a real-time render callback with a preallocated buffer.
    public func processInterleavedStereo(_ samples: UnsafeMutablePointer<Float>, frameCount: Int) {
        let c = currentConfiguration()
        let linearGain = powf(10, c.masterGainDB / 20)

        for frame in 0..<frameCount {
            var l = samples[frame * 2] * linearGain
            var r = samples[frame * 2 + 1] * linearGain

            hp.process(left: &l, right: &r)
            if c.subsonicHz > 10 { subsonic.process(left: &l, right: &r) }

            for i in filters.indices {
                filters[i].process(left: &l, right: &r)
            }

            // Full-range output stage. The dedicated sub LPF is exposed for
            // routing a subwoofer bus; don't apply it to the main stereo bus.
            if c.limiterEnabled {
                let threshold = powf(10, c.limiterThresholdDB / 20)
                l = softLimit(l, threshold)
                r = softLimit(r, threshold)
            }

            samples[frame * 2] = l
            samples[frame * 2 + 1] = r
        }
    }

    public func processSubwooferInterleavedStereo(_ samples: UnsafeMutablePointer<Float>, frameCount: Int) {
        let c = currentConfiguration()
        let linearGain = powf(10, c.masterGainDB / 20)

        for frame in 0..<frameCount {
            var l = samples[frame * 2] * linearGain
            var r = samples[frame * 2 + 1] * linearGain
            subsonic.process(left: &l, right: &r)
            lp.process(left: &l, right: &r)
            samples[frame * 2] = softLimit(l, powf(10, c.limiterThresholdDB / 20))
            samples[frame * 2 + 1] = softLimit(r, powf(10, c.limiterThresholdDB / 20))
        }
    }

    private func softLimit(_ x: Float, _ threshold: Float) -> Float {
        guard threshold > 0 else { return tanhf(x) }
        let sign: Float = x < 0 ? -1 : 1
        let a = abs(x)
        if a <= threshold { return x }
        let excess = a - threshold
        return sign * (threshold + tanhf(excess) * (1 - threshold))
    }
}
