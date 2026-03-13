import SwiftUI

struct LegendView: View {
    var body: some View {
        HStack(spacing: 18) {
            legendItem(
                color: Color(red: 52 / 255, green: 211 / 255, blue: 153 / 255).opacity(0.85),
                title: "Available"
            )
            legendItem(
                color: Color(red: 251 / 255, green: 191 / 255, blue: 36 / 255).opacity(0.80),
                title: "Heads up"
            )
            legendItem(
                color: Color(red: 248 / 255, green: 113 / 255, blue: 113 / 255).opacity(0.70),
                title: "Sleeping"
            )
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .padding(.top, 6)
        .padding(.bottom, 4)
    }

    private func legendItem(color: Color, title: String) -> some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 5, height: 5)

            Text(title)
                .font(.system(size: 9, weight: .regular))
                .foregroundStyle(.white.opacity(0.25))
        }
    }
}
