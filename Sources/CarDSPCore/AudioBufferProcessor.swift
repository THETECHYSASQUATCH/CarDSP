import Foundation

public final class AudioBufferProcessor: @unchecked Sendable {
    private let engine: RealTimeDSPEngine

    public init(engine: RealTimeDSPEngine) {
        self.engine = engine
    }

    /// Processes interleaved Float32 stereo samples in-place.
    /// Intended for an Audio Unit render callback; no heap allocation occurs here.
    public func process(_ samples: UnsafeMutablePointer<Float>, frameCount: Int) {
        engine.processInterleavedStereo(samples, frameCount: frameCount)
    }

    public func processSubwoofer(_ samples: UnsafeMutablePointer<Float>, frameCount: Int) {
        engine.processSubwooferInterleavedStereo(samples, frameCount: frameCount)
    }
}
