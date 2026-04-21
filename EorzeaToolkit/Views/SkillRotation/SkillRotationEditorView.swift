import SwiftUI
import UniformTypeIdentifiers

struct SkillRotationEditorView: View {
    let job: BattleJob
    @Bindable var viewModel: SkillRotationViewModel

    @State private var selectedCategory: SkillCategory? = nil

    private let columns = [GridItem(.adaptive(minimum: 56), spacing: 10)]
    private let rotationColumns = [GridItem(.adaptive(minimum: 48), spacing: 8)]

    private var filteredActions: [BattleAction] {
        viewModel.actions(for: job, category: selectedCategory)
    }

    private var rotation: [RotationSlot] {
        viewModel.rotation(for: job.id)
    }

    var body: some View {
        GeometryReader { geometry in
            let availableHeight = geometry.size.height
            let availableWidth = geometry.size.width
            let minSkillGridHeight = availableHeight * 0.3
            let categoryFilterSectionHeight: CGFloat = 52
            let maxRotationBarHeight = max(0, availableHeight - minSkillGridHeight - categoryFilterSectionHeight)

            VStack(spacing: 0) {
                rotationBar(availableWidth: availableWidth, maxHeight: maxRotationBarHeight)

                Divider()

                categoryFilter
                    .padding(.horizontal)
                    .padding(.vertical, 10)

                Divider()

                ScrollView {
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(filteredActions) { action in
                            SkillGridIcon(action: action)
                                .onTapGesture {
                                    viewModel.addSkill(action, to: job.id)
                                }
                                .contextMenu {
                                    Button {
                                        viewModel.addSkill(action, to: job.id)
                                    } label: {
                                        Label("加入 Rotation", systemImage: "plus.circle")
                                    }
                                } preview: {
                                    SkillDetailCard(action: action)
                                }
                        }
                    }
                    .padding(12)
                }
            }
        }
        .navigationTitle("\(job.displayName) · \(job.abbreviation)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if !rotation.isEmpty {
                    Button(role: .destructive) {
                        viewModel.clearRotation(for: job.id)
                    } label: {
                        Image(systemName: "trash")
                    }
                }
            }
        }
    }

    // MARK: - Category filter

    @ViewBuilder
    private var categoryFilter: some View {
        let available = job.availableCategories
        HStack(spacing: 8) {
            filterChip(label: "全部", isSelected: selectedCategory == nil) {
                selectedCategory = nil
            }
            ForEach(available) { category in
                filterChip(label: category.label, isSelected: selectedCategory == category) {
                    selectedCategory = (selectedCategory == category) ? nil : category
                }
            }
            Spacer()
        }
    }

    private func filterChip(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor.opacity(0.2) : Color(.systemGray6))
                .foregroundStyle(isSelected ? Color.accentColor : .primary)
                .clipShape(Capsule())
                .overlay(
                    Capsule().strokeBorder(
                        isSelected ? Color.accentColor : Color.clear,
                        lineWidth: 1
                    )
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Rotation bar

    private func rotationBar(availableWidth: CGFloat, maxHeight: CGFloat) -> some View {
        let headerApproxHeight: CGFloat = 30
        let cellWidth: CGFloat = 48
        let cellHeight: CGFloat = 44
        let spacing: CGFloat = 8
        let gridHPadding: CGFloat = 32
        let gridVPadding: CGFloat = 20

        let gridAvailableWidth = max(0, availableWidth - gridHPadding)
        let columnsPerRow = max(1, Int((gridAvailableWidth + spacing) / (cellWidth + spacing)))
        let rowCount = rotation.isEmpty ? 0 : Int(ceil(Double(rotation.count) / Double(columnsPerRow)))

        let rowPitch = cellHeight + spacing
        let usableHeightForRows = max(0, maxHeight - headerApproxHeight - gridVPadding)
        let visibleRows = max(1, Int((usableHeightForRows + spacing) / rowPitch))
        let alignedGridHeight = CGFloat(visibleRows) * cellHeight
            + CGFloat(max(0, visibleRows - 1)) * spacing
            + gridVPadding
        let needsScroll = rowCount > visibleRows

        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("施放順序")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text("(\(rotation.count))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                if !rotation.isEmpty {
                    Text("長按可刪除・拖曳可排序")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal)

            if rotation.isEmpty {
                Text("點選下方技能加入施放順序")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else if needsScroll {
                ScrollViewReader { proxy in
                    ScrollView {
                        rotationGrid
                    }
                    .frame(maxHeight: alignedGridHeight)
                    .onChange(of: rotation.count) { oldValue, newValue in
                        guard newValue > oldValue, let lastID = rotation.last?.id else { return }
                        withAnimation {
                            proxy.scrollTo(lastID, anchor: .bottom)
                        }
                    }
                }
            } else {
                rotationGrid
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
    }

    private var rotationGrid: some View {
        LazyVGrid(columns: rotationColumns, alignment: .leading, spacing: 8) {
            ForEach(Array(rotation.enumerated()), id: \.element.id) { index, slot in
                RotationSlotView(index: index + 1, slot: slot, iconSize: 44)
                    .id(slot.id)
                    .contextMenu {
                        Button(role: .destructive) {
                            viewModel.removeSlot(id: slot.id, from: job.id)
                        } label: {
                            Label("移除", systemImage: "trash")
                        }
                    }
                    .draggable(slot.id.uuidString) {
                        SkillGridIcon(action: slot.action)
                            .frame(width: 44, height: 44)
                    }
                    .dropDestination(for: String.self) { items, _ in
                        guard let droppedIDString = items.first,
                              let droppedID = UUID(uuidString: droppedIDString) else {
                            return false
                        }
                        viewModel.moveSlot(in: job.id, fromID: droppedID, toIndex: index)
                        return true
                    }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }
}

// MARK: - Skill Grid Icon

struct SkillGridIcon: View {
    let action: BattleAction

    var body: some View {
        AsyncImage(url: action.iconURL) { phase in
            switch phase {
            case .success(let image):
                image.resizable().scaledToFit()
            case .failure:
                placeholder
            default:
                placeholder
            }
        }
        .frame(width: 56, height: 56)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color(.systemGray4), lineWidth: 0.5)
        )
    }

    private var placeholder: some View {
        Color(.systemGray5)
            .overlay {
                Image(systemName: "sparkles")
                    .foregroundStyle(.secondary)
            }
    }
}

// MARK: - Rotation Slot

struct RotationSlotView: View {
    let index: Int
    let slot: RotationSlot
    var iconSize: CGFloat = 56

    var body: some View {
        VStack(spacing: 4) {
            ZStack(alignment: .topLeading) {
                AsyncImage(url: slot.action.iconURL) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFit()
                    default:
                        Color(.systemGray5)
                    }
                }
                .frame(width: iconSize, height: iconSize)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color(.systemGray4), lineWidth: 0.5)
                )

                Text("\(index)")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(Color.accentColor)
                    .clipShape(Capsule())
                    .padding(2)
            }
        }
    }
}

