import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var viewModel: TimezoneViewModel

    @State private var homeSearchQuery = ""
    @State private var homeSearchResults: [CitySearchResult] = []

    private let citySearchService = CitySearchService()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            formatToggle
            homeTimezoneSection
            groupRenameSection
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 16)
    }

    private var header: some View {
        HStack {
            Button {
                viewModel.isSettingsOpen = false
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 10, weight: .semibold))
                    Text("Back")
                        .font(.system(size: 12.5, weight: .medium))
                }
                .foregroundStyle(.white.opacity(0.88))
            }
            .buttonStyle(.plain)

            Spacer()

            Text("Settings")
                .font(.system(size: 13.5, weight: .semibold))
                .foregroundStyle(.white.opacity(0.88))
        }
    }

    private var formatToggle: some View {
        settingsCard {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Time Format")
                        .font(.system(size: 12.5, weight: .medium))
                        .foregroundStyle(.white.opacity(0.88))
                    Text("Choose 12-hour or 24-hour display")
                        .font(.system(size: 10.5))
                        .foregroundStyle(.white.opacity(0.3))
                }

                Spacer()

                Picker("Time Format", selection: $viewModel.settings.use24HourFormat) {
                    Text("12h").tag(false)
                    Text("24h").tag(true)
                }
                .pickerStyle(.segmented)
                .frame(width: 110)
            }
        }
    }

    private var homeTimezoneSection: some View {
        settingsCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Home Timezone")
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(.white.opacity(0.88))

                TextField(
                    "",
                    text: Binding(
                        get: { homeSearchQuery },
                        set: { newValue in
                            homeSearchQuery = newValue
                            homeSearchResults = citySearchService.search(query: newValue)
                        }
                    ),
                    prompt: Text(currentHomeLabel)
                        .foregroundColor(.white.opacity(0.3))
                )
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.88))
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                )

                if !homeSearchQuery.isEmpty {
                    VStack(spacing: 0) {
                        if homeSearchResults.isEmpty {
                            Text("No matching cities")
                                .font(.system(size: 11))
                                .foregroundStyle(.white.opacity(0.3))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                        } else {
                            ForEach(homeSearchResults.prefix(5)) { result in
                                Button {
                                    viewModel.setHomeTimezone(to: result.timeZoneIdentifier)
                                    homeSearchQuery = ""
                                    homeSearchResults = []
                                } label: {
                                    HStack(spacing: 10) {
                                        Text(result.flag)
                                            .font(.system(size: 18))

                                        VStack(alignment: .leading, spacing: 1) {
                                            Text(result.cityName)
                                                .font(.system(size: 12.5, weight: .medium))
                                                .foregroundStyle(.white.opacity(0.88))
                                            Text(result.countryName)
                                                .font(.system(size: 10.5))
                                                .foregroundStyle(.white.opacity(0.3))
                                        }

                                        Spacer()
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 9)
                                }
                                .buttonStyle(.plain)

                                if result.id != homeSearchResults.prefix(5).last?.id {
                                    Divider()
                                        .overlay(Color.white.opacity(0.06))
                                }
                            }
                        }
                    }
                    .background(Color.white.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                    )
                }
            }
        }
    }

    private var groupRenameSection: some View {
        settingsCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Groups")
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(.white.opacity(0.88))

                ForEach(Array(viewModel.groups.enumerated()), id: \.element.id) { index, group in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            TextField(
                                "",
                                text: Binding(
                                    get: { group.name },
                                    set: { viewModel.renameGroup(at: index, to: $0) }
                                ),
                                prompt: Text("Group name")
                                    .foregroundColor(.white.opacity(0.3))
                            )
                            .textFieldStyle(.plain)
                            .font(.system(size: 12.5))
                            .foregroundStyle(.white.opacity(0.88))

                            Spacer()

                            Text("\(group.name.count)/12")
                                .font(.system(size: 10))
                                .foregroundStyle(group.name.count >= 12 ? Color(red: 167 / 255, green: 180 / 255, blue: 1).opacity(0.55) : .white.opacity(0.25))
                        }

                        if index < viewModel.groups.count - 1 {
                            Divider()
                                .overlay(Color.white.opacity(0.06))
                                .padding(.top, 6)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    private var currentHomeLabel: String {
        if let identifier = viewModel.settings.homeTimeZoneIdentifier {
           let result = citySearchService.result(for: identifier)
            return "\(result.cityName), \(result.countryName)"
        }

        return "Search for a city"
    }

    private func settingsCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0, content: content)
            .padding(14)
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
            )
    }
}
