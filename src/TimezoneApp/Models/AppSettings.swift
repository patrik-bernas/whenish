import Foundation

struct AppSettings: Codable, Equatable {
    var use24HourFormat: Bool
    var homeTimeZoneIdentifier: String?
    var activeGroupId: UUID?
    var isColumnView: Bool

    init(
        use24HourFormat: Bool = true,
        homeTimeZoneIdentifier: String? = nil,
        activeGroupId: UUID? = nil,
        isColumnView: Bool = false
    ) {
        self.use24HourFormat = use24HourFormat
        self.homeTimeZoneIdentifier = homeTimeZoneIdentifier
        self.activeGroupId = activeGroupId
        self.isColumnView = isColumnView
    }

    private enum CodingKeys: String, CodingKey {
        case use24HourFormat
        case homeTimeZoneIdentifier
        case activeGroupId
        case isColumnView
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.use24HourFormat = try container.decodeIfPresent(Bool.self, forKey: .use24HourFormat) ?? true
        self.homeTimeZoneIdentifier = try container.decodeIfPresent(String.self, forKey: .homeTimeZoneIdentifier)
        self.activeGroupId = try container.decodeIfPresent(UUID.self, forKey: .activeGroupId)
        self.isColumnView = try container.decodeIfPresent(Bool.self, forKey: .isColumnView) ?? false
    }
}
