import Foundation

enum AvailabilityState: String, CaseIterable, Codable {
    case available
    case headsUp
    case sleeping
}

struct TimezoneService {
    private let calendar = Calendar(identifier: .gregorian)

    func currentTime(in timeZone: TimeZone, offsetHours: Double = 0) -> Date {
        let now = Date()
        let shiftedDate = now.addingTimeInterval(offsetHours * 3600)

        let utcOffset = TimeInterval(timeZone.secondsFromGMT(for: shiftedDate))
        let currentOffset = TimeInterval(TimeZone.current.secondsFromGMT(for: shiftedDate))
        let delta = utcOffset - currentOffset

        return shiftedDate.addingTimeInterval(delta)
    }

    struct TimeParts {
        let digits: String   // e.g. "5:14" or "17:14"
        let period: String?  // e.g. "PM" or nil for 24h
    }

    func formattedTime(date: Date, use24Hour: Bool) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = use24Hour ? "HH:mm" : "h:mm a"
        return formatter.string(from: date)
    }

    func formattedTimeParts(date: Date, use24Hour: Bool) -> TimeParts {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        if use24Hour {
            formatter.dateFormat = "HH:mm"
            return TimeParts(digits: formatter.string(from: date), period: nil)
        } else {
            formatter.dateFormat = "h:mm"
            let digits = formatter.string(from: date)
            formatter.dateFormat = "a"
            let period = formatter.string(from: date)
            return TimeParts(digits: digits, period: period)
        }
    }

    func offsetLabel(from home: TimeZone, to target: TimeZone, at date: Date = Date()) -> String {
        let deltaSeconds = target.secondsFromGMT(for: date) - home.secondsFromGMT(for: date)
        guard deltaSeconds != 0 else {
            return "Same"
        }

        let sign = deltaSeconds > 0 ? "+" : "-"
        let absoluteSeconds = abs(deltaSeconds)
        let hours = absoluteSeconds / 3600
        let minutes = (absoluteSeconds % 3600) / 60

        if minutes == 0 {
            return "\(sign)\(hours)h"
        }

        return "\(sign)\(hours)h \(minutes)m"
    }

    struct DayLabelParts {
        let relative: String  // "Today", "Tomorrow", "Yesterday"
        let date: String      // "Mar 20"
        var isToday: Bool { relative == "Today" }
    }

    func dayLabel(for date: Date, relativeTo reference: Date) -> String {
        dayLabelParts(for: date, relativeTo: reference).relative
    }

    func dayLabelParts(for date: Date, relativeTo reference: Date) -> DayLabelParts {
        let dayDifference = calendar.dateComponents([.day], from: calendar.startOfDay(for: reference), to: calendar.startOfDay(for: date)).day ?? 0

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MMM d"
        let dateStr = formatter.string(from: date)

        let relative: String
        switch dayDifference {
        case ..<0:
            relative = "Yesterday"
        case 0:
            relative = "Today"
        default:
            relative = "Tomorrow"
        }

        return DayLabelParts(relative: relative, date: dateStr)
    }

    func availabilityState(for hour: Int) -> AvailabilityState {
        switch hour {
        case 9..<17:
            return .available
        case 7..<9, 17..<21:
            return .headsUp
        default:
            return .sleeping
        }
    }
}
