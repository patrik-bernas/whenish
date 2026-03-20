import Foundation

enum AvailabilityState: String, CaseIterable, Codable {
    case available
    case headsUp
    case sleeping
}

struct TimezoneService {
    private let calendar = Calendar(identifier: .gregorian)

    // Cached formatters to avoid expensive re-creation in hot paths
    private static let formatter24h: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "HH:mm"
        return f
    }()
    private static let formatter12h: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "h:mm a"
        return f
    }()
    private static let formatter12hDigits: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "h:mm"
        return f
    }()
    private static let formatterPeriod: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "a"
        return f
    }()
    private static let formatterDayLabel: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "MMM d"
        return f
    }()

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
        let formatter = use24Hour ? Self.formatter24h : Self.formatter12h
        return formatter.string(from: date)
    }

    func formattedTimeParts(date: Date, use24Hour: Bool) -> TimeParts {
        if use24Hour {
            return TimeParts(digits: Self.formatter24h.string(from: date), period: nil)
        } else {
            let digits = Self.formatter12hDigits.string(from: date)
            let period = Self.formatterPeriod.string(from: date)
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

        let dateStr = Self.formatterDayLabel.string(from: date)

        let relative: String
        switch dayDifference {
        case ..<(-1):
            relative = "\(-dayDifference)d ago"
        case -1:
            relative = "Yesterday"
        case 0:
            relative = "Today"
        case 1:
            relative = "Tomorrow"
        default:
            relative = "+\(dayDifference)d"
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
