import SwiftUI

struct SharedBottomSection: View {
    @EnvironmentObject private var viewModel: TimezoneViewModel

    var body: some View {
        VStack(spacing: 0) {
            // DIVIDER — thin horizontal line
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 0.5)
                .padding(.horizontal, 20)

            // Now + current time
            HStack {
                Text(viewModel.scrubberOffset == 0 ? "Now" : viewModel.offsetLabel)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.3))
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 10))
                    let parts = viewModel.currentLocalTimeParts
                    HStack(spacing: 2) {
                        Text(parts.digits)
                            .font(.system(size: 12, weight: .regular).monospacedDigit())
                        if let period = parts.period {
                            Text(period)
                                .font(.system(size: 9, weight: .regular))
                                .opacity(0.7)
                        }
                    }
                }
                .foregroundColor(Color(red: 140/255, green: 130/255, blue: 255/255).opacity(0.7))
                .onTapGesture { viewModel.scrubberOffset = 0 }
            }
            .padding(.horizontal, 20)
            .padding(.top, 6)

            // Legend
            HStack(spacing: 18) {
                legendItem(
                    color: Color(red: 16/255, green: 185/255, blue: 129/255).opacity(0.85),
                    title: "Available"
                )
                legendItem(
                    color: Color(red: 251/255, green: 191/255, blue: 36/255).opacity(0.70),
                    title: "Heads up"
                )
                legendItem(
                    color: Color(red: 239/255, green: 68/255, blue: 68/255).opacity(0.55),
                    title: "Sleeping"
                )
            }
            .padding(.top, 6)
            .padding(.bottom, 8)
        }
    }

    private func legendItem(color: Color, title: String) -> some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 5, height: 5)
            Text(title)
                .font(.system(size: 9))
                .foregroundColor(.white.opacity(0.25))
        }
    }
}
