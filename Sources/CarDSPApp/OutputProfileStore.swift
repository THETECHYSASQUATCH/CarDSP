import Foundation
import Combine
import CarDSPCore

struct OutputDSPProfile: Codable, Identifiable, Sendable {
    var id: String { routeKey }
    let routeKey: String
    var name: String
    var configuration: DSPConfiguration
    var updatedAt: Date
}

@MainActor
final class OutputProfileStore: ObservableObject {
    @Published private(set) var profiles: [OutputDSPProfile] = []
    @Published var autoLoadEnabled: Bool {
        didSet { defaults.set(autoLoadEnabled, forKey: Self.autoLoadKey) }
    }

    private let defaults: UserDefaults
    private static let storageKey = "CarDSP.OutputProfiles"
    private static let autoLoadKey = "CarDSP.OutputProfiles.AutoLoad"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.autoLoadEnabled = defaults.object(forKey: Self.autoLoadKey) as? Bool ?? true
        loadFromDisk()
    }

    func profile(for routeKey: String) -> OutputDSPProfile? {
        profiles.first { $0.routeKey == routeKey }
    }

    func saveCurrent(configuration: DSPConfiguration, routeKey: String, name: String) {
        let profile = OutputDSPProfile(
            routeKey: routeKey,
            name: name,
            configuration: configuration,
            updatedAt: Date()
        )

        if let index = profiles.firstIndex(where: { $0.routeKey == routeKey }) {
            profiles[index] = profile
        } else {
            profiles.append(profile)
        }
        persist()
    }

    func delete(routeKey: String) {
        profiles.removeAll { $0.routeKey == routeKey }
        persist()
    }

    private func loadFromDisk() {
        guard
            let data = defaults.data(forKey: Self.storageKey),
            let decoded = try? JSONDecoder().decode([OutputDSPProfile].self, from: data)
        else { return }
        profiles = decoded
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(profiles) else { return }
        defaults.set(data, forKey: Self.storageKey)
    }
}