// MARK: - Skill Detail Card

struct SkillDetailCard: View {
    let action: BattleAction

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                AsyncImage(url: action.iconURL) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFit()
                    default:
                        Color(.systemGray5)
                    }
                }
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 4) {
                    Text(action.displayName)
                        .font(.headline)
                    HStack(spacing: 6) {
                        if let cat = action.skillCategory {
                            tag(cat.label, color: categoryColor(cat))
                        }
                        tag("Lv.\(action.level)", color: .secondary)
                    }
                }
                Spacer()
            }

            HStack(spacing: 16) {
                statBlock(title: "距離", value: action.rangeText)
                if let er = action.effectRangeText {
                    statBlock(title: "範圍", value: er)
                }
                statBlock(title: "詠唱", value: action.castText)
                if let rc = action.recastText {
                    statBlock(title: "復唱", value: rc)
                }
            }

            if !action.cleanedDescription.isEmpty {
                Divider()
                Text(action.cleanedDescription)
                    .font(.footnote)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(minWidth: 280, maxWidth: 360, alignment: .leading)
        .background(Color(.systemBackground))
    }

    private func tag(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.caption)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }

    private func statBlock(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.footnote)
                .fontWeight(.medium)
        }
    }

    private func categoryColor(_ category: SkillCategory) -> Color {
        switch category {
        case .weaponskill: return .orange
        case .spell: return .blue
        case .ability: return .green
        }
    }
}
