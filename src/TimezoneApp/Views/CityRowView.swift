import SwiftUI

struct CityRowView: View {
    @EnvironmentObject private var viewModel: TimezoneViewModel

    let city: City
    let isLast: Bool

    @State private var isHovering = false
    @State private var isHoveringRemove = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                ZStack(alignment: .bottomTrailing) {
                    if city.isHome {
                        Circle()
                            .fill(Color(red: 167 / 255, green: 180 / 255, blue: 1).opacity(0.12))
                            .frame(width: 40, height: 40)
                    }

                    Text(city.flag)
                        .font(.system(size: 20))
                        .frame(width: 26)

                    if city.isHome {
                        Text("📍")
                            .font(.system(size: 8))
                            .offset(x: 4, y: 3)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(city.name)
                        .font(.system(size: 13.5, weight: city.isHome ? .semibold : .medium))
                        .foregroundStyle(city.isHome ? Color(red: 200 / 255, green: 210 / 255, blue: 1).opacity(0.95) : Color.white.opacity(0.88))
                    Text(viewModel.relativeOffsetLabel(for: city))
                        .font(.system(size: 10.5))
                        .foregroundStyle(.white.opacity(0.3))
                }
                .frame(minWidth: 72, alignment: .leading)

                TimelineBarView(timeZone: viewModel.timeZone(for: city), scrubberOffset: viewModel.scrubberOffset)
                    .frame(maxWidth: .infinity, alignment: .center)

                VStack(alignment: .trailing, spacing: 1) {
                    Text(viewModel.displayedTime(for: city))
                        .font(.system(size: 21, weight: .light))
                        .foregroundStyle(.white.opacity(0.85))
                        .monospacedDigit()
                    Text(viewModel.displayedDayLabel(for: city))
                        .font(.system(size: 9.5, weight: viewModel.displayedDayLabel(for: city) == "Today" ? .regular : .medium))
                        .foregroundStyle(viewModel.displayedDayLabel(for: city) == "Today" ? Color.white.opacity(0.2) : Color(red: 167 / 255, green: 180 / 255, blue: 1).opacity(0.55))
                        .frame(height: 13)
                }
                .frame(minWidth: 58, alignment: .trailing)

                Button {
                    viewModel.toggleMenubar(for: city)
                } label: {
                    Circle()
                        .fill(city.showInMenubar ? Color(red: 167 / 255, green: 180 / 255, blue: 1).opacity(0.7) : Color.white.opacity(0.15))
                        .frame(width: 7, height: 7)
                        .shadow(color: city.showInMenubar ? Color(red: 167 / 255, green: 180 / 255, blue: 1).opacity(0.35) : .clear, radius: 4)
                }
                .buttonStyle(.plain)

                Button {
                    viewModel.removeCity(city)
                } label: {
                    Text("✕")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(isHoveringRemove ? 0.4 : 0.12))
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    isHoveringRemove = hovering
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(isHovering ? Color.white.opacity(0.03) : .clear)
            .onHover { hovering in
                isHovering = hovering
            }

            if !isLast {
                Divider()
                    .overlay(Color.white.opacity(0.06))
                    .padding(.horizontal, 24)
            }
        }
    }
}
