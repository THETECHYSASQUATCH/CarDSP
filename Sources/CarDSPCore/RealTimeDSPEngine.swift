import Foundation

/// Real-time stereo DSP engine.
///
/// The processing path keeps filter and dynamics state between buffers. The
/// configuration lock is only held while a buffer is processed, so a
/// configuration update cannot race the audio state. Callers should still
/// avoid calling `setConfiguration` from an audio render callback.
public final class RealTimeDSPEngine: @unchecked Sendable {
    private let lock = NSLock()
    private var configuration = DSPConfiguration()
    private var filters: [Biquad] = []
    private var hp = Biquad()
    private var lp = Biquad()
    private var subsonic = Biquad()
    private var leftDelayBuffer: [Float] = Array(repeating: 0, count: 4096)
    private var rightDelayBuffer: [Float] = Array(repeating: 0, count: 4096)
    private var leftDelayWriteIndex = 0
    private var rightDelayWriteIndex = 0
    private var leftCompressorGain: Float = 1
    private var rightCompressorGain: Float = 1

    public init(configuration: DSPConfiguration = DSPConfiguration()) {
        self.configuration = configuration
        rebuildFilters(resetState: true)
    }

    /// Updates coefficients and resets filter/dynamics state at a safe point.
    public func setConfiguration(_ configuration: DSPConfiguration) {
        lock.lock()
        self.configuration = configuration
        rebuildFilters(resetState: true)
        lock.unlock()
    }

    public func currentConfiguration() -> DSPConfiguration {
        lock.lock()
        defer { lock.unlock() }
        return configuration
    }

    private func rebuildFilters(resetState: Bool) {
        filters = configuration.eq.map { band in
            var filter = Biquad()
            filter.setPeakingEQ(
                sampleRate: configuration.sampleRate,
                frequency: min(max(band.frequency, 10), configuration.sampleRate * 0.45),
                q: band.q,
                gainDB: band.gainDB
            )
            return filter
        }

        hp = Biquad()
        hp.setHighPass(
            sampleRate: configuration.sampleRate,
            frequency: min(max(configuration.highPassHz, 10), configuration.sampleRate * 0.45)
        )

        subsonic = Biquad()
        subsonic.setHighPass(
            sampleRate: configuration.sampleRate,
            frequency: min(max(configuration.subsonicHz, 10), configuration.sampleRate * 0.45)
        )

        lp = Biquad()
        lp.setLowPass(
            sampleRate: configuration.sampleRate,
            frequency: min(max(configuration.lowPassHz, 20), configuration.sampleRate * 0.45)
        )

        if resetState {
            filters.forEach { _ in }
            hp.reset()
            subsonic.reset()
            lp.reset()
            leftCompressorGain = 1
            rightCompressorGain = 1
            leftDelayBuffer.withUnsafeMutableBufferPointer { $0.initialize(repeating: 0) }
            rightDelayBuffer.withUnsafeMutableBufferPointer { $0.initialize(repeating: 0) }
            leftDelayWriteIndex = 0
            rightDelayWriteIndex = 0
        }
    }

    /// Processes interleaved stereo Float32 samples in-place.
    /// The caller must provide at least `frameCount * 2` samples.
    public func processInterleavedStereo(_ samples: UnsafeMutablePointer<Float>, frameCount: Int) {
        guard frameCount > 0 else { return }
        lock.lock()
        defer { lock.unlock() }

        let c = configuration
        let linearGain = powf(10, c.masterGainDB / 20)

        for frame in 0..<frameCount {
            let index = frame * 2
            var left = timeAlignedSample(samples[index], channel: 0, configuration: c) * linearGain
            var right = timeAlignedSample(samples[index + 1], channel: 1, configuration: c) * linearGain

            if c.polarityInverted {
                left = -left
                right = -right
            }

            hp.process(left: &left, right: &right)
            if c.subsonicHz > 10 {
                subsonic.process(left: &left, right: &right)
            }

            for index in filters.indices {
                filters[index].process(left: &left, right: &right)
            }

            left = applyCompressor(left, channel: 0, configuration: c)
            right = applyCompressor(right, channel: 1, configuration: c)

            if c.limiterEnabled {
                let threshold = powf(10, c.limiterThresholdDB / 20)
                left = softLimit(left, threshold)
                right = softLimit(right, threshold)
            }

            samples[index] = left
            samples[index + 1] = right
        }
    }

