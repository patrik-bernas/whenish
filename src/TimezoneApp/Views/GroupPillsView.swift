import SwiftUI

struct GroupPillsView: View {
    @EnvironmentObject private var viewModel: TimezoneViewModel

    var body: some View {
        HStack(spacing: 6) {
            ForEach(Array(viewModel.groups.prefix(3).enumerated()), id: \.element.id) { index, group in
                Button {
                    viewModel.switchGroup(to: index)
                } label: {
                    Text(group.name)
                        .font(.system(size: 12, weight: viewModel.activeGroupIndex == index ? .semibold : .regular))
                        .foregroundStyle(viewModel.activeGroupIndex == index ? Color.white.opacity(0.9) : Color.white.opacity(0.35))
                        .padding(.horizontal, 16)
                        .frame(height: 30)
                        .background(viewModel.activeGroupIndex == index ? Color.white.opacity(0.14) : Color.white.opacity(0.04))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(
                                    viewModel.activeGroupIndex == index ? Color.white.opacity(0.15) : Color.white.opacity(0.08),
                                    lineWidth: 0.5
                                )
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
