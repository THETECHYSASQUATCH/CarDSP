
import Foundation

public struct Biquad {
    public var b0: Float = 1, b1: Float = 0, b2: Float = 0
    public var a1: Float = 0, a2: Float = 0
    private var z1L: Float = 0, z2L: Float = 0
    private var z1R: Float = 0, z2R: Float = 0

    public init() {}

    public mutating func reset() {
        z1L = 0; z2L = 0; z1R = 0; z2R = 0
    }

    public mutating func process(left: inout Float, right: inout Float) {
        let xL = left
        let yL = b0 * xL + z1L
        z1L = b1 * xL - a1 * yL + z2L
        z2L = b2 * xL - a2 * yL
        left = yL

        let xR = right
        let yR = b0 * xR + z1R
        z1R = b1 * xR - a1 * yR + z2R
        z2R = b2 * xR - a2 * yR
        right = yR
    }

    public mutating func setPeakingEQ(sampleRate: Float, frequency: Float, q: Float, gainDB: Float) {
        let A = powf(10, gainDB / 40)
        let w0 = 2 * Float.pi * frequency / sampleRate
        let alpha = sinf(w0) / (2 * max(q, 0.05))
        let c = cosf(w0)

        let B0 = 1 + alpha * A
        let B1 = -2 * c
        let B2 = 1 - alpha * A
        let A0 = 1 + alpha / A
        let A1 = -2 * c
        let A2 = 1 - alpha / A

        b0 = B0 / A0; b1 = B1 / A0; b2 = B2 / A0
        a1 = A1 / A0; a2 = A2 / A0
    }

    public mutating func setLowPass(sampleRate: Float, frequency: Float, q: Float = 0.7071) {
        let w0 = 2 * Float.pi * frequency / sampleRate
        let alpha = sinf(w0) / (2 * max(q, 0.05))
        let c = cosf(w0)
        let B0 = (1 - c) / 2, B1 = 1 - c, B2 = (1 - c) / 2
        let A0 = 1 + alpha, A1 = -2 * c, A2 = 1 - alpha
        b0 = B0/A0; b1 = B1/A0; b2 = B2/A0
        a1 = A1/A0; a2 = A2/A0
    }

    public mutating func setHighPass(sampleRate: Float, frequency: Float, q: Float = 0.7071) {
        let w0 = 2 * Float.pi * frequency / sampleRate
        let alpha = sinf(w0) / (2 * max(q, 0.05))
        let c = cosf(w0)
        let B0 = (1 + c) / 2, B1 = -(1 + c), B2 = (1 + c) / 2
        let A0 = 1 + alpha, A1 = -2 * c, A2 = 1 - alpha
        b0 = B0/A0; b1 = B1/A0; b2 = B2/A0
        a1 = A1/A0; a2 = A2/A0
    }
}
