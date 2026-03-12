import SwiftUI

struct TimeSliderView: View {
    @EnvironmentObject private var viewModel: TimezoneViewModel

    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .overlay(Color.white.opacity(0.06))

            VStack(spacing: 10) {
                header
                slider
                footer
            }
            .padding(.top, 10)
            .padding(.horizontal, 24)
            .padding(.bottom, 14)
        }
    }

    private var header: some View {
        HStack {
            Text(viewModel.offsetLabel)
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(.white.opacity(0.3))

            Spacer()

            Button {
                viewModel.resetScrubber()
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "clock")
                        .font(.system(size: 10, weight: .medium))
                    Text(viewModel.currentLocalTimeString)
                        .font(.system(size: 12.5, weight: .regular))
                        .monospacedDigit()
                }
                .foregroundStyle(Color(red: 167 / 255, green: 180 / 255, blue: 1).opacity(0.6))
            }
            .buttonStyle(.plain)
        }
    }

    private var slider: some View {
        GeometryReader { geometry in
            let trackWidth = geometry.size.width
            let knobDiameter: CGFloat = 18
            let clampedOffset = max(min(viewModel.scrubberOffset, 24), -24)
            let progress = (clampedOffset + 24) / 48
            let knobX = progress * trackWidth

            ZStack(alignment: .leading) {
                TimelineBarView(
                    timeZone: viewModel.homeTimeZone,
                    scrubberOffset: 0,
                    width: trackWidth,
                    height: 5,
                    showsScrubLine: false
                )

                if abs(clampedOffset) > 0.01 {
                    Rectangle()
                        .fill(Color(red: 167 / 255, green: 180 / 255, blue: 1).opacity(0.5))
                        .frame(width: 1.5, height: 14)
                        .offset(x: (trackWidth / 2) - 0.75)
                }

                Circle()
                    .fill(Color.white.opacity(0.95))
                    .frame(width: knobDiameter, height: knobDiameter)
                    .shadow(color: Color.black.opacity(0.15), radius: 8, y: 1)
                    .offset(x: knobX - (knobDiameter / 2))
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let location = min(max(value.location.x, 0), trackWidth)
                                let normalized = location / trackWidth
                                viewModel.scrubberOffset = (normalized * 48) - 24
                            }
                    )
            }
        }
        .frame(height: 22)
    }

    private var footer: some View {
        HStack {
            Text("-24h")
            Spacer()
            Text("+24h")
        }
        .font(.system(size: 9.5, weight: .regular))
        .foregroundStyle(.white.opacity(0.18))
    }
}
