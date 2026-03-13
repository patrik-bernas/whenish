import SwiftUI

struct TimelineBarView: View {
    let timeZone: TimeZone
    let scrubberOffset: Double
    var width: CGFloat = 120
    var height: CGFloat = 3
    var showsScrubLine: Bool = true

    private let timezoneService = TimezoneService()

    var body: some View {
        ZStack(alignment: .leading) {
            HStack(spacing: 0) {
                ForEach(0..<48, id: \.self) { slot in
                    Rectangle()
                        .fill(color(for: slot))
                        .frame(width: width / 48, height: height)
                }
            }
            .clipShape(Capsule())

            if showsScrubLine {
                RoundedRectangle(cornerRadius: 0.5)
                    .fill(Color.white.opacity(0.45))
                    .frame(width: 1, height: 9)
                    .offset(x: scrubX - 0.5)
            }
        }
        .frame(width: width, height: 9)
    }

    private var scrubX: CGFloat {
        let normalized = min(max((scrubberOffset + 24) / 48, 0), 1)
        return (normalized * width).rounded(.toNearestOrEven)
    }

    private func color(for slot: Int) -> Color {
        let reference = Date()
        let slotDate = reference.addingTimeInterval((Double(slot) - 24) * 3600)
        let localHour = Calendar.current.component(in: timeZone, from: slotDate)
        switch timezoneService.availabilityState(for: localHour) {
        case .available:
            return Color(red: 52 / 255, green: 211 / 255, blue: 153 / 255).opacity(0.85)
        case .headsUp:
            return Color(red: 251 / 255, green: 191 / 255, blue: 36 / 255).opacity(0.80)
        case .sleeping:
            return Color(red: 248 / 255, green: 113 / 255, blue: 113 / 255).opacity(0.70)
        }
    }
}

private extension Calendar {
    func component(in timeZone: TimeZone, from date: Date) -> Int {
        var calendar = self
        calendar.timeZone = timeZone
        return calendar.component(.hour, from: date)
    }
}
