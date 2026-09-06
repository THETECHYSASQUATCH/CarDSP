import Foundation

public struct CarAudioProfile: Codable, Sendable, Identifiable {
    public let id: String
    public let vehicle: String
    public let radio: String
    public let frontSpeakers: String
    public let rearSpeakers: String
    public let lineOutputConverter: String
    public let amplifier: String
    public let subwoofers: String
    public let defaultConfiguration: DSPConfiguration

    public init(
        id: String,
        vehicle: String,
        radio: String,
        frontSpeakers: String,
        rearSpeakers: String,
        lineOutputConverter: String,
        amplifier: String,
        subwoofers: String,
        defaultConfiguration: DSPConfiguration
    ) {
        self.id = id
        self.vehicle = vehicle
        self.radio = radio
        self.frontSpeakers = frontSpeakers
        self.rearSpeakers = rearSpeakers
        self.lineOutputConverter = lineOutputConverter
        self.amplifier = amplifier
        self.subwoofers = subwoofers
        self.defaultConfiguration = defaultConfiguration
    }

    public static let kiaSportage2017: CarAudioProfile = {
        var config = DSPConfiguration.flat()
        config.highPassHz = 20
        config.subsonicHz = 20
        config.lowPassHz = 90
        config.masterGainDB = 0
        config.limiterEnabled = true
        config.limiterThresholdDB = -1
        return CarAudioProfile(
            id: "kia-sportage-2017-lx-awd",
            vehicle: "2017 Kia Sportage LX AWD",
            radio: "Factory radio",
            frontSpeakers: "Factory door speakers",
            rearSpeakers: "Factory door speakers",
            lineOutputConverter: "Scosche SLC-4 or Metra LLC1",
            amplifier: "Power Acoustik RZR1-2500D",
            subwoofers: "2 × Sony XS-L124P5 12-inch",
            defaultConfiguration: config
        )
    }()
}
