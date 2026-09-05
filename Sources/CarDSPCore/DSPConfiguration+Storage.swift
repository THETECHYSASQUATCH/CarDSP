import Foundation

// Persistence helpers for DSPConfiguration using UserDefaults.
// Placed in CarDSPCore so both core and app targets can access it.

public extension DSPConfiguration {
    /// Load the saved configuration from UserDefaults, if present.
    static func load() -> DSPConfiguration? {
        guard let data = UserDefaults.standard.data(forKey: DSPConfiguration.storageKey) else { return nil }
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(DSPConfiguration.self, from: data)
        } catch {
            // If decoding fails, remove the corrupted data and fall back to defaults.
            UserDefaults.standard.removeObject(forKey: DSPConfiguration.storageKey)
            return nil
        }
    }

    /// Save the configuration to UserDefaults.
    func save() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(self)
            UserDefaults.standard.set(data, forKey: DSPConfiguration.storageKey)
        } catch {
            // Swallow errors — persistence is best-effort in this context.
            // Consider logging in debug builds if needed.
        }
    }
}
