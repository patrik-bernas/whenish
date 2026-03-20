import SwiftUI

struct TimeSliderView: View {
    @EnvironmentObject private var viewModel: TimezoneViewModel
    var showSlider: Bool = true

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.white.opacity(0.06))
                .frame(height: 0.5)
                .padding(.horizontal, 18)

            VStack(spacing: 0) {
                header
                    .padding(.bottom, showSlider ? 4 : 0)
                if showSlider {
                    slider
                        .padding(.bottom, 3)
                    footer
                }
            }
            .padding(.top, 6)
            .padding(.horizontal, 20)
            .padding(.bottom, 0)
        }
    }

    private var header: some View {
        HStack {
            Text(viewModel.offsetLabel)
                .font(.system(size: 10, weight: .regular))
                .foregroundStyle(.white.opacity(0.3))

            Spacer()

            Button {
                viewModel.resetScrubber()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(Color(red: 167 / 255, green: 180 / 255, blue: 1).opacity(0.6))
                    let parts = viewModel.currentLocalTimeParts
                    Text(parts.digits)
                        .font(.system(size: 10, weight: .regular))
                        .monospacedDigit()
                        .foregroundStyle(Color(red: 167 / 255, green: 180 / 255, blue: 1).opacity(0.6))
                    if let period = parts.period {
                        Text(period)
                            .font(.system(size: 8, weight: .regular))
                            .foregroundStyle(Color(red: 167 / 255, green: 180 / 255, blue: 1).opacity(0.45))
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }

    private var slider: some View {
        GeometryReader { geometry in
            let trackWidth = geometry.size.width
            let knobDiameter: CGFloat = 16
            let clampedOffset = max(min(viewModel.scrubberOffset, 24), -24)
            let progress = (clampedOffset + 24) / 48
            let knobX = progress * trackWidth

            ZStack(alignment: .leading) {
                TimelineBarView(
                    timeZone: viewModel.homeTimeZone,
                    scrubberOffset: 0,
                    width: trackWidth,
                    height: 7
                )

                if abs(clampedOffset) > 0.01 {
                    Rectangle()
                        .fill(Color(red: 140/255, green: 130/255, blue: 255/255).opacity(0.7))
                        .frame(width: 1.5, height: 12)
                        .offset(x: (trackWidth / 2) - 0.75)
                }

                Circle()
                    .fill(Color.white.opacity(0.95))
                    .frame(width: knobDiameter, height: knobDiameter)
                    .shadow(color: Color.black.opacity(0.15), radius: 6, y: 1)
                    .position(x: knobX, y: geometry.size.height / 2)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .local)
                    .onChanged { value in
                        let location = min(max(value.location.x, 0), trackWidth)
                        let normalized = location / trackWidth
                        viewModel.scrubberOffset = (normalized * 48) - 24
                    }
            )
        }
        .frame(height: 20)
    }

    private var footer: some View {
        HStack {
            Text("-24h")
            Spacer()
            Text("+24h")
        }
        .font(.system(size: 9, weight: .regular))
        .foregroundStyle(.white.opacity(0.18))
    }
}
