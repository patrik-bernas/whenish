import Foundation

@MainActor
final class TimezoneViewModel: ObservableObject {
    static let shared = TimezoneViewModel()

    @Published var groups: [TimezoneGroup] {
        didSet { persistGroupsAndRefreshState() }
    }

    @Published var settings: AppSettings {
        didSet { persistSettingsAndRefreshState() }
    }

    @Published var activeGroupIndex: Int {
        didSet {
            guard groups.indices.contains(activeGroupIndex) else { return }
            settings.activeGroupId = groups[activeGroupIndex].id
            refreshStatusItemTitle()
        }
    }

    @Published var scrubberOffset: Double {
        didSet { refreshStatusItemTitle() }
    }

    @Published var searchQuery: String = "" {
        didSet { updateSearchResults() }
    }

    @Published private(set) var searchResults: [CitySearchResult] = []
    @Published var isSettingsOpen = false

    private let persistenceService: PersistenceService
    private let timezoneService: TimezoneService
    private let citySearchService: CitySearchService

    init(
        persistenceService: PersistenceService = PersistenceService(),
        timezoneService: TimezoneService = TimezoneService(),
        citySearchService: CitySearchService = CitySearchService()
    ) {
        self.persistenceService = persistenceService
        self.timezoneService = timezoneService
        self.citySearchService = citySearchService

        let loadedGroups = persistenceService.loadGroups()
        let loadedSettings = persistenceService.loadSettings()
        let initialIndex = loadedGroups.firstIndex { $0.id == loadedSettings.activeGroupId } ?? 0

        groups = loadedGroups
        settings = loadedSettings
        activeGroupIndex = initialIndex
        scrubberOffset = 0

        refreshStatusItemTitle()
    }

    var activeGroup: TimezoneGroup? {
        groups.indices.contains(activeGroupIndex) ? groups[activeGroupIndex] : nil
    }

    var menubarCities: [City] {
        (activeGroup?.cities ?? []).filter(\.showInMenubar)
    }

    var offsetLabel: String {
        guard scrubberOffset != 0 else { return "Now" }
        let sign = scrubberOffset > 0 ? "+" : ""
        let roundedOffset = Int(scrubberOffset.rounded())
        return "\(sign)\(roundedOffset)h from now"
    }

    var currentLocalTimeString: String {
        let date = timezoneService.currentTime(in: homeTimeZone, offsetHours: scrubberOffset)
        return timezoneService.formattedTime(date: date, use24Hour: settings.use24HourFormat)
    }

    var homeTimeZone: TimeZone {
        resolvedHomeTimeZone()
    }

    func addCity(_ result: CitySearchResult) {
        guard var group = activeGroup else { return }
        guard group.cities.count < 6 else { return }
        guard !group.cities.contains(where: { $0.timeZoneIdentifier == result.timeZoneIdentifier }) else { return }

        let city = City(
            name: result.cityName,
            countryCode: result.countryCode,
            flag: result.flag,
            timeZoneIdentifier: result.timeZoneIdentifier,
            isHome: result.timeZoneIdentifier == settings.homeTimeZoneIdentifier
        )

        group.cities.append(city)
        updateActiveGroup(group)
        searchQuery = ""
    }

    func removeCity(_ city: City) {
        guard var group = activeGroup else { return }
        group.cities.removeAll { $0.id == city.id }
        updateActiveGroup(group)
    }

    func toggleMenubar(for city: City) {
        guard var group = activeGroup,
              let index = group.cities.firstIndex(where: { $0.id == city.id }) else { return }

        group.cities[index].showInMenubar.toggle()
        updateActiveGroup(group)
    }

    func switchGroup(to index: Int) {
        guard groups.indices.contains(index) else { return }
        activeGroupIndex = index
    }

    func setHomeTimezone(to identifier: String) {
        settings.homeTimeZoneIdentifier = identifier

        for groupIndex in groups.indices {
            for cityIndex in groups[groupIndex].cities.indices {
                groups[groupIndex].cities[cityIndex].isHome = groups[groupIndex].cities[cityIndex].timeZoneIdentifier == identifier
            }
        }
    }

    func renameGroup(at index: Int, to name: String) {
        guard groups.indices.contains(index) else { return }
        groups[index].name = String(name.prefix(12))
    }

    func timeZone(for city: City) -> TimeZone {
        TimeZone(identifier: city.timeZoneIdentifier) ?? .current
    }

    func displayedTime(for city: City) -> String {
        let date = timezoneService.currentTime(in: timeZone(for: city), offsetHours: scrubberOffset)
        return timezoneService.formattedTime(date: date, use24Hour: settings.use24HourFormat)
    }

    func displayedDayLabel(for city: City) -> String {
        let shiftedDate = timezoneService.currentTime(in: timeZone(for: city), offsetHours: scrubberOffset)
        let referenceDate = timezoneService.currentTime(in: timeZone(for: city), offsetHours: 0)
        return timezoneService.dayLabel(for: shiftedDate, relativeTo: referenceDate)
    }

    func relativeOffsetLabel(for city: City) -> String {
        guard let homeIdentifier = settings.homeTimeZoneIdentifier,
              let homeTimeZone = TimeZone(identifier: homeIdentifier) else {
            return city.isHome ? "You" : "Same"
        }

        return city.isHome ? "You" : timezoneService.offsetLabel(from: homeTimeZone, to: timeZone(for: city))
    }

    func resetScrubber() {
        scrubberOffset = 0
    }

    func refreshMenubarTitle() {
        refreshStatusItemTitle()
    }

    private func updateSearchResults() {
        searchResults = citySearchService.search(query: searchQuery)
    }

    private func updateActiveGroup(_ group: TimezoneGroup) {
        guard groups.indices.contains(activeGroupIndex) else { return }
        groups[activeGroupIndex] = group
    }

    private func persistGroupsAndRefreshState() {
        persistenceService.saveGroups(groups)
        if groups.indices.contains(activeGroupIndex) {
            settings.activeGroupId = groups[activeGroupIndex].id
        }
        refreshStatusItemTitle()
    }

    private func persistSettingsAndRefreshState() {
        persistenceService.saveSettings(settings)
        refreshStatusItemTitle()
    }

    private func refreshStatusItemTitle() {
        let title = menubarCities
            .prefix(4)
            .map { city in
                let date = timezoneService.currentTime(
                    in: TimeZone(identifier: city.timeZoneIdentifier) ?? .current,
                    offsetHours: scrubberOffset
                )
                let time = timezoneService.formattedTime(date: date, use24Hour: settings.use24HourFormat)
                return "\(abbreviation(for: city.name)) \(time)"
            }
            .joined(separator: " · ")

        AppDelegate.shared?.updateStatusItem(title: title)
    }

    private func abbreviation(for cityName: String) -> String {
        let customAbbreviations: [String: String] = [
            "Seoul": "SEL",
            "Bali": "BAL",
            "Amsterdam": "AMS",
            "San Francisco": "SFO",
            "London": "LON",
            "Tokyo": "TYO",
            "Sydney": "SYD",
            "New York": "NYC"
        ]

        if let custom = customAbbreviations[cityName] {
            return custom
        }

        let cleaned = cityName.replacingOccurrences(of: " ", with: "")
        return String(cleaned.prefix(3)).uppercased()
    }

    private func resolvedHomeTimeZone() -> TimeZone {
        if let identifier = settings.homeTimeZoneIdentifier,
           let timeZone = TimeZone(identifier: identifier) {
            return timeZone
        }

        return TimeZone.current
    }
}
