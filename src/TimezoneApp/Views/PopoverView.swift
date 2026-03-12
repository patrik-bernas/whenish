import SwiftUI

struct PopoverView: View {
    @EnvironmentObject private var viewModel: TimezoneViewModel

    var body: some View {
        VStack(spacing: 0) {
            SearchBarView()
                .padding(.horizontal, 24)
                .padding(.top, 20)

            PlaceholderSection(title: "Groups", subtitle: "GroupPillsView")
                .padding(.horizontal, 24)
                .padding(.top, 14)

            if let group = viewModel.activeGroup {
                VStack(spacing: 0) {
                    ForEach(group.cities) { city in
                        HStack {
                            Text(city.flag)
                            Text(city.name)
                                .foregroundStyle(.primary)
                            Spacer()
                            Text(city.timeZoneIdentifier)
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)

                        Divider()
                            .overlay(Color.white.opacity(0.06))
                            .padding(.horizontal, 24)
                    }
                }
                .padding(.top, 14)
            }

            PlaceholderSection(title: "Slider", subtitle: "TimeSliderView")
                .padding(.horizontal, 24)
                .padding(.top, 10)

            PlaceholderSection(title: "Legend", subtitle: "LegendView")
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
        }
        .frame(width: 370)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
        )
    }
}

struct PlaceholderSection: View {
    let title: String
    let subtitle: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.88))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.3))
            }
            Spacer()
        }
        .padding(12)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
        )
    }
}
