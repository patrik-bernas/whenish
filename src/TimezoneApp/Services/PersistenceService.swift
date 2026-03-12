import Foundation

struct PersistenceService {
    private enum Keys {
        static let groups = "timezone.groups"
        static let settings = "timezone.settings"
    }

    private let userDefaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func saveGroups(_ groups: [TimezoneGroup]) {
        guard let data = try? encoder.encode(groups) else {
            return
        }

        userDefaults.set(data, forKey: Keys.groups)
    }

    func loadGroups() -> [TimezoneGroup] {
        guard
            let data = userDefaults.data(forKey: Keys.groups),
            let groups = try? decoder.decode([TimezoneGroup].self, from: data),
            !groups.isEmpty
        else {
            let groups = [defaultGroup()]
            saveGroups(groups)
            return groups
        }

        return groups
    }

    func saveSettings(_ settings: AppSettings) {
        guard let data = try? encoder.encode(settings) else {
            return
        }

        userDefaults.set(data, forKey: Keys.settings)
    }

    func loadSettings() -> AppSettings {
        guard
            let data = userDefaults.data(forKey: Keys.settings),
            let settings = try? decoder.decode(AppSettings.self, from: data)
        else {
            let groups = loadGroups()
            let settings = AppSettings(
                use24HourFormat: true,
                homeTimeZoneIdentifier: groups.first?.cities.first?.timeZoneIdentifier,
                activeGroupId: groups.first?.id
            )
            saveSettings(settings)
            return settings
        }

        return settings
    }

    private func defaultGroup() -> TimezoneGroup {
        TimezoneGroup(name: "Work", cities: [defaultHomeCity()])
    }

    private func defaultHomeCity() -> City {
        let identifier = TimeZone.current.identifier
        let components = identifier.split(separator: "/")
        let fallbackName = components.last?
            .replacingOccurrences(of: "_", with: " ") ?? identifier
        let countryCode = components.first.map(String.init)?.prefix(2).uppercased() ?? "UN"

        return City(
            name: fallbackName,
            countryCode: countryCode,
            flag: flagEmoji(for: String(countryCode)),
            timeZoneIdentifier: identifier,
            isHome: true,
            showInMenubar: true
        )
    }

    private func flagEmoji(for countryCode: String) -> String {
        let scalars = countryCode.uppercased().unicodeScalars.compactMap { scalar -> UnicodeScalar? in
            guard let base = UnicodeScalar(127397 + scalar.value) else {
                return nil
            }
            return base
        }

        return scalars.isEmpty ? "🌍" : String(String.UnicodeScalarView(scalars))
    }
}
