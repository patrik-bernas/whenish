import SwiftUI

struct TimelineBarView: View {
    let timeZone: TimeZone
    let scrubberOffset: Double
    var width: CGFloat = 120
    var height: CGFloat = 3

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

            Rectangle()
                .fill(Color.white.opacity(0.45))
                .frame(width: 1, height: 9)
                .offset(x: scrubX)
        }
        .frame(width: width, height: 9)
    }

    private var scrubX: CGFloat {
        let normalized = min(max((scrubberOffset + 24) / 48, 0), 1)
        return normalized * width
    }

    private func color(for slot: Int) -> Color {
        let reference = Date().addingTimeInterval(scrubberOffset * 3600)
        let slotDate = reference.addingTimeInterval((Double(slot) - 24) * 3600)
        let localHour = Calendar.current.component(in: timeZone, from: slotDate)
        switch timezoneService.availabilityState(for: localHour) {
        case .available:
            return Color(red: 134 / 255, green: 214 / 255, blue: 177 / 255).opacity(0.75)
        case .headsUp:
            return Color(red: 229 / 255, green: 195 / 255, blue: 120 / 255).opacity(0.65)
        case .sleeping:
            return Color(red: 205 / 255, green: 133 / 255, blue: 133 / 255).opacity(0.55)
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
