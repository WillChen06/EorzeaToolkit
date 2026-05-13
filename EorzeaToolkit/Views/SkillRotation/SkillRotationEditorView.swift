import SwiftUI
import UniformTypeIdentifiers

private enum SkillRotationCategory: String, CaseIterable, Identifiable {
    case all
    case weaponskill
    case spell
    case ability
    case item

    var id: String { rawValue }

    var label: String {
        switch self {
        case .all: return "全部"
        case .weaponskill: return SkillCategory.weaponskill.label
        case .spell: return SkillCategory.spell.label
        case .ability: return SkillCategory.ability.label
        case .item: return "道具"
        }
    }

    var skillCategory: SkillCategory? {
        switch self {
        case .weaponskill: return .weaponskill
        case .spell: return .spell
        case .ability: return .ability
        case .all, .item: return nil
        }
    }
}

struct SkillRotationEditorView: View {
    let job: BattleJob
    @Bindable var viewModel: SkillRotationViewModel

    @State private var selectedLevel: SkillRotationLevel = .defaultLevel
    @State private var selectedCategory: SkillRotationCategory = .all

    private let columns = [GridItem(.adaptive(minimum: 56), spacing: 10)]
    private let rotationColumns = [GridItem(.adaptive(minimum: 60), spacing: 8, alignment: .leading)]

    private var filteredActions: [BattleAction] {
        switch selectedCategory {
        case .all:
            return viewModel.actions(for: job, level: selectedLevel, category: nil)
        case .item:
            return []
        case .weaponskill, .spell, .ability:
            return viewModel.actions(for: job, level: selectedLevel, category: selectedCategory.skillCategory)
        }
    }

    private var filteredTinctures: [Tincture] {
        switch selectedCategory {
        case .all, .item:
            return viewModel.tinctures(for: job)
        case .weaponskill, .spell, .ability:
            return []
        }
    }

    private var rotation: [RotationSlot] {
        viewModel.rotation(for: job.id, level: selectedLevel)
    }

    private var showsTinctureSectionSeparator: Bool {
        selectedCategory == .all && !filteredActions.isEmpty && !filteredTinctures.isEmpty
    }

    var body: some View {
        GeometryReader { geometry in
            let availableHeight = geometry.size.height
            let availableWidth = geometry.size.width
            let minSkillGridHeight = availableHeight * 0.3
            let filterSectionHeight: CGFloat = 96
            let maxRotationBarHeight = max(0, availableHeight - minSkillGridHeight - filterSectionHeight)

            VStack(spacing: 0) {
                rotationBar(availableWidth: availableWidth, maxHeight: maxRotationBarHeight)

                Divider()

                levelFilter
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .padding(.bottom, 6)

                categoryFilter
                    .padding(.horizontal)
                    .padding(.bottom, 10)

                Divider()

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 14) {
                        actionGrid
                        tinctureGrid
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
                        viewModel.clearRotation(for: job.id, level: selectedLevel)
                    } label: {
                        Image(systemName: "trash")
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var actionGrid: some View {
        if !filteredActions.isEmpty {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(filteredActions) { action in
                    SkillGridIcon(item: .action(action))
                        .onTapGesture {
                            viewModel.addSkill(action, to: job.id, level: selectedLevel)
                        }
                        .contextMenu {
                            Button {
                                viewModel.addSkill(action, to: job.id, level: selectedLevel)
                            } label: {
                                Label("加入 Rotation", systemImage: "plus.circle")
                            }
                        } preview: {
                            RotationItemDetailCard(item: .action(action), statName: nil)
                        }
                }
            }
        }
    }

    @ViewBuilder
    private var tinctureGrid: some View {
        if !filteredTinctures.isEmpty {
            if showsTinctureSectionSeparator {
                Text("道具")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 4)
            }

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(filteredTinctures) { tincture in
                    SkillGridIcon(item: .tincture(tincture))
                        .onTapGesture {
                            viewModel.addTincture(tincture, to: job.id, level: selectedLevel)
                        }
                        .contextMenu {
                            Button {
                                viewModel.addTincture(tincture, to: job.id, level: selectedLevel)
                            } label: {
                                Label("加入 Rotation", systemImage: "plus.circle")
                            }
                        } preview: {
                            RotationItemDetailCard(
                                item: .tincture(tincture),
                                statName: viewModel.statName(for: tincture)
                            )
                        }
                }
            }
        }
    }

    // MARK: - Filters

    @ViewBuilder
    private var levelFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(SkillRotationLevel.displayCases) { level in
                    filterChip(label: level.label, isSelected: selectedLevel == level) {
                        selectedLevel = level
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(SkillRotationCategory.allCases) { category in
                    filterChip(label: category.label, isSelected: selectedCategory == category) {
                        selectedCategory = category
                    }
                }
                Spacer(minLength: 0)
            }
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
        let cellWidth: CGFloat = 60
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
                Text("施放順序 \(selectedLevel.label)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text("(\(rotation.count))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                if !rotation.isEmpty {
                    Text("長按拖曳可排序")
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
                HStack(spacing: 8) {
                    RotationSlotView(slot: slot, iconSize: 44) {
                        viewModel.removeSlot(id: slot.id, from: job.id, level: selectedLevel)
                    }
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .opacity(index == rotation.count - 1 ? 0 : 1)
                }
                .id(slot.id)
                .draggable(slot.id.uuidString) {
                    SkillGridIcon(item: slot.item)
                        .frame(width: 44, height: 44)
                }
                .dropDestination(for: String.self) { items, _ in
                    guard let droppedIDString = items.first,
                          let droppedID = UUID(uuidString: droppedIDString) else {
                        return false
                    }
                    viewModel.moveSlot(in: job.id, level: selectedLevel, fromID: droppedID, toIndex: index)
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
    let item: RotationItem

    var body: some View {
        AsyncImage(url: item.iconURL) { phase in
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
                Image(systemName: placeholderImageName)
                    .foregroundStyle(.secondary)
            }
    }

    private var placeholderImageName: String {
        switch item {
        case .action: return "sparkles"
        case .tincture: return "cross.vial"
        }
    }
}

// MARK: - Rotation Slot

struct RotationSlotView: View {
    let slot: RotationSlot
    var iconSize: CGFloat = 56
    var onDelete: (() -> Void)? = nil

    var body: some View {
        ZStack(alignment: .topTrailing) {
            AsyncImage(url: slot.item.iconURL) { phase in
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

            if let onDelete {
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, .red)
                        .shadow(color: .black.opacity(0.2), radius: 1, y: 1)
                }
                .buttonStyle(.plain)
                .offset(x: 6, y: -6)
            }
        }
    }
}

// MARK: - Rotation Item Detail Card

struct RotationItemDetailCard: View {
    let item: RotationItem
    let statName: String?

    var body: some View {
        switch item {
        case .action(let action):
            SkillDetailCard(action: action)
        case .tincture(let tincture):
            TinctureDetailCard(tincture: tincture, statName: statName ?? tincture.stat)
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

// MARK: - Tincture Detail Card

struct TinctureDetailCard: View {
    let tincture: Tincture
    let statName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                AsyncImage(url: tincture.iconURL) { phase in
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
                    Text(tincture.displayName)
                        .font(.headline)
                    HStack(spacing: 6) {
                        tag("道具", color: .purple)
                        tag("iLv.\(tincture.itemLevel)", color: .secondary)
                    }
                }
                Spacer()
            }

            Divider()

            statBlock(title: "效果", value: "\(statName) +10%")
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
}
