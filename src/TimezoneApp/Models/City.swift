import Foundation

struct City: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var countryCode: String
    var flag: String
    var timeZoneIdentifier: String
    var isHome: Bool
    var showInMenubar: Bool

    init(
        id: UUID = UUID(),
        name: String,
        countryCode: String,
        flag: String,
        timeZoneIdentifier: String,
        isHome: Bool = false,
        showInMenubar: Bool = false
    ) {
        self.id = id
        self.name = name
        self.countryCode = countryCode
        self.flag = flag
        self.timeZoneIdentifier = timeZoneIdentifier
        self.isHome = isHome
        self.showInMenubar = showInMenubar
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case countryCode
        case flag
        case timeZoneIdentifier
        case isHome
        case showInMenubar
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let timeZoneIdentifier = try container.decode(String.self, forKey: .timeZoneIdentifier)
        let fallbackName = timeZoneIdentifier
            .split(separator: "/")
            .last
            .map { $0.replacingOccurrences(of: "_", with: " ") } ?? timeZoneIdentifier

        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? fallbackName
        self.countryCode = try container.decodeIfPresent(String.self, forKey: .countryCode) ?? "UN"
        self.flag = try container.decodeIfPresent(String.self, forKey: .flag) ?? "🌍"
        self.timeZoneIdentifier = timeZoneIdentifier
        self.isHome = try container.decodeIfPresent(Bool.self, forKey: .isHome) ?? false
        self.showInMenubar = try container.decodeIfPresent(Bool.self, forKey: .showInMenubar) ?? false
    }
}
