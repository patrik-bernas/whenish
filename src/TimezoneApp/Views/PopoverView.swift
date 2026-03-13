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
        .frame(width: 390)
        .background(.regularMaterial)
    }

    private var mainContent: some View {
        VStack(spacing: 0) {
            SearchBarView()
                .padding(.horizontal, 20)
                .padding(.top, 14)

            GroupPillsView()
                .padding(.horizontal, 20)
                .padding(.top, 8)

            if let group = viewModel.activeGroup {
                VStack(spacing: 0) {
                    ForEach(Array(group.cities.enumerated()), id: \.element.id) { index, city in
                        CityRowView(city: city, isLast: index == group.cities.count - 1)
                    }
                }
                .padding(.top, 6)
            }

            TimeSliderView()
                .padding(.top, 4)

            LegendView()
        }
    }
}
