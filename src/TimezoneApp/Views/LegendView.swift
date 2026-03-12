import SwiftUI

struct LegendView: View {
    var body: some View {
        HStack(spacing: 18) {
            legendItem(
                color: Color(red: 134 / 255, green: 214 / 255, blue: 177 / 255).opacity(0.75),
                title: "Available"
            )
            legendItem(
                color: Color(red: 229 / 255, green: 195 / 255, blue: 120 / 255).opacity(0.65),
                title: "Heads up"
            )
            legendItem(
                color: Color(red: 205 / 255, green: 133 / 255, blue: 133 / 255).opacity(0.55),
                title: "Sleeping"
            )
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
    }

    private func legendItem(color: Color, title: String) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 5, height: 5)

            Text(title)
                .font(.system(size: 10, weight: .regular))
                .foregroundStyle(.white.opacity(0.25))
        }
    }
}
