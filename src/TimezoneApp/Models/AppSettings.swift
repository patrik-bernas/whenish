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
}
