import SwiftUI

struct PopoverView: View {
    @EnvironmentObject private var viewModel: TimezoneViewModel

    var body: some View {
        Group {
            if viewModel.isSettingsOpen {
                SettingsView()
            } else {
                mainContent
            }
        }
        .frame(width: 370)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
        )
    }

    private var mainContent: some View {
        VStack(spacing: 0) {
            SearchBarView()
                .padding(.horizontal, 24)
                .padding(.top, 20)

            GroupPillsView()
                .padding(.horizontal, 24)
                .padding(.top, 14)

            if let group = viewModel.activeGroup {
                VStack(spacing: 0) {
                    ForEach(Array(group.cities.enumerated()), id: \.element.id) { index, city in
                        CityRowView(city: city, isLast: index == group.cities.count - 1)
                    }
                }
                .padding(.top, 14)
            }

            TimeSliderView()
                .padding(.top, 10)

            LegendView()
                .padding(.top, 2)
        }
    }
}
