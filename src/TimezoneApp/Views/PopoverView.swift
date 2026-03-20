import SwiftUI

struct PopoverView: View {
    @EnvironmentObject private var viewModel: TimezoneViewModel

    var body: some View {
        mainContent
    }

    private var mainContent: some View {
        VStack(spacing: 0) {
            // STATIC — never animates
            SearchBarView()
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .zIndex(10)

            GroupPillsView()
                .padding(.horizontal, 20)
                .padding(.top, 8)

            // CONTENT AREA — fills remaining space, only this part transitions
            Group {
                if viewModel.settings.isColumnView {
                    ColumnView()
                } else {
                    VStack(spacing: 0) {
                        if let group = viewModel.activeGroup {
                            VStack(spacing: 0) {
                                ForEach(Array(group.cities.enumerated()), id: \.element.id) { index, city in
                                    CityRowView(city: city, isLast: index == group.cities.count - 1)
                                }
                            }
                            .padding(.top, 6)
                        }
                    }
                }
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .clipped()
            .transition(.asymmetric(
                insertion: .opacity.animation(.easeIn(duration: 0.15).delay(0.1)),
                removal: .opacity.animation(.easeOut(duration: 0.1))
            ))
            .animation(.easeInOut(duration: 0.25), value: viewModel.settings.isColumnView)

            // BOTTOM SECTION — pinned to bottom
            // Row: full slider + footer. Column: only Now + time (no slider, no -24h/+24h).
            TimeSliderView(showSlider: !viewModel.settings.isColumnView)
            LegendView()
                .padding(.bottom, 4)
        }
        .frame(width: 390, height: 500)
        .background(.regularMaterial)
    }
}
