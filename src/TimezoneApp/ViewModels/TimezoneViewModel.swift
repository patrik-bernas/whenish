import Combine
import Foundation

@MainActor
final class TimezoneViewModel: ObservableObject {
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
    @Published private(set) var currentDate: Date = Date()

    private let persistenceService: PersistenceService
    private let timezoneService: TimezoneService
    private let citySearchService: CitySearchService

    private var groupsPersistTask: Task<Void, Never>?
    private var settingsPersistTask: Task<Void, Never>?
    private var clockTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    // Cache sorted active group to avoid re-sorting on every access
    private var cachedActiveGroupIndex: Int = -1
    private var cachedActiveGroupSource: TimezoneGroup?
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
        startClockUpdates()
        refreshStatusItemTitle()
    }

    deinit {
        groupsPersistTask?.cancel()
        settingsPersistTask?.cancel()
        clockTask?.cancel()
    }

    // MARK: - Computed properties

    var activeGroup: TimezoneGroup? {
        guard groups.indices.contains(activeGroupIndex) else { return nil }
        let group = groups[activeGroupIndex]

        // Return cached sorted version if the group hasn't changed
        if activeGroupIndex == cachedActiveGroupIndex,
           let cachedSource = cachedActiveGroupSource,
           let cached = cachedSortedGroup,
           cachedSource == group {
            return cached
        }

        var sorted = group
        sorted.cities.sort { city1, city2 in
            let tz1 = TimeZone(identifier: city1.timeZoneIdentifier) ?? .current
            let tz2 = TimeZone(identifier: city2.timeZoneIdentifier) ?? .current
            return tz1.secondsFromGMT() < tz2.secondsFromGMT()
        }
        cachedActiveGroupIndex = activeGroupIndex
        cachedActiveGroupSource = group
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

    var currentLocalTimeParts: TimezoneService.TimeParts {
        timezoneService.formattedTimeParts(date: currentDate, use24Hour: settings.use24HourFormat)
    }

    var homeTimeZone: TimeZone {
        resolvedHomeTimeZone()
    }

    // MARK: - Actions

    func addCity(_ result: CitySearchResult) {
        guard groups.indices.contains(activeGroupIndex) else { return }
        let group = groups[activeGroupIndex]
        guard group.cities.count < 5 else { return }
        guard !group.cities.contains(where: { $0.timeZoneIdentifier == result.timeZoneIdentifier }) else { return }

        let city = City(
            name: result.cityName,
            countryCode: result.countryCode,
            flag: result.flag,
            timeZoneIdentifier: result.timeZoneIdentifier,
            isHome: result.timeZoneIdentifier == settings.homeTimeZoneIdentifier
        )

        groups[activeGroupIndex].cities.append(city)
        searchQuery = ""
    }

    func removeCity(_ city: City) {
        guard groups.indices.contains(activeGroupIndex) else { return }
        groups[activeGroupIndex].cities.removeAll { $0.id == city.id }
        if city.isHome {
            assignFallbackHomeTimezone()
        }
    }

    func toggleMenubar(for city: City) {
        guard groups.indices.contains(activeGroupIndex),
              let index = groups[activeGroupIndex].cities.firstIndex(where: { $0.id == city.id }) else { return }
        groups[activeGroupIndex].cities[index].showInMenubar.toggle()
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
        if let homeIdentifier = settings.homeTimeZoneIdentifier,
           !containsCity(withTimeZoneIdentifier: homeIdentifier) {
            assignFallbackHomeTimezone()
        }
    }

    func timeZone(for city: City) -> TimeZone {
        TimeZone(identifier: city.timeZoneIdentifier) ?? .current
    }

    func displayedTimeParts(for city: City) -> TimezoneService.TimeParts {
        let date = timezoneService.currentTime(from: currentDate, in: timeZone(for: city), offsetHours: scrubberOffset)
        return timezoneService.formattedTimeParts(date: date, use24Hour: settings.use24HourFormat)
    }

    func displayedDayLabelParts(for city: City) -> TimezoneService.DayLabelParts {
        let shiftedDate = timezoneService.currentTime(from: currentDate, in: timeZone(for: city), offsetHours: scrubberOffset)
        let referenceDate = timezoneService.currentTime(from: currentDate, in: timeZone(for: city), offsetHours: 0)
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

    private func startClockUpdates() {
        clockTask?.cancel()
        clockTask = Task { @MainActor [weak self] in
            guard let self else { return }
            self.currentDate = Date()

            while !Task.isCancelled {
                let now = Date()
                let nextMinute = Calendar.current.dateInterval(of: .minute, for: now)?.end ?? now.addingTimeInterval(60)
                let delay = max(nextMinute.timeIntervalSince(now), 0.1)
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                guard !Task.isCancelled else { return }
                self.currentDate = Date()
            }
        }
    }

    /// Debounce groups persistence — coalesce rapid mutations (e.g. drag, rename typing)
    private func scheduleGroupsPersist() {
        cachedSortedGroup = nil // Invalidate cache
        cachedActiveGroupSource = nil

        groupsPersistTask?.cancel()
        groupsPersistTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3s
            guard !Task.isCancelled, let self else { return }
            self.persistenceService.saveGroups(self.groups)
            if self.groups.indices.contains(self.activeGroupIndex) {
                self.settings.activeGroupId = self.groups[self.activeGroupIndex].id
            }
            self.refreshStatusItemTitle()
        }
    }

    /// Debounce settings persistence
    private func scheduleSettingsPersist() {
        settingsPersistTask?.cancel()
        settingsPersistTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3s
            guard !Task.isCancelled, let self else { return }
            self.persistenceService.saveSettings(self.settings)
            self.refreshStatusItemTitle()
        }
    }

    private func refreshStatusItemTitle() {
        let now = Date()
        let cities = menubarCities

        let timeFormatter = DateFormatter()
        timeFormatter.locale = Locale(identifier: "en_US_POSIX")
        timeFormatter.dateFormat = settings.use24HourFormat ? "HH:mm" : "h:mm a"

        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "EEE, MMM d"

        let title = cities
            .map { city -> String in
                timeFormatter.timeZone = TimeZone(identifier: city.timeZoneIdentifier) ?? .current
                let time = timeFormatter.string(from: now)
                return "\(abbreviation(for: city.name)) \(time)"
            }
            .joined(separator: " · ")

        // Build tooltip with middle dot separators
        let tooltipText = cities.map { city -> String in
            let tz = TimeZone(identifier: city.timeZoneIdentifier) ?? .current
            timeFormatter.timeZone = tz
            dateFormatter.timeZone = tz
            let time = timeFormatter.string(from: now)
            let date = dateFormatter.string(from: now)
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

    private func assignFallbackHomeTimezone() {
        if let fallbackCity = groups.lazy.flatMap(\.cities).first {
            setHomeTimezone(to: fallbackCity.timeZoneIdentifier)
            return
        }

        settings.homeTimeZoneIdentifier = TimeZone.current.identifier
    }

    private func containsCity(withTimeZoneIdentifier identifier: String) -> Bool {
        groups.contains { group in
            group.cities.contains { $0.timeZoneIdentifier == identifier }
        }
    }
}
