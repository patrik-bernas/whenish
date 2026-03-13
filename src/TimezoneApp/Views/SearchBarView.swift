import SwiftUI

struct SearchBarView: View {
    @EnvironmentObject private var viewModel: TimezoneViewModel

    @State private var isHoveringClear = false

    private var isGroupFull: Bool {
        (viewModel.activeGroup?.cities.count ?? 0) >= 5
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.3))

                    TextField("", text: $viewModel.searchQuery, prompt: Text("Add city...").foregroundColor(.white.opacity(0.3)))
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.88))

                    if !viewModel.searchQuery.isEmpty {
                        Button {
                            viewModel.searchQuery = ""
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(.white.opacity(isHoveringClear ? 0.5 : 0.3))
                        }
                        .buttonStyle(.plain)
                        .onHover { hovering in
                            isHoveringClear = hovering
                        }
                    }
                }
                .padding(.horizontal, 10)
                .frame(height: 34)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                )

                Button {
                    viewModel.isSettingsOpen = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.35))
                        .frame(width: 30, height: 30)
                        .background(Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                        )
                }
                .buttonStyle(.plain)
            }

            if !viewModel.searchQuery.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    if isGroupFull {
                        Text("This group is full (5/5)")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundStyle(.white.opacity(0.35))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)

                        if !viewModel.searchResults.isEmpty {
                            Rectangle()
                                .fill(Color.white.opacity(0.06))
                                .frame(height: 0.5)
                                .padding(.horizontal, 10)
                        }
                    }

                    if viewModel.searchResults.isEmpty {
                        Text("No matching cities")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.white.opacity(0.5))
                            .padding(10)
                    } else {
                        let results = Array(viewModel.searchResults.prefix(5))
                        ForEach(Array(results.enumerated()), id: \.element.id) { index, result in
                            SearchResultRow(result: result, isGroupFull: isGroupFull) {
                                if !isGroupFull {
                                    viewModel.addCity(result)
                                }
                            }

                            if index < results.count - 1 {
                                Rectangle()
                                    .fill(Color.white.opacity(0.06))
                                    .frame(height: 0.5)
                                    .padding(.horizontal, 10)
                            }
                        }
                    }
                }
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                )
            }
        }
    }
}

private struct SearchResultRow: View {
    let result: CitySearchResult
    let isGroupFull: Bool
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(result.flag)
                    .font(.system(size: 14))
                VStack(alignment: .leading, spacing: 2) {
                    Text(result.cityName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(isGroupFull ? 0.4 : 0.88))
                    Text(result.countryName)
                        .font(.system(size: 10, weight: .regular))
                        .foregroundStyle(.white.opacity(0.3))
                }
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(isHovering && !isGroupFull ? Color.white.opacity(0.06) : Color.clear)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}
