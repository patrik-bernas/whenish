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

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case cities
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.name = String((try container.decodeIfPresent(String.self, forKey: .name) ?? "Group").prefix(12))
        self.cities = Array((try container.decodeIfPresent([City].self, forKey: .cities) ?? []).prefix(5))
    }
}
