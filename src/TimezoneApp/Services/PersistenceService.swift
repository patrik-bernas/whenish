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
        guard let data = userDefaults.data(forKey: Keys.groups) else {
            let groups = [defaultGroup()]
            saveGroups(groups)
            return groups
        }

        guard let decodedGroups = try? decoder.decode([TimezoneGroup].self, from: data) else {
            return [defaultGroup()]
        }

        let groups = sanitizedGroups(decodedGroups)

        // Refresh flags from current mapping — fixes persisted wrong flags from earlier versions
        let refreshed = groups.map { group -> TimezoneGroup in
            var g = group
            g.cities = g.cities.map { city -> City in
                let correct = citySearchService.result(for: city.timeZoneIdentifier)
                var c = city
                c.flag = correct.flag
                c.countryCode = correct.countryCode
                return c
            }
            return g
        }
        if refreshed != groups {
            saveGroups(refreshed)
        }
        return refreshed
    }

    func saveSettings(_ settings: AppSettings) {
        guard let data = try? encoder.encode(settings) else {
            return
        }

        userDefaults.set(data, forKey: Keys.settings)
    }

    func loadSettings() -> AppSettings {
        guard let data = userDefaults.data(forKey: Keys.settings) else {
            let groups = loadGroups()
            let settings = AppSettings(
                use24HourFormat: true,
                homeTimeZoneIdentifier: groups.first?.cities.first?.timeZoneIdentifier,
                activeGroupId: groups.first?.id
            )
            saveSettings(settings)
            return settings
        }

        guard let settings = try? decoder.decode(AppSettings.self, from: data) else {
            let groups = loadGroups()
            return AppSettings(
                use24HourFormat: true,
                homeTimeZoneIdentifier: groups.first?.cities.first?.timeZoneIdentifier,
                activeGroupId: groups.first?.id
            )
        }

        return settings
    }

    private func defaultGroup() -> TimezoneGroup {
        TimezoneGroup(name: "Work", cities: [defaultHomeCity()])
    }

    private func sanitizedGroups(_ groups: [TimezoneGroup]) -> [TimezoneGroup] {
        let sanitized = Array(groups.prefix(5)).map { group -> TimezoneGroup in
            var sanitizedGroup = group
            sanitizedGroup.name = String(group.name.prefix(12))
            sanitizedGroup.cities = Array(group.cities.prefix(5))
            return sanitizedGroup
        }

        if sanitized.isEmpty {
            return [defaultGroup()]
        }

        return sanitized
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