    /// Processes the stereo signal through the subwoofer crossover path.
    public func processSubwooferInterleavedStereo(_ samples: UnsafeMutablePointer<Float>, frameCount: Int) {
        guard frameCount > 0 else { return }
        lock.lock()
        defer { lock.unlock() }

        let c = configuration
        let linearGain = powf(10, c.masterGainDB / 20)
        let threshold = powf(10, c.limiterThresholdDB / 20)

        for frame in 0..<frameCount {
            let index = frame * 2
            var left = timeAlignedSample(samples[index], channel: 0, configuration: c) * linearGain
            var right = timeAlignedSample(samples[index + 1], channel: 1, configuration: c) * linearGain

            if c.polarityInverted {
                left = -left
                right = -right
            }

            subsonic.process(left: &left, right: &right)
            lp.process(left: &left, right: &right)
            left = applyCompressor(left, channel: 0, configuration: c)
            right = applyCompressor(right, channel: 1, configuration: c)
            samples[index] = softLimit(left, threshold)
            samples[index + 1] = softLimit(right, threshold)
        }
    }

    private func timeAlignedSample(_ sample: Float, channel: Int, configuration: DSPConfiguration) -> Float {
        let requestedDelay = Int(round(configuration.timeAlignmentMs / 1000 * configuration.sampleRate))
        let delaySamples = min(max(0, requestedDelay), leftDelayBuffer.count - 1)
        guard delaySamples > 0 else { return sample }

        if channel == 0 {
            let readIndex = (leftDelayWriteIndex + leftDelayBuffer.count - delaySamples) % leftDelayBuffer.count
            let delayed = leftDelayBuffer[readIndex]
            leftDelayBuffer[leftDelayWriteIndex] = sample
            leftDelayWriteIndex = (leftDelayWriteIndex + 1) % leftDelayBuffer.count
            return delayed
        }

        let readIndex = (rightDelayWriteIndex + rightDelayBuffer.count - delaySamples) % rightDelayBuffer.count
        let delayed = rightDelayBuffer[readIndex]
        rightDelayBuffer[rightDelayWriteIndex] = sample
        rightDelayWriteIndex = (rightDelayWriteIndex + 1) % rightDelayBuffer.count
        return delayed
    }

    private func applyCompressor(_ value: Float, channel: Int, configuration: DSPConfiguration) -> Float {
        let threshold = powf(10, configuration.compressorThresholdDB / 20)
        let ratio = max(configuration.compressorRatio, 1)
        let amplitude = abs(value)
        let attack = expf(-1 / max(configuration.sampleRate * configuration.compressorAttackSeconds, 1))
        let release = expf(-1 / max(configuration.sampleRate * configuration.compressorReleaseSeconds, 1))

        let desiredGain: Float
        if amplitude <= threshold {
            desiredGain = 1
        } else {
            let reduced = threshold + ((amplitude - threshold) / ratio)
            desiredGain = reduced / max(amplitude, 0.0001)
        }

        if channel == 0 {
            let previous = leftCompressorGain
            leftCompressorGain = amplitude > threshold
                ? previous * attack + desiredGain * (1 - attack)
                : previous * release + desiredGain * (1 - release)
            return value * leftCompressorGain
        }

        let previous = rightCompressorGain
        rightCompressorGain = amplitude > threshold
            ? previous * attack + desiredGain * (1 - attack)
            : previous * release + desiredGain * (1 - release)
        return value * rightCompressorGain
    }

    private func softLimit(_ x: Float, _ threshold: Float) -> Float {
        guard threshold > 0 else { return tanhf(x) }
        let sign: Float = x < 0 ? -1 : 1
        let amplitude = abs(x)
        guard amplitude > threshold else { return x }
        let excess = amplitude - threshold
        return sign * (threshold + tanhf(excess) * (1 - threshold))
    }
}
