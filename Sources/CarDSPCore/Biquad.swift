import Foundation

public struct Biquad: Sendable {
    private var b0: Float = 1, b1: Float = 0, b2: Float = 0
    private var a1: Float = 0, a2: Float = 0
    private var x1L: Float = 0, x2L: Float = 0, y1L: Float = 0, y2L: Float = 0
    private var x1R: Float = 0, x2R: Float = 0, y1R: Float = 0, y2R: Float = 0

    public init() {}

    public mutating func reset() {
        x1L = 0; x2L = 0; y1L = 0; y2L = 0
        x1R = 0; x2R = 0; y1R = 0; y2R = 0
    }

    public mutating func process(left: inout Float, right: inout Float) {
        let inL = left
        let outL = b0 * inL + b1 * x1L + b2 * x2L - a1 * y1L - a2 * y2L
        x2L = x1L; x1L = inL; y2L = y1L; y1L = outL; left = outL
        let inR = right
        let outR = b0 * inR + b1 * x1R + b2 * x2R - a1 * y1R - a2 * y2R
        x2R = x1R; x1R = inR; y2R = y1R; y1R = outR; right = outR
    }

    public mutating func setPeakingEQ(sampleRate: Float, frequency: Float, q: Float, gainDB: Float) {
        let A = powf(10, gainDB / 40); let w0 = 2 * Float.pi * frequency / sampleRate; let c = cosf(w0); let s = sinf(w0)
        let alpha = s / (2 * max(q, 0.05)); let B0 = 1 + alpha * A; let B1 = -2 * c; let B2 = 1 - alpha * A
        let A0 = 1 + alpha / A; let A1 = -2 * c; let A2 = 1 - alpha / A
        b0 = B0 / A0; b1 = B1 / A0; b2 = B2 / A0; a1 = A1 / A0; a2 = A2 / A0; reset()
    }

    public mutating func setHighPass(sampleRate: Float, frequency: Float, q: Float = 0.7071) {
        let w0 = 2 * Float.pi * frequency / sampleRate; let c = cosf(w0); let s = sinf(w0); let alpha = s / (2 * max(q, 0.05))
        let B0 = (1 + c) / 2; let B1 = -(1 + c); let B2 = (1 + c) / 2; let A0 = 1 + alpha; let A1 = -2 * c; let A2 = 1 - alpha
        b0 = B0 / A0; b1 = B1 / A0; b2 = B2 / A0; a1 = A1 / A0; a2 = A2 / A0; reset()
    }

    public mutating func setLowPass(sampleRate: Float, frequency: Float, q: Float = 0.7071) {
        let w0 = 2 * Float.pi * frequency / sampleRate; let c = cosf(w0); let s = sinf(w0); let alpha = s / (2 * max(q, 0.05))
        let B0 = (1 - c) / 2; let B1 = 1 - c; let B2 = (1 - c) / 2; let A0 = 1 + alpha; let A1 = -2 * c; let A2 = 1 - alpha
        b0 = B0 / A0; b1 = B1 / A0; b2 = B2 / A0; a1 = A1 / A0; a2 = A2 / A0; reset()
    }

    public mutating func setBandPass(sampleRate: Float, frequency: Float, q: Float = 1.0) {
        let w0 = 2 * Float.pi * frequency / sampleRate; let alpha = sinf(w0) / (2 * max(q, 0.05)); let c = cosf(w0)
        let A0 = 1 + alpha; let B0 = alpha; let B1: Float = 0; let B2 = -alpha; let A1 = -2 * c; let A2 = 1 - alpha
        b0 = B0 / A0; b1 = B1 / A0; b2 = B2 / A0; a1 = A1 / A0; a2 = A2 / A0; reset()
    }
}
