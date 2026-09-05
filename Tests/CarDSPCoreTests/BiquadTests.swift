
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
}
