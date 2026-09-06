import Foundation

/// Real-time stereo DSP engine. Filter and dynamics state is retained between buffers.
public final class RealTimeDSPEngine: @unchecked Sendable {
    private let lock = NSLock()
    private var configuration = DSPConfiguration()
    private var filters: [Biquad] = []
    private var hp = Biquad(); private var lp = Biquad(); private var subsonic = Biquad()
    private var leftDelayBuffer = Array(repeating: Float.zero, count: 4096)
    private var rightDelayBuffer = Array(repeating: Float.zero, count: 4096)
    private var leftDelayWriteIndex = 0; private var rightDelayWriteIndex = 0
    private var leftCompressorGain: Float = 1; private var rightCompressorGain: Float = 1

    public init(configuration: DSPConfiguration = DSPConfiguration()) {
        self.configuration = configuration; rebuildFilters(resetState: true)
    }
    public func setConfiguration(_ configuration: DSPConfiguration) { lock.lock(); defer { lock.unlock() }; self.configuration = configuration; rebuildFilters(resetState: true) }
    public func currentConfiguration() -> DSPConfiguration { lock.lock(); defer { lock.unlock() }; return configuration }
    public func reset() { lock.lock(); defer { lock.unlock() }; resetState() }

    private func resetState() {
        hp.reset(); subsonic.reset(); lp.reset(); for i in filters.indices { filters[i].reset() }
        leftCompressorGain = 1; rightCompressorGain = 1
        for i in leftDelayBuffer.indices { leftDelayBuffer[i] = 0 }; for i in rightDelayBuffer.indices { rightDelayBuffer[i] = 0 }
        leftDelayWriteIndex = 0; rightDelayWriteIndex = 0
    }

    private func rebuildFilters(resetState: Bool) {
        filters = configuration.eq.map { band in
            var f = Biquad(); f.setPeakingEQ(sampleRate: configuration.sampleRate, frequency: min(max(band.frequency, 10), configuration.sampleRate * 0.45), q: max(band.q, 0.05), gainDB: band.gainDB); return f
        }
        hp = Biquad(); hp.setHighPass(sampleRate: configuration.sampleRate, frequency: min(max(configuration.highPassHz, 10), configuration.sampleRate * 0.45))
        subsonic = Biquad(); subsonic.setHighPass(sampleRate: configuration.sampleRate, frequency: min(max(configuration.subsonicHz, 10), configuration.sampleRate * 0.45))
        lp = Biquad(); lp.setLowPass(sampleRate: configuration.sampleRate, frequency: min(max(configuration.lowPassHz, 20), configuration.sampleRate * 0.45))
        if resetState { resetState() }
    }

    public func processInterleavedStereo(_ samples: UnsafeMutablePointer<Float>, frameCount: Int) {
        guard frameCount > 0 else { return }; lock.lock(); defer { lock.unlock() }
        processLocked(interleaved: samples, frameCount: frameCount)
    }

    /// Processes separate non-interleaved stereo channel buffers in-place.
    public func processNonInterleavedStereo(_ left: UnsafeMutablePointer<Float>, _ right: UnsafeMutablePointer<Float>, frameCount: Int) {
        guard frameCount > 0 else { return }; lock.lock(); defer { lock.unlock() }
        let c = configuration; let gain = powf(10, c.masterGainDB / 20); let threshold = powf(10, c.limiterThresholdDB / 20)
        for frame in 0..<frameCount {
            var l = timeAlignedSample(left[frame], channel: 0, configuration: c) * gain
            var r = timeAlignedSample(right[frame], channel: 1, configuration: c) * gain
            if c.polarityInverted { l = -l; r = -r }
            hp.process(left: &l, right: &r); if c.subsonicHz > 10 { subsonic.process(left: &l, right: &r) }
            for i in filters.indices { filters[i].process(left: &l, right: &r) }
            l = applyCompressor(l, channel: 0, configuration: c); r = applyCompressor(r, channel: 1, configuration: c)
            if c.limiterEnabled { l = softLimit(l, threshold); r = softLimit(r, threshold) }
            left[frame] = l; right[frame] = r
        }
    }

