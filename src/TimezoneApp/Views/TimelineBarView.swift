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

            // Dark plum "now" tick mark — fixed at center, always visible, 10px tall
            if showsScrubLine {
                Rectangle()
                    .fill(Color(red: 140/255, green: 130/255, blue: 255/255).opacity(0.7))
                    .frame(width: 2, height: 10)
                    .offset(x: nowX - 1)
                    .allowsHitTesting(false)

                Rectangle()
                    .fill(Color.white.opacity(0.5))
                    .frame(width: 1.5, height: scrubLineHeight)
                    .offset(x: scrubX - 0.75)
                    .allowsHitTesting(false)
            }
        }
        .frame(width: width, height: height)
    }

    /// Height of the scrub line — tall enough to visually bridge across rows
    private let scrubLineHeight: CGFloat = 46

    /// X position of "now" on the bar — always at center (offset 0 → normalized 0.5)
    private var nowX: CGFloat {
        (0.5 * width).rounded(.toNearestOrEven)
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
            return Color(red: 16/255, green: 185/255, blue: 129/255).opacity(0.85)
        case .headsUp:
            return Color(red: 251/255, green: 191/255, blue: 36/255).opacity(0.70)
        case .sleeping:
            return Color(red: 239/255, green: 68/255, blue: 68/255).opacity(0.55)
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
