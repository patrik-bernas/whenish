import Foundation

struct CitySearchResult: Identifiable, Equatable {
    let timeZoneIdentifier: String
    let cityName: String
    let countryName: String
    let countryCode: String
    let flag: String

    var id: String { timeZoneIdentifier }
}

struct CitySearchService {
    private let curatedCities: [String: CitySearchResult] = [
        "Asia/Seoul": .init(timeZoneIdentifier: "Asia/Seoul", cityName: "Seoul", countryName: "South Korea", countryCode: "KR", flag: "🇰🇷"),
        "Asia/Tokyo": .init(timeZoneIdentifier: "Asia/Tokyo", cityName: "Tokyo", countryName: "Japan", countryCode: "JP", flag: "🇯🇵"),
        "Asia/Makassar": .init(timeZoneIdentifier: "Asia/Makassar", cityName: "Bali", countryName: "Indonesia", countryCode: "ID", flag: "🇮🇩"),
        "Europe/Amsterdam": .init(timeZoneIdentifier: "Europe/Amsterdam", cityName: "Amsterdam", countryName: "Netherlands", countryCode: "NL", flag: "🇳🇱"),
        "Europe/London": .init(timeZoneIdentifier: "Europe/London", cityName: "London", countryName: "United Kingdom", countryCode: "GB", flag: "🇬🇧"),
        "Australia/Sydney": .init(timeZoneIdentifier: "Australia/Sydney", cityName: "Sydney", countryName: "Australia", countryCode: "AU", flag: "🇦🇺"),
        "America/Los_Angeles": .init(timeZoneIdentifier: "America/Los_Angeles", cityName: "San Francisco", countryName: "United States", countryCode: "US", flag: "🇺🇸"),
        "America/New_York": .init(timeZoneIdentifier: "America/New_York", cityName: "New York", countryName: "United States", countryCode: "US", flag: "🇺🇸"),
    ]

    func search(query: String) -> [CitySearchResult] {
        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let allResults = buildDataset()

        guard !normalizedQuery.isEmpty else {
            return Array(allResults.prefix(20))
        }

        let queryTokens = normalizedQuery.split(separator: " ").map(String.init)

        return allResults
            .filter { result in
                let haystack = [
                    result.cityName,
                    result.countryName,
                    result.timeZoneIdentifier.replacingOccurrences(of: "_", with: " ")
                ]
                    .joined(separator: " ")
                    .lowercased()

                return queryTokens.allSatisfy { haystack.contains($0) }
            }
            .sorted { lhs, rhs in
                if lhs.cityName.caseInsensitiveCompare(rhs.cityName) == .orderedSame {
                    return lhs.countryName < rhs.countryName
                }
                return lhs.cityName < rhs.cityName
            }
    }

    func result(for identifier: String) -> CitySearchResult {
        curatedCities[identifier] ?? fallbackResult(for: identifier)
    }

    private func buildDataset() -> [CitySearchResult] {
        TimeZone.knownTimeZoneIdentifiers
            .map(result(for:))
            .sorted { lhs, rhs in
                if lhs.cityName.caseInsensitiveCompare(rhs.cityName) == .orderedSame {
                    return lhs.countryName < rhs.countryName
                }
                return lhs.cityName < rhs.cityName
            }
    }

    private func fallbackResult(for identifier: String) -> CitySearchResult {
        let components = identifier.split(separator: "/").map(String.init)
        let cityName = components.last?
            .replacingOccurrences(of: "_", with: " ") ?? identifier
        let region = components.first ?? "World"
        let countryCode = regionCode(for: region)

        return CitySearchResult(
            timeZoneIdentifier: identifier,
            cityName: cityName,
            countryName: region.replacingOccurrences(of: "_", with: " "),
            countryCode: countryCode,
            flag: flagEmoji(for: countryCode)
        )
    }

    private func regionCode(for region: String) -> String {
        switch region {
        case "Africa":
            return "ZA"
        case "America":
            return "US"
        case "Antarctica":
            return "AQ"
        case "Arctic":
            return "NO"
        case "Asia":
            return "JP"
        case "Atlantic":
            return "PT"
        case "Australia":
            return "AU"
        case "Europe":
            return "EU"
        case "Indian":
            return "IN"
        case "Pacific":
            return "NZ"
        default:
            return "UN"
        }
    }

    private func flagEmoji(for countryCode: String) -> String {
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
