import Foundation

struct CitySearchResult: Identifiable, Equatable {
    let timeZoneIdentifier: String
    let cityName: String
    let countryName: String
    let countryCode: String
    let flag: String
    let aliases: [String]

    var id: String { "\(timeZoneIdentifier)|\(countryCode)|\(cityName)" }

    init(timeZoneIdentifier: String, cityName: String, countryName: String, countryCode: String, flag: String, aliases: [String] = []) {
        self.timeZoneIdentifier = timeZoneIdentifier
        self.cityName = cityName
        self.countryName = countryName
        self.countryCode = countryCode
        self.flag = flag
        self.aliases = aliases
    }
}

private struct CityEntry: Decodable {
    let name: String
    let country: String
    let countryCode: String
    let timezoneId: String
    let aliases: [String]
}

struct CitySearchService {
    /// Full dataset loaded once from cities.json + IANA fallbacks
    private let allCities: [CitySearchResult]
    /// Keyed by timezone identifier for fast lookup
    private let byTimezone: [String: CitySearchResult]

    init() {
        let loaded = Self.loadCitiesJSON()
        self.allCities = loaded
        self.byTimezone = Self.buildTimezoneLookup(from: loaded)
    }

    func search(query: String) -> [CitySearchResult] {
        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        guard !normalizedQuery.isEmpty else {
            return Array(allCities.prefix(20))
        }

        let queryTokens = normalizedQuery.split(separator: " ").map(String.init)

        return allCities
            .filter { result in
                let haystack = ([
                    result.cityName,
                    result.countryName,
                ] + result.aliases)
                    .joined(separator: " ")
                    .lowercased()

                return queryTokens.allSatisfy { haystack.contains($0) }
            }
            .sorted { lhs, rhs in
                // Prefer exact prefix matches
                let lhsPrefix = lhs.cityName.lowercased().hasPrefix(normalizedQuery)
                let rhsPrefix = rhs.cityName.lowercased().hasPrefix(normalizedQuery)
                if lhsPrefix != rhsPrefix { return lhsPrefix }
                if lhs.cityName.caseInsensitiveCompare(rhs.cityName) == .orderedSame {
                    return lhs.countryName < rhs.countryName
                }
                return lhs.cityName < rhs.cityName
            }
    }

    func result(for identifier: String) -> CitySearchResult {
        byTimezone[identifier] ?? fallbackResult(for: identifier)
    }

    // MARK: - JSON Loading

    private static func loadCitiesJSON() -> [CitySearchResult] {
        guard let url = Bundle.main.url(forResource: "cities", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let entries = try? JSONDecoder().decode([CityEntry].self, from: data) else {
            // Fallback to IANA identifiers if JSON not found
            return TimeZone.knownTimeZoneIdentifiers.map { id in
                let components = id.split(separator: "/").map(String.init)
                let cityName = components.last?.replacingOccurrences(of: "_", with: " ") ?? id
                return CitySearchResult(
                    timeZoneIdentifier: id,
                    cityName: cityName,
                    countryName: components.first ?? "World",
                    countryCode: "UN",
                    flag: "🌍"
                )
            }
        }

        return entries.compactMap { entry -> CitySearchResult? in
            // Skip entries with invalid timezone identifiers
            guard TimeZone(identifier: entry.timezoneId) != nil else { return nil }
            return CitySearchResult(
                timeZoneIdentifier: entry.timezoneId,
                cityName: entry.name,
                countryName: entry.country,
                countryCode: entry.countryCode,
                flag: flagEmoji(for: entry.countryCode),
                aliases: entry.aliases
            )
        }
        .sorted { lhs, rhs in
            if lhs.cityName.caseInsensitiveCompare(rhs.cityName) == .orderedSame {
                return lhs.countryName < rhs.countryName
            }
            return lhs.cityName < rhs.cityName
        }
    }

    private static func buildTimezoneLookup(from cities: [CitySearchResult]) -> [String: CitySearchResult] {
        var lookup: [String: CitySearchResult] = [:]

        for city in cities {
            guard let current = lookup[city.timeZoneIdentifier] else {
                lookup[city.timeZoneIdentifier] = city
                continue
            }

            if isBetterRepresentative(city, than: current) {
                lookup[city.timeZoneIdentifier] = city
            }
        }

        return lookup
    }

    private static func isBetterRepresentative(_ candidate: CitySearchResult, than current: CitySearchResult) -> Bool {
        let timezoneCityName = normalizedTimezoneCityName(for: candidate.timeZoneIdentifier)
        let candidateName = normalizedSearchTerm(candidate.cityName)
        let currentName = normalizedSearchTerm(current.cityName)

        if candidateName == timezoneCityName && currentName != timezoneCityName {
            return true
        }

        if currentName == timezoneCityName {
            return false
        }

        let candidateAliasMatches = candidate.aliases.contains { normalizedSearchTerm($0) == timezoneCityName }
        let currentAliasMatches = current.aliases.contains { normalizedSearchTerm($0) == timezoneCityName }

        return candidateAliasMatches && !currentAliasMatches
    }

    private static func normalizedTimezoneCityName(for identifier: String) -> String {
        let cityComponent = identifier.split(separator: "/").last.map(String.init) ?? identifier
        return normalizedSearchTerm(cityComponent.replacingOccurrences(of: "_", with: " "))
    }

    private static func normalizedSearchTerm(_ value: String) -> String {
        value
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .lowercased()
            .replacingOccurrences(of: "[^a-z0-9]+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func fallbackResult(for identifier: String) -> CitySearchResult {
        let components = identifier.split(separator: "/").map(String.init)
        let cityName = components.last?
            .replacingOccurrences(of: "_", with: " ") ?? identifier
        let countryName = (components.first ?? "World").replacingOccurrences(of: "_", with: " ")

        return CitySearchResult(
            timeZoneIdentifier: identifier,
            cityName: cityName,
            countryName: countryName,
            countryCode: "UN",
            flag: "🌍"
        )
    }

    private static func flagEmoji(for countryCode: String) -> String {
        let uppercasedCode = countryCode.uppercased()
        guard uppercasedCode.count == 2 else {
            return "🌍"
        }

        let scalars = uppercasedCode.unicodeScalars.compactMap { scalar -> UnicodeScalar? in
            UnicodeScalar(127397 + scalar.value)
        }

        return String(String.UnicodeScalarView(scalars))
    }
}
