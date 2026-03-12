import SwiftUI

struct SearchBarView: View {
    @EnvironmentObject private var viewModel: TimezoneViewModel

    private var isGroupFull: Bool {
        (viewModel.activeGroup?.cities.count ?? 0) >= 6
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.3))

                    TextField("", text: $viewModel.searchQuery, prompt: Text("Add city...").foregroundColor(.white.opacity(0.3)))
                        .textFieldStyle(.plain)
                        .foregroundStyle(.white.opacity(0.88))
                }
                .padding(.horizontal, 14)
                .frame(height: 36)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                )

                Button {
                    viewModel.isSettingsOpen = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.35))
                        .frame(width: 32, height: 32)
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
                        Text("Active group is full")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white.opacity(0.6))
                            .padding(12)
                    } else if viewModel.searchResults.isEmpty {
                        Text("No matching cities")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white.opacity(0.6))
                            .padding(12)
                    } else {
                        ForEach(viewModel.searchResults.prefix(5)) { result in
                            Button {
                                viewModel.addCity(result)
                            } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(result.flag) \(result.cityName)")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundStyle(.white.opacity(0.88))
                                    Text(result.countryName)
                                        .font(.system(size: 11, weight: .regular))
                                        .foregroundStyle(.white.opacity(0.3))
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                            }
                            .buttonStyle(.plain)

                            if result.id != viewModel.searchResults.prefix(5).last?.id {
                                Divider()
                                    .overlay(Color.white.opacity(0.06))
                                    .padding(.horizontal, 12)
                            }
                        }
                    }
                }
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                )
            }
        }
    }
}
