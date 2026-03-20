import SwiftUI

struct TimelineBarView: View {
    let timeZone: TimeZone
    let scrubberOffset: Double
    var width: CGFloat = 120
    var height: CGFloat = 3

    private static let timezoneService = TimezoneService()

    var body: some View {
        let slotColors = Self.computeSlotColors(timeZone: timeZone)
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

    private static func computeSlotColors(timeZone: TimeZone) -> [Color] {
        let reference = Date()
        var calendar = Calendar.current
        calendar.timeZone = timeZone
        return (0..<48).map { slot in
            let slotDate = reference.addingTimeInterval((Double(slot) - 24) * 3600)
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
    }
}
