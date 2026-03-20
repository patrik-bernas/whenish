import SwiftUI

struct ColumnView: View {
    @EnvironmentObject private var viewModel: TimezoneViewModel

    private let columnBarHeight: CGFloat = 140
    private let maxColumnWidth: CGFloat = 65
    private let barWidth: CGFloat = 22
    private let columnGap: CGFloat = 6
    private let timezoneService = TimezoneService()

    var body: some View {
        if let group = viewModel.activeGroup {
            let cities = group.cities
            VStack(spacing: 0) {
                // Column headers: flag + name + offset + menubar dot
                columnHeaders(cities: cities)
                    .frame(height: 75)

                // Column bars with scrub line
                columnBars(cities: cities)
                    .frame(height: columnBarHeight)

                // Time labels + date labels
                timeLabels(cities: cities)
                    .frame(height: 45)
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Column Headers

    private func columnHeaders(cities: [City]) -> some View {
        HStack(spacing: columnGap) {
            ForEach(cities) { city in
                ColumnHeaderView(city: city)
                    .frame(maxWidth: maxColumnWidth)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Column Bars

    private func columnBars(cities: [City]) -> some View {
        GeometryReader { geometry in
            let availableWidth = geometry.size.width
            let headerColWidth = cities.isEmpty ? maxColumnWidth : min((availableWidth - CGFloat(max(cities.count - 1, 0)) * columnGap) / CGFloat(cities.count), maxColumnWidth)
            let totalHeaderWidth = headerColWidth * CGFloat(cities.count) + CGFloat(max(cities.count - 1, 0)) * columnGap
            let leadingOffset = (availableWidth - totalHeaderWidth) / 2

            let clampedOffset = max(min(viewModel.scrubberOffset, 24), -24)
            let scrubNormalized = (clampedOffset + 24) / 48
            let scrubY = scrubNormalized * columnBarHeight

            ZStack(alignment: .topLeading) {
                // Column bars — slim pillars centered in each column slot
                HStack(spacing: columnGap) {
                    ForEach(cities) { city in
                        VerticalTimelineBar(
                            timeZone: viewModel.timeZone(for: city),
                            width: barWidth,
                            height: columnBarHeight
                        )
                        .frame(width: headerColWidth)
                    }
                }
                .frame(maxWidth: .infinity)

                // "Now" marker — indigo line, visible when scrubbed away
                if abs(clampedOffset) > 0.01 {
                    Rectangle()
                        .fill(Color(red: 140/255, green: 130/255, blue: 255/255).opacity(0.7))
                        .frame(width: totalHeaderWidth, height: 2)
                        .offset(x: leadingOffset, y: columnBarHeight / 2 - 1)
                }

                // Horizontal scrub line
                Rectangle()
                    .fill(Color.white.opacity(0.5))
                    .frame(width: totalHeaderWidth, height: 2)
                    .offset(x: leadingOffset, y: scrubY - 1)
                    .allowsHitTesting(false)

                // Scrub handle dot
                Circle()
                    .fill(Color.white.opacity(0.95))
                    .frame(width: 16, height: 16)
                    .shadow(color: Color.black.opacity(0.15), radius: 6, y: 1)
                    .position(x: availableWidth / 2, y: scrubY)
                    .allowsHitTesting(false)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .local)
                    .onChanged { value in
                        let location = min(max(value.location.y, 0), columnBarHeight)
                        let normalized = location / columnBarHeight
                        viewModel.scrubberOffset = (normalized * 48) - 24
                    }
            )
        }
    }

    // MARK: - Time Labels

    private func timeLabels(cities: [City]) -> some View {
        HStack(spacing: columnGap) {
            ForEach(cities) { city in
                let parts = viewModel.displayedTimeParts(for: city)
                VStack(spacing: 2) {
                    HStack(spacing: 1) {
                        Text(parts.digits)
                            .font(.system(size: 18, weight: .light))
                            .monospacedDigit()
                        if let period = parts.period {
                            Text(period)
                                .font(.system(size: 9, weight: .regular))
                                .foregroundStyle(.white.opacity(0.4))
                        }
                    }
                    .foregroundStyle(.white.opacity(0.85))

                    let dayParts = viewModel.displayedDayLabelParts(for: city)
                    VStack(spacing: 1) {
                        Text(dayParts.relative)
                            .font(.system(size: 8, weight: dayParts.isToday ? .regular : .medium))
                            .foregroundStyle(dayParts.isToday ? Color.white.opacity(0.2) : Color(red: 167 / 255, green: 180 / 255, blue: 1).opacity(0.55))
                        Text(dayParts.date)
                            .font(.system(size: 8, weight: .regular))
                            .foregroundStyle(dayParts.isToday ? Color.white.opacity(0.15) : Color(red: 167 / 255, green: 180 / 255, blue: 1).opacity(0.40))
                    }
                }
                .frame(maxWidth: maxColumnWidth)
            }
        }
        .frame(maxWidth: .infinity)
    }

}

// MARK: - Column Header

private struct ColumnHeaderView: View {
    @EnvironmentObject private var viewModel: TimezoneViewModel
    let city: City
    @State private var isHovering = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 2) {
                Text(city.flag)
                    .font(.system(size: 18))

                Text(city.name)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(city.isHome ? Color(red: 200 / 255, green: 210 / 255, blue: 1).opacity(0.95) : .white.opacity(0.85))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(width: 65, height: 28)

                Text(city.isHome ? "You" : viewModel.relativeOffsetLabel(for: city))
                    .font(.system(size: 9))
                    .foregroundStyle(.white.opacity(0.3))
                    .lineLimit(1)

                // Menubar dot
                Circle()
                    .fill(city.showInMenubar ? Color(red: 167 / 255, green: 180 / 255, blue: 1).opacity(0.7) : Color.white.opacity(0.15))
                    .frame(width: 5, height: 5)
                    .shadow(color: city.showInMenubar ? Color(red: 167 / 255, green: 180 / 255, blue: 1).opacity(0.35) : .clear, radius: 3)
                    .padding(.top, 1)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .onTapGesture {
                viewModel.toggleMenubar(for: city)
            }
            .onHover { hovering in
                isHovering = hovering
            }

            // Remove button on hover
            if isHovering {
                Button {
                    viewModel.removeCity(city)
                } label: {
                    Text("✕")
                        .font(.system(size: 8))
                        .foregroundStyle(.white.opacity(0.4))
                        .frame(width: 12, height: 12)
                }
                .buttonStyle(.plain)
                .offset(x: 2, y: -2)
            }
        }
    }
}

// MARK: - Vertical Timeline Bar

private struct VerticalTimelineBar: View {
    let timeZone: TimeZone
    let width: CGFloat
    let height: CGFloat

    private let timezoneService = TimezoneService()

    private var nowNormalized: CGFloat {
        return 0.5
    }

    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                ForEach(0..<48, id: \.self) { slot in
                    Rectangle()
                        .fill(color(for: slot))
                        .frame(width: width, height: height / 48)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))

            // "Now" tick mark — indigo
            Rectangle()
                .fill(Color(red: 140/255, green: 130/255, blue: 255/255).opacity(0.7))
                .frame(width: width, height: 2)
                .offset(y: nowNormalized * height - 1)
                .allowsHitTesting(false)
        }
    }

    private func color(for slot: Int) -> Color {
        let reference = Date()
        let slotDate = reference.addingTimeInterval((Double(slot) - 24) * 3600)
        var calendar = Calendar.current
        calendar.timeZone = timeZone
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
