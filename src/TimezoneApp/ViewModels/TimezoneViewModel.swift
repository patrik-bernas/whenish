import Combine
import Foundation

@MainActor
final class TimezoneViewModel: ObservableObject {
    static let shared = TimezoneViewModel()

    @Published var groups: [TimezoneGroup] {
        didSet { scheduleGroupsPersist() }
    }

    @Published var settings: AppSettings {
        didSet { scheduleSettingsPersist() }
    }

    @Published var activeGroupIndex: Int {
        didSet {
            guard groups.indices.contains(activeGroupIndex) else { return }
            settings.activeGroupId = groups[activeGroupIndex].id
            refreshStatusItemTitle()
        }
    }

    @Published var scrubberOffset: Double = 0

    @Published var searchQuery: String = ""

    @Published private(set) var searchResults: [CitySearchResult] = []

    private let persistenceService: PersistenceService
    private let timezoneService: TimezoneService
    private let citySearchService: CitySearchService

    private var groupsPersistWorkItem: DispatchWorkItem?
    private var settingsPersistWorkItem: DispatchWorkItem?
    private var searchDebounceWorkItem: DispatchWorkItem?
    private var cancellables = Set<AnyCancellable>()

    // Cache sorted active group to avoid re-sorting on every access
    private var cachedActiveGroupIndex: Int = -1
    private var cachedSortedGroup: TimezoneGroup?

    init(
        persistenceService: PersistenceService? = nil,
        timezoneService: TimezoneService = TimezoneService(),
        citySearchService: CitySearchService = CitySearchService()
    ) {
        self.citySearchService = citySearchService
        self.persistenceService = persistenceService ?? PersistenceService(citySearchService: citySearchService)
        self.timezoneService = timezoneService

        let loadedGroups = self.persistenceService.loadGroups()
        let loadedSettings = self.persistenceService.loadSettings()
        let initialIndex = loadedGroups.firstIndex { $0.id == loadedSettings.activeGroupId } ?? 0

        groups = loadedGroups
        settings = loadedSettings
        activeGroupIndex = initialIndex

        setupBindings()
        refreshStatusItemTitle()
    }

    // MARK: - Computed properties

    var activeGroup: TimezoneGroup? {
        guard groups.indices.contains(activeGroupIndex) else { return nil }
        let group = groups[activeGroupIndex]

        // Return cached sorted version if the group hasn't changed
        if activeGroupIndex == cachedActiveGroupIndex, let cached = cachedSortedGroup, cached.id == group.id, cached.cities.count == group.cities.count {
            return cached
        }

        var sorted = group
        sorted.cities.sort { city1, city2 in
            let tz1 = TimeZone(identifier: city1.timeZoneIdentifier) ?? .current
            let tz2 = TimeZone(identifier: city2.timeZoneIdentifier) ?? .current
            return tz1.secondsFromGMT() < tz2.secondsFromGMT()
        }
        cachedActiveGroupIndex = activeGroupIndex
        cachedSortedGroup = sorted
        return sorted
    }

    var menubarCities: [City] {
        var seen = Set<String>()
        var result = [City]()
        for group in groups {
            for city in group.cities where city.showInMenubar {
                if !seen.contains(city.timeZoneIdentifier) {
                    seen.insert(city.timeZoneIdentifier)
                    result.append(city)
                }
            }
        }
        return Array(result.prefix(4))
    }

    var offsetLabel: String {
        guard scrubberOffset != 0 else { return "Now" }
        let sign = scrubberOffset > 0 ? "+" : ""
        let roundedOffset = Int(scrubberOffset.rounded())
        return "\(sign)\(roundedOffset)h from now"
    }

