import SwiftUI

struct TimelineBarView: View {
    let timeZone: TimeZone
    let referenceDate: Date
    var width: CGFloat = 120
    var height: CGFloat = 3

    var body: some View {
        let slotColors = TimelineSlotColors.colors(for: timeZone, referenceDate: referenceDate)
        ZStack(alignment: .leading) {
            HStack(spacing: 0) {
                ForEach(0..<48, id: \.self) { slot in
                    Rectangle()
                        .fill(slotColors[slot])
                        .frame(width: width / 48, height: height)
                }
            }
            .clipShape(Capsule())
        }
        .frame(width: width, height: height)
    }
}

@MainActor
enum TimelineSlotColors {
    private static let timezoneService = TimezoneService()
    private static var cachedHourBucket: Int?
    private static var cache: [String: [Color]] = [:]

    static func colors(for timeZone: TimeZone, referenceDate: Date) -> [Color] {
        let hourBucket = Int(referenceDate.timeIntervalSinceReferenceDate / 3600)
        if cachedHourBucket != hourBucket {
            cachedHourBucket = hourBucket
            cache.removeAll(keepingCapacity: true)
        }

        if let cached = cache[timeZone.identifier] {
            return cached
        }

        var calendar = Calendar.current
        calendar.timeZone = timeZone
        let colors = (0..<48).map { slot in
            let slotDate = referenceDate.addingTimeInterval((Double(slot) - 24) * 3600)
            let localHour = calendar.component(.hour, from: slotDate)
            switch timezoneService.availabilityState(for: localHour) {
            case .available:
                return Color(red: 16/255, green: 185/255, blue: 129/255).opacity(0.85)
            case .headsUp:
                return Color(red: 251/255, green: 191/255, blue: 36/255).opacity(0.70)
            case .sleeping:
                return Color(red: 239/255, green: 68/255, blue: 68/255).opacity(0.55)
            }
        }
        cache[timeZone.identifier] = colors
        return colors
    }
}
