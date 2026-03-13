import Foundation

struct TimezoneGroup: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var cities: [City]

    init(id: UUID = UUID(), name: String, cities: [City] = []) {
        self.id = id
        self.name = String(name.prefix(12))
        self.cities = Array(cities.prefix(5))
    }
}
