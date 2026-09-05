
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
    private var leftDelayBuffer: [Float] = Array(repeating: 0, count: 4096)
    private var rightDelayBuffer: [Float] = Array(repeating: 0, count: 4096)
    private var leftDelayWriteIndex: Int = 0
    private var rightDelayWriteIndex: Int = 0
    private var leftCompressorGain: Float = 1
    private var rightCompressorGain: Float = 1

    private struct ProcessingState {
        let configuration: DSPConfiguration
        let filters: [Biquad]
        let hp: Biquad
        let lp: Biquad
        let subsonic: Biquad
    }

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

    private func processingState() -> ProcessingState {
        lock.lock(); defer { lock.unlock() }
        return ProcessingState(
            configuration: configuration,
            filters: filters,
            hp: hp,
            lp: lp,
            subsonic: subsonic
        )
    }

    /// Processes interleaved stereo Float32 samples in-place.
    /// Use this from a real-time render callback with a preallocated buffer.
    public func processInterleavedStereo(_ samples: UnsafeMutablePointer<Float>, frameCount: Int) {
        let state = processingState()
        var filters = state.filters
        var hp = state.hp
        var subsonic = state.subsonic
        let c = state.configuration
        let linearGain = powf(10, c.masterGainDB / 20)

        for frame in 0..<frameCount {
            let inputL = samples[frame * 2]
            let inputR = samples[frame * 2 + 1]

            var l = timeAlignedSample(inputL, channel: 0, configuration: c) * linearGain
            var r = timeAlignedSample(inputR, channel: 1, configuration: c) * linearGain

            if c.polarityInverted {
                l = -l
                r = -r
            }

            hp.process(left: &l, right: &r)
            if c.subsonicHz > 10 { subsonic.process(left: &l, right: &r) }

            for i in filters.indices {
                filters[i].process(left: &l, right: &r)
            }

            l = applyCompressor(l, channel: 0, configuration: c)
            r = applyCompressor(r, channel: 1, configuration: c)

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
        let state = processingState()
        var subsonic = state.subsonic
        var lp = state.lp
        let c = state.configuration
        let linearGain = powf(10, c.masterGainDB / 20)

        for frame in 0..<frameCount {
            let inputL = samples[frame * 2]
            let inputR = samples[frame * 2 + 1]

            var l = timeAlignedSample(inputL, channel: 0, configuration: c) * linearGain
            var r = timeAlignedSample(inputR, channel: 1, configuration: c) * linearGain

            if c.polarityInverted {
                l = -l
                r = -r
            }

            subsonic.process(left: &l, right: &r)
            lp.process(left: &l, right: &r)
            l = applyCompressor(l, channel: 0, configuration: c)
            r = applyCompressor(r, channel: 1, configuration: c)
            let threshold = powf(10, c.limiterThresholdDB / 20)
            samples[frame * 2] = softLimit(l, threshold)
            samples[frame * 2 + 1] = softLimit(r, threshold)
        }
    }

    private func timeAlignedSample(_ sample: Float, channel: Int, configuration: DSPConfiguration) -> Float {
        let delaySamples = max(0, Int(round(configuration.timeAlignmentMs / 1000 * configuration.sampleRate)))
        guard delaySamples > 0 else { return sample }

        if channel == 0 {
            let readIndex = (leftDelayWriteIndex + leftDelayBuffer.count - delaySamples) % leftDelayBuffer.count
            let delayed = leftDelayBuffer[readIndex]
            leftDelayBuffer[leftDelayWriteIndex] = sample
            leftDelayWriteIndex = (leftDelayWriteIndex + 1) % leftDelayBuffer.count
            return delayed
        } else {
            let readIndex = (rightDelayWriteIndex + rightDelayBuffer.count - delaySamples) % rightDelayBuffer.count
            let delayed = rightDelayBuffer[readIndex]
            rightDelayBuffer[rightDelayWriteIndex] = sample
            rightDelayWriteIndex = (rightDelayWriteIndex + 1) % rightDelayBuffer.count
            return delayed
        }
    }

    private func applyCompressor(_ value: Float, channel: Int, configuration: DSPConfiguration) -> Float {
        let threshold = powf(10, configuration.compressorThresholdDB / 20)
        let ratio = max(configuration.compressorRatio, 1.0)
        let amplitude = abs(value)
        let attack = expf(-1 / max(configuration.sampleRate * configuration.compressorAttackSeconds, 1))
        let release = expf(-1 / max(configuration.sampleRate * configuration.compressorReleaseSeconds, 1))

        let desiredGain: Float
        if amplitude <= threshold {
            desiredGain = 1
        } else {
            let excess = amplitude - threshold
            let reduced = threshold + (excess / ratio)
            desiredGain = reduced / max(amplitude, 0.0001)
        }

        var previousGain: Float
        if channel == 0 {
            previousGain = leftCompressorGain
            leftCompressorGain = amplitude > threshold ? previousGain * attack + desiredGain * (1 - attack)
                : previousGain * release + desiredGain * (1 - release)
            return value * leftCompressorGain
        } else {
            previousGain = rightCompressorGain
            rightCompressorGain = amplitude > threshold ? previousGain * attack + desiredGain * (1 - attack)
                : previousGain * release + desiredGain * (1 - release)
            return value * rightCompressorGain
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
