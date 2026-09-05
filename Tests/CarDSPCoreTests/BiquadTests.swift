
import XCTest
@testable import CarDSPCore

final class BiquadTests: XCTestCase {
    func testFlatPeakingEQDoesNotChangeDCState() {
        var filter = Biquad()
        filter.setPeakingEQ(sampleRate: 48_000, frequency: 1000, q: 1, gainDB: 0)
        var l: Float = 0.25
        var r: Float = 0.25
        for _ in 0..<100 {
            filter.process(left: &l, right: &r)
        }
        XCTAssertEqual(l, 0.25, accuracy: 0.001)
        XCTAssertEqual(r, 0.25, accuracy: 0.001)
    }

    func testHighPassRejectsDCComponent() {
        var filter = Biquad()
        filter.setHighPass(sampleRate: 48_000, frequency: 1000, q: 0.7071)

        var left: Float = 1
        var right: Float = 1
        for _ in 0..<200 {
            filter.process(left: &left, right: &right)
        }

        XCTAssertLessThan(abs(left), 0.001, "high-pass should attenuate a DC input")
        XCTAssertLessThan(abs(right), 0.001, "high-pass should attenuate a DC input")
    }

    func testLowPassShapesHighFrequencyContent() {
        var filter = Biquad()
        filter.setLowPass(sampleRate: 48_000, frequency: 1000, q: 0.7071)

        var left: Float = 1
        var right: Float = 1
        for _ in 0..<50 {
            filter.process(left: &left, right: &right)
        }

        XCTAssertLessThan(abs(left), 1.0, "low-pass should attenuate a full-scale input over time")
        XCTAssertLessThan(abs(right), 1.0, "low-pass should attenuate a full-scale input over time")
    }
}
