import SwiftUI

struct RowListContentView: View {
    @EnvironmentObject private var viewModel: TimezoneViewModel

    var body: some View {
        if let group = viewModel.activeGroup {
            let cities = group.cities
            let cityCount = CGFloat(cities.count)
            let totalCityHeight = cityCount * RowLayoutMetrics.rowHeight

            GeometryReader { geometry in
                let barStartX = RowLayoutMetrics.timelineLeadingInset
                let barEndX = max(barStartX, geometry.size.width - RowLayoutMetrics.timelineTrailingInset)
                let barWidth = max(barEndX - barStartX, 1)
                let clampedOffset = max(min(viewModel.scrubberOffset, 24), -24)
                let normalized = (clampedOffset + 24) / 48
                let scrubX = barStartX + normalized * barWidth

                ZStack(alignment: .topLeading) {
                    // City rows — fixed 52px each
                    VStack(spacing: 0) {
                        ForEach(cities) { city in
                            CityRowView(city: city)
                                .frame(height: RowLayoutMetrics.rowHeight)
                        }
                    }

                    // Purple "now" marker — fixed at center, only visible when scrubbed away
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
}
