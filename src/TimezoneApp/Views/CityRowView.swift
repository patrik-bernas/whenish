import SwiftUI

enum RowLayoutMetrics {
    static let rowHeight: CGFloat = 52
    static let horizontalPadding: CGFloat = 20
    static let itemSpacing: CGFloat = 6
    static let flagWidth: CGFloat = 24
    static let nameWidth: CGFloat = 95
    static let timelineHeight: CGFloat = 9
    static let timelineBarHeight: CGFloat = 6
    static let timeWidth: CGFloat = 82
    static let menubarDotWidth: CGFloat = 6
    static let removeButtonWidth: CGFloat = 14

    static var timelineLeadingInset: CGFloat {
        horizontalPadding + flagWidth + itemSpacing + nameWidth + itemSpacing
    }

    static var timelineTrailingInset: CGFloat {
        horizontalPadding + removeButtonWidth + itemSpacing + menubarDotWidth + itemSpacing + timeWidth + itemSpacing
    }
}

struct CityRowView: View {
    @EnvironmentObject private var viewModel: TimezoneViewModel

    let city: City

    @State private var isHovering = false
    @State private var isHoveringRemove = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: RowLayoutMetrics.itemSpacing) {
                // Flag + home pin
                ZStack(alignment: .bottomTrailing) {
                    Text(city.flag)
                        .font(.system(size: 18))
                        .frame(width: RowLayoutMetrics.flagWidth, height: RowLayoutMetrics.flagWidth)

                    if city.isHome {
                        Text("📍")
                            .font(.system(size: 7))
                    }
                }
                .frame(width: RowLayoutMetrics.flagWidth, height: RowLayoutMetrics.flagWidth)

                // Name + offset: 95px fixed
                VStack(alignment: .leading, spacing: 1) {
                    Text(city.name)
                        .font(.system(size: 12.5, weight: city.isHome ? .semibold : .medium))
                        .foregroundStyle(city.isHome ? Color(red: 200 / 255, green: 210 / 255, blue: 1).opacity(0.95) : Color.white.opacity(0.88))
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Text(viewModel.relativeOffsetLabel(for: city))
                        .font(.system(size: 10.5))
                        .foregroundStyle(.white.opacity(0.3))
                        .lineLimit(1)
                }
                .frame(width: RowLayoutMetrics.nameWidth, alignment: .leading)

                // Timeline bar: flex — takes ALL remaining space
                GeometryReader { geo in
                    TimelineBarView(timeZone: viewModel.timeZone(for: city), referenceDate: viewModel.currentDate, width: geo.size.width, height: RowLayoutMetrics.timelineBarHeight)
                }
                .frame(maxWidth: .infinity)
                .frame(height: RowLayoutMetrics.timelineHeight)

                // Time + date: 82px fixed
                VStack(alignment: .trailing, spacing: 1) {
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        let parts = viewModel.displayedTimeParts(for: city)
                        Text(parts.digits)
                            .font(.system(size: 19, weight: .light))
                            .foregroundStyle(.white.opacity(0.85))
                            .monospacedDigit()
                        if let period = parts.period {
                            Text(period)
                                .font(.system(size: 10, weight: .regular))
                                .foregroundStyle(.white.opacity(0.45))
                        }
                    }
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                    let dayParts = viewModel.displayedDayLabelParts(for: city)
                    Text("\(dayParts.relative), \(dayParts.date)")
                        .font(.system(size: 9, weight: dayParts.isToday ? .regular : .medium))
                        .foregroundStyle(dayParts.isToday ? Color.white.opacity(0.2) : Color(red: 167 / 255, green: 180 / 255, blue: 1).opacity(0.55))
                        .frame(height: 12)
                }
                .frame(width: RowLayoutMetrics.timeWidth, alignment: .trailing)

                // Menubar dot: 6px
                Button {
                    viewModel.toggleMenubar(for: city)
                } label: {
                    Circle()
                        .fill(city.showInMenubar ? Color(red: 167 / 255, green: 180 / 255, blue: 1).opacity(0.7) : Color.white.opacity(0.15))
                        .frame(width: RowLayoutMetrics.menubarDotWidth, height: RowLayoutMetrics.menubarDotWidth)
                        .shadow(color: city.showInMenubar ? Color(red: 167 / 255, green: 180 / 255, blue: 1).opacity(0.35) : .clear, radius: 4)
                }
                .buttonStyle(.plain)
                .frame(width: RowLayoutMetrics.menubarDotWidth)

                // Remove button
                Button {
                    viewModel.removeCity(city)
                } label: {
                    Text("✕")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(isHoveringRemove ? 0.4 : 0.12))
                        .frame(width: RowLayoutMetrics.removeButtonWidth, height: RowLayoutMetrics.removeButtonWidth)
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    isHoveringRemove = hovering
                }
            }
            .padding(.horizontal, RowLayoutMetrics.horizontalPadding)
            .frame(height: RowLayoutMetrics.rowHeight)
            .background(
                Group {
                    if city.isHome {
                        Color(red: 167 / 255, green: 180 / 255, blue: 1).opacity(0.04)
                    } else if isHovering {
                        Color.white.opacity(0.03)
                    } else {
                        Color.clear
                    }
                }
            )
            .onHover { hovering in
                isHovering = hovering
            }

            // Rows intentionally render without dividers.
        }
    }
}
