#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CITY_DATA="$ROOT_DIR/src/TimezoneApp/Resources/cities.json"
MODULE_CACHE="${TMPDIR:-/tmp}/whenish-swift-module-cache"

mkdir -p "$MODULE_CACHE"

swift -module-cache-path "$MODULE_CACHE" - "$CITY_DATA" <<'SWIFT'
import Foundation

struct CityEntry: Decodable {
    let name: String
    let country: String
    let countryCode: String
    let timezoneId: String
    let aliases: [String]
}

let path = CommandLine.arguments[1]
let data = try Data(contentsOf: URL(fileURLWithPath: path))
let entries = try JSONDecoder().decode([CityEntry].self, from: data)

func normalized(_ value: String) -> String {
    value
        .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
        .lowercased()
        .replacingOccurrences(of: "[^a-z0-9]+", with: " ", options: .regularExpression)
        .trimmingCharacters(in: .whitespacesAndNewlines)
}

func timezoneCityName(_ identifier: String) -> String {
    let cityComponent = identifier.split(separator: "/").last.map(String.init) ?? identifier
    return normalized(cityComponent.replacingOccurrences(of: "_", with: " "))
}

func isBetterRepresentative(_ candidate: CityEntry, than current: CityEntry) -> Bool {
    let target = timezoneCityName(candidate.timezoneId)
    let candidateName = normalized(candidate.name)
    let currentName = normalized(current.name)

    if candidateName == target && currentName != target {
        return true
    }

    if currentName == target {
        return false
    }

    let candidateAliasMatches = candidate.aliases.contains { normalized($0) == target }
    let currentAliasMatches = current.aliases.contains { normalized($0) == target }

    return candidateAliasMatches && !currentAliasMatches
}

var errors: [String] = []

let invalidTimezones = entries.filter { TimeZone(identifier: $0.timezoneId) == nil }
if !invalidTimezones.isEmpty {
    errors.append("Invalid timezone IDs: \(invalidTimezones.map { "\($0.name)=\($0.timezoneId)" }.joined(separator: ", "))")
}

var seenIDs = Set<String>()
var duplicateIDs: [String] = []
for entry in entries {
    let id = "\(entry.timezoneId)|\(entry.countryCode)|\(entry.name)"
    if !seenIDs.insert(id).inserted {
        duplicateIDs.append(id)
    }
}

if !duplicateIDs.isEmpty {
    errors.append("Duplicate city result IDs: \(duplicateIDs.joined(separator: ", "))")
}

let sortedEntries = entries.sorted {
    if $0.name.caseInsensitiveCompare($1.name) == .orderedSame {
        return $0.country < $1.country
    }
    return $0.name < $1.name
}

var representatives: [String: CityEntry] = [:]
for entry in sortedEntries {
    guard let current = representatives[entry.timezoneId] else {
        representatives[entry.timezoneId] = entry
        continue
    }

    if isBetterRepresentative(entry, than: current) {
        representatives[entry.timezoneId] = entry
    }
}

let expectedRepresentatives = [
    "America/New_York": "New York",
    "America/Los_Angeles": "Los Angeles",
    "Europe/London": "London",
    "Asia/Tokyo": "Tokyo",
]

for (timezone, expectedCity) in expectedRepresentatives {
    let actualCity = representatives[timezone]?.name
    if actualCity != expectedCity {
        errors.append("Expected \(timezone) representative to be \(expectedCity), got \(actualCity ?? "nil")")
    }
}

if !errors.isEmpty {
    fputs(errors.joined(separator: "\n") + "\n", stderr)
    exit(1)
}

print("Validated \(entries.count) cities")
SWIFT
