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
        case .all: return L10n.SkillRotation.allCategoryText
        case .weaponskill: return SkillCategory.weaponskill.label
        case .spell: return SkillCategory.spell.label
        case .ability: return SkillCategory.ability.label
        case .item: return L10n.SkillRotation.itemCategoryText
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

    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @State private var selectedLevel: SkillRotationLevel = .defaultLevel
    @State private var selectedCategory: SkillRotationCategory = .all

    private let columns = [GridItem(.adaptive(minimum: 56), spacing: 10)]
    private let rotationColumns = [GridItem(.adaptive(minimum: 60), spacing: 8, alignment: .leading)]

    private var maxRotationVisibleRows: Int {
        verticalSizeClass == .compact ? 7 : 8
    }

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
            let availableWidth = geometry.size.width

            VStack(spacing: 0) {
                rotationBar(availableWidth: availableWidth, maxVisibleRows: maxRotationVisibleRows)

                Divider()
                    .overlay(AppTheme.gold.opacity(0.25))

                levelFilter
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .padding(.bottom, 6)

                categoryFilter
                    .padding(.horizontal)
                    .padding(.bottom, 10)

                Divider()
                    .overlay(AppTheme.gold.opacity(0.25))

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 14) {
                        actionGrid
                        tinctureGrid
                    }
                    .padding(12)
                }
            }
        }
        .appThemedBackground()
        .navigationTitle(L10n.SkillRotation.editorTitle(jobName: job.displayName, abbreviation: job.abbreviation))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if !rotation.isEmpty {
                    Button(L10n.Common.clear, systemImage: "trash", role: .destructive) {
                        viewModel.clearRotation(for: job.id, level: selectedLevel)
                    }
                    .labelStyle(.iconOnly)
                }
            }
        }
        .appThemedScreen(tint: HomeFeature.skillRotation.accent)
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
                                Label(L10n.SkillRotation.addToRotation, systemImage: "plus.circle")
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
                Text(L10n.SkillRotation.itemSection)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.mutedInk)
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
                                Label(L10n.SkillRotation.addToRotation, systemImage: "plus.circle")
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
                .frame(minHeight: 44)
                .background(isSelected ? HomeFeature.skillRotation.accent.opacity(0.2) : AppTheme.surfaceDepth)
                .foregroundStyle(isSelected ? HomeFeature.skillRotation.accent : AppTheme.ink)
                .clipShape(Capsule())
                .overlay(
                    Capsule().strokeBorder(
                        isSelected ? HomeFeature.skillRotation.accent : AppTheme.gold.opacity(0.2),
                        lineWidth: 1
                    )
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Rotation bar

    private func rotationBar(availableWidth: CGFloat, maxVisibleRows: Int) -> some View {
        let cellWidth: CGFloat = 60
        let cellHeight: CGFloat = 44
        let spacing: CGFloat = 8
        let gridHPadding: CGFloat = 32
        let gridVPadding: CGFloat = 20

        let gridAvailableWidth = max(0, availableWidth - gridHPadding)
        let columnsPerRow = max(1, Int((gridAvailableWidth + spacing) / (cellWidth + spacing)))
        let rowCount = rotation.isEmpty ? 0 : Int(ceil(Double(rotation.count) / Double(columnsPerRow)))

        let visibleRows = min(rowCount, max(1, maxVisibleRows))
        let alignedGridHeight = CGFloat(visibleRows) * cellHeight
            + CGFloat(max(0, visibleRows - 1)) * spacing
            + gridVPadding
        let needsScroll = rowCount > maxVisibleRows

        return VStack(alignment: .leading, spacing: 6) {
            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: 2) {
                        rotationTitle

                        HStack(alignment: .firstTextBaseline) {
                            rotationCount
                            Spacer()
                            rotationReorderHint
                        }
                    }
                } else {
                    HStack(alignment: .firstTextBaseline) {
                        rotationTitle
                        rotationCount
                        Spacer()
                        rotationReorderHint
                    }
                }
            }
            .padding(.horizontal)

            if rotation.isEmpty {
                Text(L10n.SkillRotation.emptyRotationHint)
                    .font(.footnote)
                    .foregroundStyle(AppTheme.mutedInk)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.vertical, 20)
            } else if needsScroll {
                ScrollViewReader { proxy in
                    ScrollView {
                        rotationGrid
                    }
                    .frame(height: alignedGridHeight)
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
        .background(AppTheme.surface)
        .overlay(alignment: .bottom) {
            AppTheme.gold.opacity(0.22)
                .frame(height: 1)
        }
    }

    private var rotationTitle: some View {
        Text(L10n.SkillRotation.rotationTitle(level: selectedLevel.label))
            .font(.subheadline)
            .fontWeight(.semibold)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var rotationCount: some View {
        Text(L10n.SkillRotation.rotationCount(rotation.count))
            .font(.caption)
            .foregroundStyle(AppTheme.mutedInk)
    }

    @ViewBuilder
    private var rotationReorderHint: some View {
        if !rotation.isEmpty {
            Text(L10n.SkillRotation.reorderHint)
                .font(.caption)
                .foregroundStyle(AppTheme.mutedInk)
                .multilineTextAlignment(.trailing)
        }
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
                        .foregroundStyle(AppTheme.mutedInk)
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
        CachedIconImage(url: item.iconURL) {
            placeholder
        }
        .frame(width: 56, height: 56)
        .background(AppTheme.surfaceDepth)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(AppTheme.gold.opacity(0.25), lineWidth: 1)
        )
    }

    private var placeholder: some View {
        AppTheme.surfaceDepth
            .overlay {
                Image(systemName: placeholderImageName)
                    .foregroundStyle(AppTheme.mutedInk)
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
            CachedIconImage(url: slot.item.iconURL) {
                AppTheme.surfaceDepth
            }
            .frame(width: iconSize, height: iconSize)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(AppTheme.gold.opacity(0.25), lineWidth: 1)
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
                .frame(width: 44, height: 44)
            }
        }
        .padding(.top, onDelete == nil ? 0 : 6)
        .padding(.trailing, onDelete == nil ? 0 : 6)
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
                CachedIconImage(url: action.iconURL) {
                    AppTheme.surfaceDepth
                }
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 4) {
                    Text(action.displayName)
                        .font(.headline)
                    HStack(spacing: 6) {
                        if let cat = action.skillCategory {
                            tag(L10n.SkillRotation.skillCategory(cat), color: categoryColor(cat))
                        }
                        tag(L10n.SkillRotation.level(action.level), color: AppTheme.mutedInk)
                    }
                }
                Spacer()
            }

            HStack(spacing: 16) {
                statBlock(title: L10n.SkillRotation.distance, value: action.rangeText)
                if let er = action.effectRangeText {
                    statBlock(title: L10n.SkillRotation.effectRange, value: er)
                }
                statBlock(title: L10n.SkillRotation.cast, value: action.castText)
                if let rc = action.recastText {
                    statBlock(title: L10n.SkillRotation.recast, value: rc)
                }
            }

            if !action.cleanedDescription.isEmpty {
                Divider()
                Text(action.cleanedDescription)
                    .font(.footnote)
                    .foregroundStyle(AppTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(minWidth: 280, maxWidth: 360, alignment: .leading)
        .appThemedCard()
    }

    private func tag(_ text: LocalizedStringKey, color: Color) -> some View {
        Text(text)
            .font(.caption)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }

    private func statBlock(title: LocalizedStringKey, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(AppTheme.mutedInk)
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
                CachedIconImage(url: tincture.iconURL) {
                    AppTheme.surfaceDepth
                }
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 4) {
                    Text(tincture.displayName)
                        .font(.headline)
                    HStack(spacing: 6) {
                        tag(L10n.SkillRotation.itemCategory, color: .purple)
                        tag(L10n.SkillRotation.itemLevel(tincture.itemLevel), color: AppTheme.mutedInk)
                    }
                }
                Spacer()
            }

            Divider()

            statBlock(title: L10n.SkillRotation.effect, value: L10n.SkillRotation.effectValueText(statName: statName))
        }
        .padding(16)
        .frame(minWidth: 280, maxWidth: 360, alignment: .leading)
        .appThemedCard()
    }

    private func tag(_ text: LocalizedStringKey, color: Color) -> some View {
        Text(text)
            .font(.caption)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }

    private func statBlock(title: LocalizedStringKey, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(AppTheme.mutedInk)
            Text(value)
                .font(.footnote)
                .fontWeight(.medium)
        }
    }
}
