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
        "Asia/Shanghai": .init(timeZoneIdentifier: "Asia/Shanghai", cityName: "Shanghai", countryName: "China", countryCode: "CN", flag: "🇨🇳"),
        "Asia/Hong_Kong": .init(timeZoneIdentifier: "Asia/Hong_Kong", cityName: "Hong Kong", countryName: "China", countryCode: "HK", flag: "🇭🇰"),
        "Asia/Singapore": .init(timeZoneIdentifier: "Asia/Singapore", cityName: "Singapore", countryName: "Singapore", countryCode: "SG", flag: "🇸🇬"),
        "Asia/Dubai": .init(timeZoneIdentifier: "Asia/Dubai", cityName: "Dubai", countryName: "UAE", countryCode: "AE", flag: "🇦🇪"),
        "Asia/Kolkata": .init(timeZoneIdentifier: "Asia/Kolkata", cityName: "Mumbai", countryName: "India", countryCode: "IN", flag: "🇮🇳"),
        "Asia/Bangkok": .init(timeZoneIdentifier: "Asia/Bangkok", cityName: "Bangkok", countryName: "Thailand", countryCode: "TH", flag: "🇹🇭"),
        "Europe/Amsterdam": .init(timeZoneIdentifier: "Europe/Amsterdam", cityName: "Amsterdam", countryName: "Netherlands", countryCode: "NL", flag: "🇳🇱"),
        "Europe/London": .init(timeZoneIdentifier: "Europe/London", cityName: "London", countryName: "United Kingdom", countryCode: "GB", flag: "🇬🇧"),
        "Europe/Vienna": .init(timeZoneIdentifier: "Europe/Vienna", cityName: "Vienna", countryName: "Austria", countryCode: "AT", flag: "🇦🇹"),
        "Europe/Berlin": .init(timeZoneIdentifier: "Europe/Berlin", cityName: "Berlin", countryName: "Germany", countryCode: "DE", flag: "🇩🇪"),
        "Europe/Paris": .init(timeZoneIdentifier: "Europe/Paris", cityName: "Paris", countryName: "France", countryCode: "FR", flag: "🇫🇷"),
        "Europe/Madrid": .init(timeZoneIdentifier: "Europe/Madrid", cityName: "Madrid", countryName: "Spain", countryCode: "ES", flag: "🇪🇸"),
        "Europe/Rome": .init(timeZoneIdentifier: "Europe/Rome", cityName: "Rome", countryName: "Italy", countryCode: "IT", flag: "🇮🇹"),
        "Europe/Zurich": .init(timeZoneIdentifier: "Europe/Zurich", cityName: "Zurich", countryName: "Switzerland", countryCode: "CH", flag: "🇨🇭"),
        "Europe/Stockholm": .init(timeZoneIdentifier: "Europe/Stockholm", cityName: "Stockholm", countryName: "Sweden", countryCode: "SE", flag: "🇸🇪"),
        "Europe/Prague": .init(timeZoneIdentifier: "Europe/Prague", cityName: "Prague", countryName: "Czech Republic", countryCode: "CZ", flag: "🇨🇿"),
        "Europe/Warsaw": .init(timeZoneIdentifier: "Europe/Warsaw", cityName: "Warsaw", countryName: "Poland", countryCode: "PL", flag: "🇵🇱"),
        "Europe/Istanbul": .init(timeZoneIdentifier: "Europe/Istanbul", cityName: "Istanbul", countryName: "Turkey", countryCode: "TR", flag: "🇹🇷"),
        "Europe/Moscow": .init(timeZoneIdentifier: "Europe/Moscow", cityName: "Moscow", countryName: "Russia", countryCode: "RU", flag: "🇷🇺"),
        "Europe/Lisbon": .init(timeZoneIdentifier: "Europe/Lisbon", cityName: "Lisbon", countryName: "Portugal", countryCode: "PT", flag: "🇵🇹"),
        "Australia/Sydney": .init(timeZoneIdentifier: "Australia/Sydney", cityName: "Sydney", countryName: "Australia", countryCode: "AU", flag: "🇦🇺"),
        "Australia/Melbourne": .init(timeZoneIdentifier: "Australia/Melbourne", cityName: "Melbourne", countryName: "Australia", countryCode: "AU", flag: "🇦🇺"),
        "America/Los_Angeles": .init(timeZoneIdentifier: "America/Los_Angeles", cityName: "San Francisco", countryName: "United States", countryCode: "US", flag: "🇺🇸"),
        "America/New_York": .init(timeZoneIdentifier: "America/New_York", cityName: "New York", countryName: "United States", countryCode: "US", flag: "🇺🇸"),
        "America/Chicago": .init(timeZoneIdentifier: "America/Chicago", cityName: "Chicago", countryName: "United States", countryCode: "US", flag: "🇺🇸"),
        "America/Denver": .init(timeZoneIdentifier: "America/Denver", cityName: "Denver", countryName: "United States", countryCode: "US", flag: "🇺🇸"),
        "America/Toronto": .init(timeZoneIdentifier: "America/Toronto", cityName: "Toronto", countryName: "Canada", countryCode: "CA", flag: "🇨🇦"),
        "America/Vancouver": .init(timeZoneIdentifier: "America/Vancouver", cityName: "Vancouver", countryName: "Canada", countryCode: "CA", flag: "🇨🇦"),
        "America/Mexico_City": .init(timeZoneIdentifier: "America/Mexico_City", cityName: "Mexico City", countryName: "Mexico", countryCode: "MX", flag: "🇲🇽"),
        "America/Sao_Paulo": .init(timeZoneIdentifier: "America/Sao_Paulo", cityName: "São Paulo", countryName: "Brazil", countryCode: "BR", flag: "🇧🇷"),
        "America/Argentina/Buenos_Aires": .init(timeZoneIdentifier: "America/Argentina/Buenos_Aires", cityName: "Buenos Aires", countryName: "Argentina", countryCode: "AR", flag: "🇦🇷"),
        "Pacific/Honolulu": .init(timeZoneIdentifier: "Pacific/Honolulu", cityName: "Honolulu", countryName: "United States", countryCode: "US", flag: "🇺🇸"),
        "Pacific/Auckland": .init(timeZoneIdentifier: "Pacific/Auckland", cityName: "Auckland", countryName: "New Zealand", countryCode: "NZ", flag: "🇳🇿"),
        "Africa/Cairo": .init(timeZoneIdentifier: "Africa/Cairo", cityName: "Cairo", countryName: "Egypt", countryCode: "EG", flag: "🇪🇬"),
        "Africa/Lagos": .init(timeZoneIdentifier: "Africa/Lagos", cityName: "Lagos", countryName: "Nigeria", countryCode: "NG", flag: "🇳🇬"),
        "Africa/Johannesburg": .init(timeZoneIdentifier: "Africa/Johannesburg", cityName: "Johannesburg", countryName: "South Africa", countryCode: "ZA", flag: "🇿🇦"),
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

    // Comprehensive timezone-to-country mapping for correct flag display
    private let timezoneToCountry: [String: String] = [
        "Europe/Athens": "GR",
        "Europe/Vienna": "AT",
        "Europe/Berlin": "DE",
        "Europe/London": "GB",
        "Europe/Paris": "FR",
        "Europe/Rome": "IT",
        "Europe/Madrid": "ES",
        "Europe/Amsterdam": "NL",
        "Europe/Dublin": "IE",
        "Europe/Lisbon": "PT",
        "Europe/Brussels": "BE",
        "Europe/Zurich": "CH",
        "Europe/Stockholm": "SE",
        "Europe/Oslo": "NO",
        "Europe/Copenhagen": "DK",
        "Europe/Helsinki": "FI",
        "Europe/Warsaw": "PL",
        "Europe/Prague": "CZ",
        "Europe/Budapest": "HU",
        "Europe/Bucharest": "RO",
        "Europe/Sofia": "BG",
        "Europe/Zagreb": "HR",
        "Europe/Belgrade": "RS",
        "Europe/Istanbul": "TR",
        "Europe/Moscow": "RU",
        "Europe/Kiev": "UA",
        "Europe/Kyiv": "UA",
        "Europe/Minsk": "BY",
        "Europe/Tallinn": "EE",
        "Europe/Riga": "LV",
        "Europe/Vilnius": "LT",
        "Europe/Ljubljana": "SI",
        "Europe/Bratislava": "SK",
        "Europe/Luxembourg": "LU",
        "Europe/Monaco": "MC",
        "Europe/Malta": "MT",
        "Europe/Andorra": "AD",
        "Europe/Tirane": "AL",
        "Europe/Sarajevo": "BA",
        "Europe/Podgorica": "ME",
        "Europe/Skopje": "MK",
        "Europe/Chisinau": "MD",
        "Asia/Tokyo": "JP",
        "Asia/Seoul": "KR",
        "Asia/Shanghai": "CN",
        "Asia/Hong_Kong": "HK",
        "Asia/Taipei": "TW",
        "Asia/Singapore": "SG",
        "Asia/Bangkok": "TH",
        "Asia/Jakarta": "ID",
        "Asia/Makassar": "ID",
        "Asia/Jayapura": "ID",
        "Asia/Kolkata": "IN",
        "Asia/Dubai": "AE",
        "Asia/Riyadh": "SA",
        "Asia/Doha": "QA",
        "Asia/Karachi": "PK",
        "Asia/Dhaka": "BD",
        "Asia/Kuala_Lumpur": "MY",
        "Asia/Manila": "PH",
        "Asia/Ho_Chi_Minh": "VN",
        "Asia/Phnom_Penh": "KH",
        "Asia/Kathmandu": "NP",
        "Asia/Colombo": "LK",
        "Asia/Tbilisi": "GE",
        "Asia/Yerevan": "AM",
        "Asia/Baku": "AZ",
        "Asia/Jerusalem": "IL",
        "Asia/Beirut": "LB",
        "Asia/Amman": "JO",
        "Asia/Baghdad": "IQ",
        "Asia/Tehran": "IR",
        "Asia/Kabul": "AF",
        "Asia/Muscat": "OM",
        "Asia/Kuwait": "KW",
        "Asia/Bahrain": "BH",
        "Asia/Yangon": "MM",
        "Asia/Vientiane": "LA",
        "Asia/Brunei": "BN",
        "Asia/Dili": "TL",
        "Asia/Ulaanbaatar": "MN",
        "Asia/Almaty": "KZ",
        "Asia/Tashkent": "UZ",
        "Asia/Bishkek": "KG",
        "Asia/Dushanbe": "TJ",
        "Asia/Ashgabat": "TM",
        "Asia/Nicosia": "CY",
        "Australia/Sydney": "AU",
        "Australia/Melbourne": "AU",
        "Australia/Brisbane": "AU",
        "Australia/Perth": "AU",
        "Australia/Adelaide": "AU",
        "Australia/Darwin": "AU",
        "Australia/Hobart": "AU",
        "Pacific/Auckland": "NZ",
        "Pacific/Chatham": "NZ",
        "Pacific/Fiji": "FJ",
        "Pacific/Honolulu": "US",
        "Pacific/Guam": "GU",
        "Pacific/Port_Moresby": "PG",
        "Pacific/Noumea": "NC",
        "Pacific/Apia": "WS",
        "Pacific/Tongatapu": "TO",
        "America/New_York": "US",
        "America/Chicago": "US",
        "America/Denver": "US",
        "America/Los_Angeles": "US",
        "America/Anchorage": "US",
        "America/Phoenix": "US",
        "America/Adak": "US",
        "America/Boise": "US",
        "America/Detroit": "US",
        "America/Indiana/Indianapolis": "US",
        "America/Juneau": "US",
        "America/Kentucky/Louisville": "US",
        "America/Menominee": "US",
        "America/Nome": "US",
        "America/North_Dakota/Center": "US",
        "America/Sitka": "US",
        "America/Yakutat": "US",
        "America/Toronto": "CA",
        "America/Vancouver": "CA",
        "America/Edmonton": "CA",
        "America/Winnipeg": "CA",
        "America/Halifax": "CA",
        "America/St_Johns": "CA",
        "America/Regina": "CA",
        "America/Mexico_City": "MX",
        "America/Cancun": "MX",
        "America/Tijuana": "MX",
        "America/Hermosillo": "MX",
        "America/Bogota": "CO",
        "America/Lima": "PE",
        "America/Santiago": "CL",
        "America/Buenos_Aires": "AR",
        "America/Argentina/Buenos_Aires": "AR",
        "America/Sao_Paulo": "BR",
        "America/Caracas": "VE",
        "America/Panama": "PA",
        "America/Costa_Rica": "CR",
        "America/Jamaica": "JM",
        "America/Havana": "CU",
        "America/Guatemala": "GT",
        "America/Tegucigalpa": "HN",
        "America/Managua": "NI",
        "America/El_Salvador": "SV",
        "America/Guayaquil": "EC",
        "America/Asuncion": "PY",
        "America/Montevideo": "UY",
        "America/La_Paz": "BO",
        "America/Santo_Domingo": "DO",
        "America/Port-au-Prince": "HT",
        "America/Guyana": "GY",
        "America/Paramaribo": "SR",
        "Africa/Cairo": "EG",
        "Africa/Lagos": "NG",
        "Africa/Nairobi": "KE",
        "Africa/Johannesburg": "ZA",
        "Africa/Casablanca": "MA",
        "Africa/Accra": "GH",
        "Africa/Addis_Ababa": "ET",
        "Africa/Algiers": "DZ",
        "Africa/Tunis": "TN",
        "Africa/Tripoli": "LY",
        "Africa/Khartoum": "SD",
        "Africa/Dar_es_Salaam": "TZ",
        "Africa/Kampala": "UG",
        "Africa/Maputo": "MZ",
        "Africa/Lusaka": "ZM",
        "Africa/Harare": "ZW",
        "Africa/Windhoek": "NA",
        "Africa/Abidjan": "CI",
        "Africa/Dakar": "SN",
        "Atlantic/Reykjavik": "IS",
        "Atlantic/Cape_Verde": "CV",
        "Indian/Maldives": "MV",
        "Indian/Mauritius": "MU",
        "Indian/Antananarivo": "MG",
    ]

    private func fallbackResult(for identifier: String) -> CitySearchResult {
        let components = identifier.split(separator: "/").map(String.init)
        let cityName = components.last?
            .replacingOccurrences(of: "_", with: " ") ?? identifier

        // Look up country code from the comprehensive dictionary
        let countryCode: String
        if let code = timezoneToCountry[identifier] {
            countryCode = code
        } else {
            // No match — use globe emoji fallback
            countryCode = ""
        }

        let countryName: String
        if !countryCode.isEmpty {
            countryName = Locale.current.localizedString(forRegionCode: countryCode)
                ?? (components.first ?? "World").replacingOccurrences(of: "_", with: " ")
        } else {
            countryName = (components.first ?? "World").replacingOccurrences(of: "_", with: " ")
        }

        let flag = countryCode.isEmpty ? "🌍" : flagEmoji(for: countryCode)

        return CitySearchResult(
            timeZoneIdentifier: identifier,
            cityName: cityName,
            countryName: countryName,
            countryCode: countryCode.isEmpty ? "UN" : countryCode,
            flag: flag
        )
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
