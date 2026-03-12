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
}
