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

    public static let kiaSportageLX = VehicleProfile(
        name: "2017 Kia Sportage LX",
        description: "Balanced cabin tuning with a warm bass shelf and smooth upper-mid control.",
        highPassHz: 20,
        subsonicHz: 20,
        lowPassHz: 90,
        masterGainDB: 0,
        limiterThresholdDB: -1,
        eq: [
            EQBand(frequency: 20, gainDB: 1), EQBand(frequency: 25, gainDB: 1), EQBand(frequency: 31.5, gainDB: 2),
            EQBand(frequency: 40, gainDB: 3), EQBand(frequency: 50, gainDB: 3), EQBand(frequency: 63, gainDB: 4),
            EQBand(frequency: 80, gainDB: 4), EQBand(frequency: 100, gainDB: 3), EQBand(frequency: 125, gainDB: 2),
            EQBand(frequency: 160, gainDB: 1), EQBand(frequency: 200, gainDB: 0), EQBand(frequency: 250, gainDB: 0),
            EQBand(frequency: 315, gainDB: 0), EQBand(frequency: 400, gainDB: 0), EQBand(frequency: 500, gainDB: 0),
            EQBand(frequency: 630, gainDB: 0), EQBand(frequency: 800, gainDB: 0), EQBand(frequency: 1000, gainDB: 0),
            EQBand(frequency: 1250, gainDB: 0), EQBand(frequency: 1600, gainDB: 0), EQBand(frequency: 2000, gainDB: 0),
            EQBand(frequency: 2500, gainDB: 0), EQBand(frequency: 3150, gainDB: 0), EQBand(frequency: 4000, gainDB: 0),
            EQBand(frequency: 5000, gainDB: 0), EQBand(frequency: 6300, gainDB: 0), EQBand(frequency: 8000, gainDB: 0),
            EQBand(frequency: 10000, gainDB: -1), EQBand(frequency: 12500, gainDB: -1), EQBand(frequency: 16000, gainDB: -2),
            EQBand(frequency: 20000, gainDB: -2)
        ]
    )

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