    private func processLocked(interleaved samples: UnsafeMutablePointer<Float>, frameCount: Int) {
        let c = configuration; let gain = powf(10, c.masterGainDB / 20); let threshold = powf(10, c.limiterThresholdDB / 20)
        for frame in 0..<frameCount {
            let i = frame * 2; var l = timeAlignedSample(samples[i], channel: 0, configuration: c) * gain; var r = timeAlignedSample(samples[i + 1], channel: 1, configuration: c) * gain
            if c.polarityInverted { l = -l; r = -r }; hp.process(left: &l, right: &r); if c.subsonicHz > 10 { subsonic.process(left: &l, right: &r) }
            for j in filters.indices { filters[j].process(left: &l, right: &r) }; l = applyCompressor(l, channel: 0, configuration: c); r = applyCompressor(r, channel: 1, configuration: c)
            if c.limiterEnabled { l = softLimit(l, threshold); r = softLimit(r, threshold) }; samples[i] = l; samples[i + 1] = r
        }
    }

    public func processSubwooferInterleavedStereo(_ samples: UnsafeMutablePointer<Float>, frameCount: Int) {
        guard frameCount > 0 else { return }; lock.lock(); defer { lock.unlock() }; let c = configuration; let gain = powf(10, c.masterGainDB / 20); let threshold = powf(10, c.limiterThresholdDB / 20)
        for frame in 0..<frameCount { let i = frame * 2; var l = timeAlignedSample(samples[i], channel: 0, configuration: c) * gain; var r = timeAlignedSample(samples[i + 1], channel: 1, configuration: c) * gain; if c.polarityInverted { l = -l; r = -r }; subsonic.process(left: &l, right: &r); lp.process(left: &l, right: &r); l = applyCompressor(l, channel: 0, configuration: c); r = applyCompressor(r, channel: 1, configuration: c); samples[i] = softLimit(l, threshold); samples[i + 1] = softLimit(r, threshold) }
    }

    private func timeAlignedSample(_ sample: Float, channel: Int, configuration: DSPConfiguration) -> Float {
        let requested = Int(round(configuration.timeAlignmentMs / 1000 * configuration.sampleRate)); let delay = min(max(0, requested), 4095); guard delay > 0 else { return sample }
        if channel == 0 { let read = (leftDelayWriteIndex + 4096 - delay) % 4096; let result = leftDelayBuffer[read]; leftDelayBuffer[leftDelayWriteIndex] = sample; leftDelayWriteIndex = (leftDelayWriteIndex + 1) % 4096; return result }
        let read = (rightDelayWriteIndex + 4096 - delay) % 4096; let result = rightDelayBuffer[read]; rightDelayBuffer[rightDelayWriteIndex] = sample; rightDelayWriteIndex = (rightDelayWriteIndex + 1) % 4096; return result
    }
    private func applyCompressor(_ value: Float, channel: Int, configuration: DSPConfiguration) -> Float {
        let threshold = powf(10, configuration.compressorThresholdDB / 20); let ratio = max(configuration.compressorRatio, 1); let amplitude = abs(value); let attack = expf(-1 / max(configuration.sampleRate * configuration.compressorAttackSeconds, 1)); let release = expf(-1 / max(configuration.sampleRate * configuration.compressorReleaseSeconds, 1)); let desired: Float = amplitude <= threshold ? 1 : (threshold + (amplitude - threshold) / ratio) / max(amplitude, 0.0001)
        if channel == 0 { leftCompressorGain = amplitude > threshold ? leftCompressorGain * attack + desired * (1 - attack) : leftCompressorGain * release + desired * (1 - release); return value * leftCompressorGain }
        rightCompressorGain = amplitude > threshold ? rightCompressorGain * attack + desired * (1 - attack) : rightCompressorGain * release + desired * (1 - release); return value * rightCompressorGain
    }
    private func softLimit(_ x: Float, _ threshold: Float) -> Float { guard threshold > 0 else { return tanhf(x) }; let sign: Float = x < 0 ? -1 : 1; let amplitude = abs(x); guard amplitude > threshold else { return x }; return sign * (threshold + tanhf(amplitude - threshold) * max(0, 1 - threshold)) }
}
