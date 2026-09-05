
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
    public var timeAlignmentMs: Float = 0
    public var polarityInverted: Bool = false
    public var compressorThresholdDB: Float = -6
    public var compressorRatio: Float = 3.0
    public var compressorAttackSeconds: Float = 0.01
    public var compressorReleaseSeconds: Float = 0.12

    public static let storageKey = "CarDSP.Configuration"

    public init() {
        let frequencies: [Float] = [
            20,25,31.5,40,50,63,80,100,125,160,200,250,315,400,500,630,
            800,1000,1250,1600,2000,2500,3150,4000,5000,6300,8000,10000,
            12500,16000,20000
        ]
        eq = frequencies.map { EQBand(frequency: $0) }
    }

    public static func flat() -> DSPConfiguration {
        DSPConfiguration()
    }

    public static func bassBoost() -> DSPConfiguration {
        var c = DSPConfiguration()
        let gains: [Float] = [2,2,3,3,4,4,4,3,2,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
        for i in c.eq.indices { c.eq[i].gainDB = gains.indices.contains(i) ? gains[i] : 0 }
        c.subsonicHz = 18
        c.lowPassHz = 100
        c.masterGainDB = 1
        c.limiterThresholdDB = -2
        return c
    }

    public static func trebleBoost() -> DSPConfiguration {
        var c = DSPConfiguration()
        let gains: [Float] = Array(repeating: Float(0), count: 10) + [0,0,0,0,0,0,0,0,1,2,2,3,3,3,4,4,4,4,4,4,4,3,3,2] + Array(repeating: Float(0), count: 6)
        for i in c.eq.indices { c.eq[i].gainDB = i < gains.count ? gains[i] : 0 }
        c.highPassHz = 25
        c.masterGainDB = 1.5
        c.limiterThresholdDB = -1
        return c
    }

    public static func vocal() -> DSPConfiguration {
        var c = DSPConfiguration()
        let gains: [Float] = Array(repeating: Float(0), count: 14) + [2,3,2,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
        for i in c.eq.indices { c.eq[i].gainDB = i < gains.count ? gains[i] : 0 }
        c.highPassHz = 25
        c.subsonicHz = 20
        c.limiterThresholdDB = -1.5
        return c
    }

    public static func rock() -> DSPConfiguration {
        var c = DSPConfiguration()
        let gains: [Float] = [2,2,3,3,3,2,2,1,1,0,0,0,0,0,0,0,1,2,2,2,3,3,4,4,3,2,1,0,0,0,0]
        for i in c.eq.indices { c.eq[i].gainDB = i < gains.count ? gains[i] : 0 }
        c.subsonicHz = 20
        c.lowPassHz = 110
        c.limiterThresholdDB = -1.5
        return c
    }

    public func save(to userDefaults: UserDefaults = .standard) {
        guard let encoded = try? JSONEncoder().encode(self) else { return }
        userDefaults.set(encoded, forKey: Self.storageKey)
    }

    public static func load(from userDefaults: UserDefaults = .standard) -> DSPConfiguration? {
        guard let data = userDefaults.data(forKey: Self.storageKey) else { return nil }
        return try? JSONDecoder().decode(DSPConfiguration.self, from: data)
    }
}