    var currentLocalTimeString: String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = settings.use24HourFormat ? "HH:mm" : "h:mm a"
        let result = formatter.string(from: Date())
        print("[TimezoneApp] currentLocalTimeString — system TZ: \(TimeZone.current.identifier), home TZ: \(homeTimeZone.identifier), Date(): \(Date()), formatted: \(result)")
        return result
    }

    var currentLocalTimeParts: TimezoneService.TimeParts {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        if settings.use24HourFormat {
            formatter.dateFormat = "HH:mm"
            let result = formatter.string(from: Date())
            print("[TimezoneApp] currentLocalTimeParts — system TZ: \(TimeZone.current.identifier), formatted: \(result)")
            return TimezoneService.TimeParts(digits: result, period: nil)
        } else {
            formatter.dateFormat = "h:mm"
            let digits = formatter.string(from: Date())
            formatter.dateFormat = "a"
            let period = formatter.string(from: Date())
            print("[TimezoneApp] currentLocalTimeParts — system TZ: \(TimeZone.current.identifier), formatted: \(digits) \(period)")
            return TimezoneService.TimeParts(digits: digits, period: period)
        }
    }

    var homeTimeZone: TimeZone {
        resolvedHomeTimeZone()
    }

    // MARK: - Actions

    func addCity(_ result: CitySearchResult) {
        guard var group = activeGroup else { return }
        guard group.cities.count < 5 else { return }
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

    func setHomeCity(_ city: City) {
        setHomeTimezone(to: city.timeZoneIdentifier)
    }

    func renameGroup(at index: Int, to name: String) {
        guard groups.indices.contains(index) else { return }
        groups[index].name = String(name.prefix(12))
    }

    func addGroup() {
        guard groups.count < 5 else { return }
        let defaultName = "Group \(groups.count + 1)"
        let newGroup = TimezoneGroup(name: defaultName)
        groups.append(newGroup)
        activeGroupIndex = groups.count - 1
    }

    func deleteGroup(at index: Int) {
        guard groups.count > 1, groups.indices.contains(index) else { return }
        let wasActive = index == activeGroupIndex
        groups.remove(at: index)
        if wasActive || activeGroupIndex >= groups.count {
            activeGroupIndex = 0
        }
    }

    func timeZone(for city: City) -> TimeZone {
        TimeZone(identifier: city.timeZoneIdentifier) ?? .current
    }

    func displayedTime(for city: City) -> String {
        let date = timezoneService.currentTime(in: timeZone(for: city), offsetHours: scrubberOffset)
        return timezoneService.formattedTime(date: date, use24Hour: settings.use24HourFormat)
    }

    func displayedTimeParts(for city: City) -> TimezoneService.TimeParts {
        let date = timezoneService.currentTime(in: timeZone(for: city), offsetHours: scrubberOffset)
        return timezoneService.formattedTimeParts(date: date, use24Hour: settings.use24HourFormat)
    }

    func displayedDayLabel(for city: City) -> String {
        let shiftedDate = timezoneService.currentTime(in: timeZone(for: city), offsetHours: scrubberOffset)
        let referenceDate = timezoneService.currentTime(in: timeZone(for: city), offsetHours: 0)
        return timezoneService.dayLabel(for: shiftedDate, relativeTo: referenceDate)
    }

    func displayedDayLabelParts(for city: City) -> TimezoneService.DayLabelParts {
        let shiftedDate = timezoneService.currentTime(in: timeZone(for: city), offsetHours: scrubberOffset)
        let referenceDate = timezoneService.currentTime(in: timeZone(for: city), offsetHours: 0)
        return timezoneService.dayLabelParts(for: shiftedDate, relativeTo: referenceDate)
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

    func toggle24HourFormat() {
        settings.use24HourFormat.toggle()
    }

    func toggleColumnView() {
        settings.isColumnView.toggle()
    }

    func refreshMenubarTitle() {
        refreshStatusItemTitle()
    }

    // MARK: - Private

    private func setupBindings() {
        // Debounce search — 200ms after user stops typing
        $searchQuery
            .debounce(for: .milliseconds(200), scheduler: RunLoop.main)
            .sink { [weak self] query in
                self?.searchResults = self?.citySearchService.search(query: query) ?? []
            }
            .store(in: &cancellables)

        // Note: menubar always shows real current time — NOT affected by scrubber offset.
        // Scrubber only affects times shown inside the popover.
    }

    private func updateActiveGroup(_ group: TimezoneGroup) {
        guard groups.indices.contains(activeGroupIndex) else { return }
        groups[activeGroupIndex] = group
    }

    /// Debounce groups persistence — coalesce rapid mutations (e.g. drag, rename typing)
    private func scheduleGroupsPersist() {
        cachedSortedGroup = nil // Invalidate cache

        groupsPersistWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.persistenceService.saveGroups(self.groups)
            if self.groups.indices.contains(self.activeGroupIndex) {
                self.settings.activeGroupId = self.groups[self.activeGroupIndex].id
            }
            self.refreshStatusItemTitle()
        }
        groupsPersistWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: workItem)
    }

    /// Debounce settings persistence
    private func scheduleSettingsPersist() {
        settingsPersistWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.persistenceService.saveSettings(self.settings)
            self.refreshStatusItemTitle()
        }
        settingsPersistWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: workItem)
    }

    private func refreshStatusItemTitle() {
        let now = Date()
        let cities = menubarCities

        let title = cities
            .map { city -> String in
                let formatter = DateFormatter()
                formatter.timeZone = TimeZone(identifier: city.timeZoneIdentifier) ?? .current
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.dateFormat = settings.use24HourFormat ? "HH:mm" : "h:mm a"
                let time = formatter.string(from: now)
                return "\(abbreviation(for: city.name)) \(time)"
            }
            .joined(separator: " · ")

        // Build tooltip with middle dot separators
        let tooltipText = cities.map { city -> String in
            let formatter = DateFormatter()
            formatter.timeZone = TimeZone(identifier: city.timeZoneIdentifier) ?? .current
            formatter.locale = Locale(identifier: "en_US_POSIX")

            formatter.dateFormat = settings.use24HourFormat ? "HH:mm" : "h:mm a"
            let time = formatter.string(from: now)

            formatter.dateFormat = "EEE, MMM d"
            let date = formatter.string(from: now)

            return "\(city.name) · \(time) · \(date)"
        }.joined(separator: "\n")

        AppDelegate.shared?.updateStatusItem(title: title)
        AppDelegate.shared?.updateStatusItemTooltip(tooltip: tooltipText)
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
            "New York": "NYC",
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
