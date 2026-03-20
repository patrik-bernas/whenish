import SwiftUI

struct CityRowView: View {
    @EnvironmentObject private var viewModel: TimezoneViewModel

    let city: City

    @State private var isHovering = false
    @State private var isHoveringRemove = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                // Flag + home pin
                ZStack(alignment: .bottomTrailing) {
                    Text(city.flag)
                        .font(.system(size: 18))
                        .frame(width: 24, height: 24)

                    if city.isHome {
                        Text("📍")
                            .font(.system(size: 7))
                    }
                }
                .frame(width: 24, height: 24)

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
                .frame(width: 95, alignment: .leading)

                // Timeline bar: flex — takes ALL remaining space
                GeometryReader { geo in
                    TimelineBarView(timeZone: viewModel.timeZone(for: city), referenceDate: viewModel.currentDate, width: geo.size.width, height: 6)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 9)

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
                .frame(width: 82, alignment: .trailing)

                // Menubar dot: 6px
                Button {
                    viewModel.toggleMenubar(for: city)
                } label: {
                    Circle()
                        .fill(city.showInMenubar ? Color(red: 167 / 255, green: 180 / 255, blue: 1).opacity(0.7) : Color.white.opacity(0.15))
                        .frame(width: 6, height: 6)
                        .shadow(color: city.showInMenubar ? Color(red: 167 / 255, green: 180 / 255, blue: 1).opacity(0.35) : .clear, radius: 4)
                }
                .buttonStyle(.plain)
                .frame(width: 6)

                // Remove button
                Button {
                    viewModel.removeCity(city)
                } label: {
                    Text("✕")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(isHoveringRemove ? 0.4 : 0.12))
                        .frame(width: 14, height: 14)
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    isHoveringRemove = hovering
                }
            }
            .padding(.horizontal, 20)
            .frame(height: 52)
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
