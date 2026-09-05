
import Foundation

public struct EQBand: Codable, Sendable {
    public var frequency: Float
    public var gainDB: Float
    public var q: Float

    public init(frequency: Float, gainDB: Float = 0, q: Float = 1.0) {
        self.frequency = frequency
        self.gainDB = gainDB
        self.q = q
    }
}

public struct DSPConfiguration: Codable, Sendable {
    public var sampleRate: Float = 48_000
    public var eq: [EQBand]
    public var highPassHz: Float = 20
    public var subsonicHz: Float = 20
    public var lowPassHz: Float = 90
    public var masterGainDB: Float = 0
    public var limiterThresholdDB: Float = -1
    public var limiterEnabled: Bool = true

    public init() {
        let frequencies: [Float] = [
            20,25,31.5,40,50,63,80,100,125,160,200,250,315,400,500,630,
            800,1000,1250,1600,2000,2500,3150,4000,5000,6300,8000,10000,
            12500,16000,20000
        ]
        eq = frequencies.map { EQBand(frequency: $0) }
    }

    public static func carBass() -> DSPConfiguration {
        var c = DSPConfiguration()
        let gains: [Float] = [4,4,4,4,3,3,3,2,1,1] + Array(repeating: Float(0), count: 21)
        for i in c.eq.indices { c.eq[i].gainDB = gains[i] }
        c.subsonicHz = 20
        c.lowPassHz = 90
        c.limiterThresholdDB = -1
        return c
    }
}
