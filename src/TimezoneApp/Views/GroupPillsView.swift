import SwiftUI

struct GroupPillsView: View {
    @EnvironmentObject private var viewModel: TimezoneViewModel

    @State private var editingIndex: Int?
    @State private var editName: String = ""
    @State private var showDeleteConfirm = false

    var body: some View {
        HStack(spacing: 5) {
            ForEach(Array(viewModel.groups.prefix(5).enumerated()), id: \.element.id) { index, group in
                if editingIndex == index {
                    inlineEditPill(index: index)
                } else {
                    pillButton(group: group, index: index)
                }
            }

            if viewModel.groups.count < 5 && editingIndex == nil {
                addButton
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Normal pill

    @ViewBuilder
    private func pillButton(group: TimezoneGroup, index: Int) -> some View {
        let isActive = viewModel.activeGroupIndex == index
        let textColor: Color = isActive ? .white.opacity(0.9) : .white.opacity(0.35)
        let bgColor: Color = isActive ? .white.opacity(0.14) : .white.opacity(0.04)
        let borderColor: Color = isActive ? .white.opacity(0.15) : .white.opacity(0.08)
        let weight: Font.Weight = isActive ? .semibold : .regular

        Text(group.name)
            .font(.system(size: 11, weight: weight))
            .foregroundStyle(textColor)
            .padding(.horizontal, 12)
            .frame(height: 26)
            .background(bgColor)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(borderColor, lineWidth: 0.5))
            .onTapGesture(count: 2) {
                editName = group.name
                editingIndex = index
            }
            .onTapGesture(count: 1) {
                viewModel.switchGroup(to: index)
            }
    }

    // MARK: - Inline edit pill

    private func inlineEditPill(index: Int) -> some View {
        HStack(spacing: 4) {
            TextField("", text: $editName)
                .textFieldStyle(.plain)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.9))
                .frame(width: 72)
                .onChange(of: editName) { newValue in
                    if newValue.count > 12 {
                        editName = String(newValue.prefix(12))
                    }
                }
                .onSubmit {
                    commitAndClose(index: index)
                }

            Text("\(editName.count)/12")
                .font(.system(size: 9, weight: .regular))
                .foregroundStyle(.white.opacity(0.3))
                .monospacedDigit()
                .fixedSize()

            if viewModel.groups.count > 1 {
                Button {
                    showDeleteConfirm = true
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.white.opacity(0.35))
                }
                .buttonStyle(.plain)
                .alert("Delete group?", isPresented: $showDeleteConfirm) {
                    Button("Cancel", role: .cancel) {}
                    Button("Delete", role: .destructive) {
                        let idx = index
                        editingIndex = nil
                        viewModel.deleteGroup(at: idx)
                    }
                } message: {
                    Text("This will remove \"\(viewModel.groups.indices.contains(index) ? viewModel.groups[index].name : "this group")\" and all its cities.")
                }
            }
        }
        .padding(.horizontal, 10)
        .frame(height: 26)
        .background(Color.white.opacity(0.14))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 0.5))
    }

    // MARK: - Add button

    private var addButton: some View {
        Button {
            viewModel.addGroup()
        } label: {
            Text("+")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.3))
                .padding(.horizontal, 10)
                .frame(height: 26)
                .background(Color.white.opacity(0.04))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.white.opacity(0.08), lineWidth: 0.5))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func commitAndClose(index: Int) {
        let trimmed = editName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            viewModel.renameGroup(at: index, to: trimmed)
        }
        editingIndex = nil
    }
}
