import Foundation

struct PersistenceService {
    private enum Keys {
        static let groups = "timezone.groups"
        static let settings = "timezone.settings"
    }

    private let userDefaults: UserDefaults
    private let citySearchService: CitySearchService
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(
        userDefaults: UserDefaults = .standard,
        citySearchService: CitySearchService = CitySearchService()
    ) {
        self.userDefaults = userDefaults
        self.citySearchService = citySearchService
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
        let result = citySearchService.result(for: identifier)

        return City(
            name: result.cityName,
            countryCode: result.countryCode,
            flag: result.flag,
            timeZoneIdentifier: identifier,
            isHome: true,
            showInMenubar: true
        )
    }
}
