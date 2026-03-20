import SwiftUI

struct PopoverView: View {
    @EnvironmentObject private var viewModel: TimezoneViewModel

    var body: some View {
        VStack(spacing: 0) {
            // TOP SECTION — identical in both views, never changes
            SearchBarView()
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .zIndex(10)

            GroupPillsView()
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 6)

            // CONTENT SECTION — fixed at 260px
            Group {
                if viewModel.settings.isColumnView {
                    ColumnView()
                } else {
                    RowListContentView()
                }
            }
            .frame(height: 260)
            .clipped()
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.25), value: viewModel.settings.isColumnView)

            // BOTTOM — identical in both views, never changes
            SharedBottomSection()
        }
        .frame(width: 390, height: 410)
        .background(.regularMaterial)
    }
}
