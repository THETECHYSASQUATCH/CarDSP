import XCTest
@testable import CarDSPCore

final class BiquadTests: XCTestCase {
    func testFlatPeakingEQDoesNotChangeDCState() {
        var filter = Biquad()
        filter.setPeakingEQ(sampleRate: 48_000, frequency: 1000, q: 1, gainDB: 0)
        var l: Float = 0.25
        var r: Float = 0.25
        for _ in 0..<100 { filter.process(left: &l, right: &r) }
        XCTAssertEqual(l, 0.25, accuracy: 0.001)
        XCTAssertEqual(r, 0.25, accuracy: 0.001)
    }

    func testHighPassRejectsDCComponent() {
        var filter = Biquad()
        filter.setHighPass(sampleRate: 48_000, frequency: 1000, q: 0.7071)
        var left: Float = 0
        var right: Float = 0
        for _ in 0..<200 {
            left = 1
            right = 1
            filter.process(left: &left, right: &right)
        }
        XCTAssertLessThan(abs(left), 0.001)
        XCTAssertLessThan(abs(right), 0.001)
    }

    func testLowPassShapesHighFrequencyContent() {
        var filter = Biquad()
        filter.setLowPass(sampleRate: 48_000, frequency: 1000, q: 0.7071)
        var left: Float = 1
        var right: Float = 1
        for _ in 0..<50 { filter.process(left: &left, right: &right) }
        XCTAssertLessThan(abs(left), 1.0)
        XCTAssertLessThan(abs(right), 1.0)
    }

    func testBandPassRejectsDC() {
        var filter = Biquad()
        filter.setBandPass(sampleRate: 48_000, frequency: 1000, q: 1.4)
        var left: Float = 0
        var right: Float = 0
        for _ in 0..<500 {
            left = 1
            right = 1
            filter.process(left: &left, right: &right)
        }
        XCTAssertLessThan(abs(left), 0.01)
        XCTAssertLessThan(abs(right), 0.01)
    }
}

final class RealTimeDSPEngineTests: XCTestCase {
    func testSourceRateSurvivesPresetChanges() {
        let engine = RealTimeDSPEngine()
        XCTAssertTrue(engine.prepare(sampleRate: 44_100))
        engine.setConfiguration(.bassBoost())
        XCTAssertEqual(engine.currentConfiguration().sampleRate, 44_100)
        XCTAssertFalse(engine.prepare(sampleRate: .nan))
        XCTAssertFalse(engine.prepare(sampleRate: 0))
        XCTAssertEqual(engine.currentConfiguration().sampleRate, 44_100)
    }

    func testPlanarPlaybackMatchesInterleavedDSP() {
        var config = DSPConfiguration.bassBoost()
        config.timeAlignmentMs = 2
        let interleavedEngine = RealTimeDSPEngine(configuration: config)
        let planarEngine = RealTimeDSPEngine(configuration: config)
        XCTAssertTrue(interleavedEngine.prepare(sampleRate: 44_100))
        XCTAssertTrue(planarEngine.prepare(sampleRate: 44_100))
        var left = (0..<1024).map { sinf(Float($0) * 0.13) * 0.2 }
        var right = Array(repeating: Float.zero, count: left.count)
        var interleaved = left.flatMap { [$0, Float.zero] }
        interleaved.withUnsafeMutableBufferPointer {
            interleavedEngine.processInterleavedStereo($0.baseAddress!, frameCount: 1024)
        }
        left.withUnsafeMutableBufferPointer { l in
            right.withUnsafeMutableBufferPointer { r in
                planarEngine.processNonInterleavedStereo(l.baseAddress!, r.baseAddress!, frameCount: 257)
                planarEngine.processNonInterleavedStereo(l.baseAddress!.advanced(by: 257), r.baseAddress!.advanced(by: 257), frameCount: 767)
            }
        }
        for index in left.indices {
            XCTAssertEqual(left[index], interleaved[index * 2], accuracy: 0.00001)
            XCTAssertEqual(right[index], 0)
        }
    }

    func testFilterStateContinuesAcrossBuffers() {
        var config = DSPConfiguration.flat()
        config.highPassHz = 10
        config.subsonicHz = 10
        config.lowPassHz = 20_000
        config.limiterEnabled = false
        config.compressorThresholdDB = 0
        config.compressorRatio = 1

        let oneBuffer = RealTimeDSPEngine(configuration: config)
        let splitBuffer = RealTimeDSPEngine(configuration: config)
        var continuous = Array(repeating: Float(0.25), count: 2048)
        var split = continuous

        continuous.withUnsafeMutableBufferPointer {
            oneBuffer.processInterleavedStereo($0.baseAddress!, frameCount: 1024)
        }
        split.withUnsafeMutableBufferPointer {
            splitBuffer.processInterleavedStereo($0.baseAddress!, frameCount: 512)
            splitBuffer.processInterleavedStereo($0.baseAddress!.advanced(by: 1024), frameCount: 512)
        }

        for index in 1024..<2048 {
            XCTAssertEqual(split[index], continuous[index], accuracy: 0.0001)
        }
    }
}

final class RTAAnalyzerTests: XCTestCase {
    func testRTAProducesAllStandardBands() {
        let samples = Array(repeating: Float(0.1), count: 2048)
        let bands = RTAAnalyzer.measure(from: samples, sampleRate: 48_000)
        XCTAssertEqual(bands.count, RTAAnalyzer.standardBands.count)
        XCTAssertEqual(bands.first?.frequency, 20)
        XCTAssertEqual(bands.last?.frequency, 20_000)
    }
}
