import Foundation

public struct VehicleProfile: Codable, Sendable {
    public let name: String
    public let description: String
    public let highPassHz: Float
    public let subsonicHz: Float
    public let lowPassHz: Float
    public let masterGainDB: Float
    public let limiterThresholdDB: Float
    public let eq: [EQBand]

    public init(
        name: String,
        description: String,
        highPassHz: Float,
        subsonicHz: Float,
        lowPassHz: Float,
        masterGainDB: Float,
        limiterThresholdDB: Float,
        eq: [EQBand]
    ) {
        self.name = name
        self.description = description
        self.highPassHz = highPassHz
        self.subsonicHz = subsonicHz
        self.lowPassHz = lowPassHz
        self.masterGainDB = masterGainDB
        self.limiterThresholdDB = limiterThresholdDB
        self.eq = eq
    }

    public func apply(to configuration: inout DSPConfiguration) {
        configuration.highPassHz = highPassHz
        configuration.subsonicHz = subsonicHz
        configuration.lowPassHz = lowPassHz
        configuration.masterGainDB = masterGainDB
        configuration.limiterThresholdDB = limiterThresholdDB

        let eqCount = min(configuration.eq.count, eq.count)
        for index in 0..<eqCount {
            configuration.eq[index].gainDB = eq[index].gainDB
            configuration.eq[index].q = eq[index].q
        }
    }
}

public extension DSPConfiguration {
    func applying(_ profile: VehicleProfile) -> DSPConfiguration {
        var updated = self
        profile.apply(to: &updated)
        return updated
    }
}
