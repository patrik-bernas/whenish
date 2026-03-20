import SwiftUI

struct RowListContentView: View {
    @EnvironmentObject private var viewModel: TimezoneViewModel

    private let rowHeight: CGFloat = 52
    // Timeline bar region X bounds (within the 390px popover)
    // 20px padding + 24px flag + 6px gap + 95px name + 6px gap = 151px
    private let barStartX: CGFloat = 151
    // 390 - 20px padding - 14px remove - 6px gap - 6px dot - 6px gap - 82px time - 6px gap = 250px
    private let barEndX: CGFloat = 250

    var body: some View {
        if let group = viewModel.activeGroup {
            let cities = group.cities
            let cityCount = CGFloat(cities.count)
            let totalCityHeight = cityCount * rowHeight

            let barWidth = barEndX - barStartX
            let clampedOffset = max(min(viewModel.scrubberOffset, 24), -24)
            let normalized = (clampedOffset + 24) / 48
            let scrubX = barStartX + normalized * barWidth

            ZStack(alignment: .topLeading) {
                // City rows — fixed 52px each
                VStack(spacing: 0) {
                    ForEach(Array(cities.enumerated()), id: \.element.id) { index, city in
                        CityRowView(city: city, isLast: index == cities.count - 1)
                            .frame(height: rowHeight)
                    }
                }

                // Purple "now" marker — FIXED at center, only visible when scrubbed away
                let nowX = barStartX + (0.5 * barWidth)
                Rectangle()
                    .fill(Color(red: 140/255, green: 130/255, blue: 255/255).opacity(0.7))
                    .frame(width: 2, height: totalCityHeight)
                    .position(x: nowX, y: totalCityHeight / 2)
                    .allowsHitTesting(false)
                    .opacity(abs(viewModel.scrubberOffset) < 0.5 ? 0 : 1)

                // Continuous vertical scrub line (2px, matching column view)
                Rectangle()
                    .fill(Color.white.opacity(0.5))
                    .frame(width: 2, height: totalCityHeight)
                    .position(x: scrubX, y: totalCityHeight / 2)
                    .allowsHitTesting(false)

                // White drag dot
                Circle()
                    .fill(Color.white.opacity(0.95))
                    .frame(width: 16, height: 16)
                    .shadow(color: .black.opacity(0.15), radius: 4, y: 1)
                    .position(x: scrubX, y: totalCityHeight / 2)
                    .allowsHitTesting(false)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .local)
                    .onChanged { value in
                        let dragX = max(barStartX, min(value.location.x, barEndX))
                        let norm = (dragX - barStartX) / barWidth
                        viewModel.scrubberOffset = (norm * 48) - 24
                    }
            )
        }
    }
}
