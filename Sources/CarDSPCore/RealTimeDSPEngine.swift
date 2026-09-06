import Foundation

/// Real-time stereo DSP engine. Filter and dynamics state is retained between buffers.
public final class RealTimeDSPEngine: @unchecked Sendable {
    private let lock = NSLock()
    private var configuration = DSPConfiguration()
    private var filters: [Biquad] = []
    private var hp = Biquad()
    private var lp = Biquad()
    private var subsonic = Biquad()
    private var leftDelayBuffer = Array(repeating: Float.zero, count: 4096)
    private var rightDelayBuffer = Array(repeating: Float.zero, count: 4096)
    private var leftDelayWriteIndex = 0
    private var rightDelayWriteIndex = 0
    private var leftCompressorGain: Float = 1
    private var rightCompressorGain: Float = 1

    public init(configuration: DSPConfiguration = DSPConfiguration()) {
        self.configuration = configuration
        rebuildFilters(resetState: true)
    }

    public func setConfiguration(_ configuration: DSPConfiguration) {
        lock.lock(); defer { lock.unlock() }
        self.configuration = configuration
        rebuildFilters(resetState: true)
    }

    public func currentConfiguration() -> DSPConfiguration {
        lock.lock(); defer { lock.unlock() }
        return configuration
    }

    public func reset() {
        lock.lock(); defer { lock.unlock() }
        resetState()
    }

    private func resetState() {
        hp.reset(); subsonic.reset(); lp.reset()
        for index in filters.indices { filters[index].reset() }
        leftCompressorGain = 1
        rightCompressorGain = 1
        for index in leftDelayBuffer.indices { leftDelayBuffer[index] = 0 }
        for index in rightDelayBuffer.indices { rightDelayBuffer[index] = 0 }
        leftDelayWriteIndex = 0
        rightDelayWriteIndex = 0
    }

    private func rebuildFilters(resetState: Bool) {
        filters = configuration.eq.map { band in
            var filter = Biquad()
            filter.setPeakingEQ(sampleRate: configuration.sampleRate,
                                 frequency: min(max(band.frequency, 10), configuration.sampleRate * 0.45),
                                 q: max(band.q, 0.05),
                                 gainDB: band.gainDB)
            return filter
        }
        hp = Biquad()
        hp.setHighPass(sampleRate: configuration.sampleRate,
                       frequency: min(max(configuration.highPassHz, 10), configuration.sampleRate * 0.45))
        subsonic = Biquad()
        subsonic.setHighPass(sampleRate: configuration.sampleRate,
                             frequency: min(max(configuration.subsonicHz, 10), configuration.sampleRate * 0.45))
        lp = Biquad()
        lp.setLowPass(sampleRate: configuration.sampleRate,
                      frequency: min(max(configuration.lowPassHz, 20), configuration.sampleRate * 0.45))
        if resetState { resetState() }
    }

    public func processInterleavedStereo(_ samples: UnsafeMutablePointer<Float>, frameCount: Int) {
        guard frameCount > 0 else { return }
        lock.lock(); defer { lock.unlock() }
        let c = configuration
        let linearGain = powf(10, c.masterGainDB / 20)
        let limiterThreshold = powf(10, c.limiterThresholdDB / 20)
        for frame in 0..<frameCount {
            let index = frame * 2
            var left = timeAlignedSample(samples[index], channel: 0, configuration: c) * linearGain
            var right = timeAlignedSample(samples[index + 1], channel: 1, configuration: c) * linearGain
            if c.polarityInverted { left = -left; right = -right }
            hp.process(left: &left, right: &right)
            if c.subsonicHz > 10 { subsonic.process(left: &left, right: &right) }
            for filterIndex in filters.indices { filters[filterIndex].process(left: &left, right: &right) }
            left = applyCompressor(left, channel: 0, configuration: c)
            right = applyCompressor(right, channel: 1, configuration: c)
            if c.limiterEnabled {
                left = softLimit(left, limiterThreshold)
                right = softLimit(right, limiterThreshold)
            }
            samples[index] = left
            samples[index + 1] = right
        }
    }

    public func processSubwooferInterleavedStereo(_ samples: UnsafeMutablePointer<Float>, frameCount: Int) {
        guard frameCount > 0 else { return }
        lock.lock(); defer { lock.unlock() }
        let c = configuration
        let linearGain = powf(10, c.masterGainDB / 20)
        let limiterThreshold = powf(10, c.limiterThresholdDB / 20)
        for frame in 0..<frameCount {
            let index = frame * 2
            var left = timeAlignedSample(samples[index], channel: 0, configuration: c) * linearGain
            var right = timeAlignedSample(samples[index + 1], channel: 1, configuration: c) * linearGain
            if c.polarityInverted { left = -left; right = -right }
            subsonic.process(left: &left, right: &right)
            lp.process(left: &left, right: &right)
            left = applyCompressor(left, channel: 0, configuration: c)
            right = applyCompressor(right, channel: 1, configuration: c)
            samples[index] = softLimit(left, limiterThreshold)
            samples[index + 1] = softLimit(right, limiterThreshold)
        }
    }

    private func timeAlignedSample(_ sample: Float, channel: Int, configuration: DSPConfiguration) -> Float {
        let requested = Int(round(configuration.timeAlignmentMs / 1000 * configuration.sampleRate))
        let delay = min(max(0, requested), leftDelayBuffer.count - 1)
        guard delay > 0 else { return sample }
        if channel == 0 {
            let read = (leftDelayWriteIndex + leftDelayBuffer.count - delay) % leftDelayBuffer.count
            let result = leftDelayBuffer[read]
            leftDelayBuffer[leftDelayWriteIndex] = sample
            leftDelayWriteIndex = (leftDelayWriteIndex + 1) % leftDelayBuffer.count
            return result
        }
        let read = (rightDelayWriteIndex + rightDelayBuffer.count - delay) % rightDelayBuffer.count
        let result = rightDelayBuffer[read]
        rightDelayBuffer[rightDelayWriteIndex] = sample
        rightDelayWriteIndex = (rightDelayWriteIndex + 1) % rightDelayBuffer.count
        return result
    }

    private func applyCompressor(_ value: Float, channel: Int, configuration: DSPConfiguration) -> Float {
        let threshold = powf(10, configuration.compressorThresholdDB / 20)
        let ratio = max(configuration.compressorRatio, 1)
        let amplitude = abs(value)
        let attack = expf(-1 / max(configuration.sampleRate * configuration.compressorAttackSeconds, 1))
        let release = expf(-1 / max(configuration.sampleRate * configuration.compressorReleaseSeconds, 1))
        let desiredGain: Float = amplitude <= threshold ? 1 : (threshold + (amplitude - threshold) / ratio) / max(amplitude, 0.0001)
        if channel == 0 {
            leftCompressorGain = amplitude > threshold ? leftCompressorGain * attack + desiredGain * (1 - attack) : leftCompressorGain * release + desiredGain * (1 - release)
            return value * leftCompressorGain
        }
        rightCompressorGain = amplitude > threshold ? rightCompressorGain * attack + desiredGain * (1 - attack) : rightCompressorGain * release + desiredGain * (1 - release)
        return value * rightCompressorGain
    }

    private func softLimit(_ x: Float, _ threshold: Float) -> Float {
        guard threshold > 0 else { return tanhf(x) }
        let sign: Float = x < 0 ? -1 : 1
        let amplitude = abs(x)
        guard amplitude > threshold else { return x }
        return sign * (threshold + tanhf(amplitude - threshold) * max(0, 1 - threshold))
    }
}
