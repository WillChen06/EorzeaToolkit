import SwiftUI
import UniformTypeIdentifiers
import ComposableArchitecture

struct SkillRotationEditorView: View {
    let store: StoreOf<SkillRotationEditorFeature>

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .headline) private var minimumPaneWidth: CGFloat = 300
    
    private let columns = [GridItem(.adaptive(minimum: 56), spacing: 10)]
    private let rotationColumns = [GridItem(.adaptive(minimum: 60), spacing: 8, alignment: .leading)]

    var body: some View {
        GeometryReader { geometry in
            let sizing = SkillRotationEditorLayout(
                size: geometry.size,
                minimumPaneWidth: minimumPaneWidth,
                isAccessibilitySize: dynamicTypeSize.isAccessibilitySize
            )
            let layout = sizing.isHorizontal
                ? AnyLayout(HStackLayout(alignment: .top, spacing: 0))
                : AnyLayout(VStackLayout(alignment: .leading, spacing: 0))

            // Change placement, not the identity of either editing panel.
            layout {
                rotationPanel
                    .frame(width: sizing.rotationSize.width, height: sizing.rotationSize.height)

                AppTheme.gold.opacity(0.25)
                    .frame(width: sizing.dividerSize.width, height: sizing.dividerSize.height)

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 14) {
                        levelFilter
                        categoryFilter
                        Divider().overlay(AppTheme.gold.opacity(0.25))
                        actionGrid
                        tinctureGrid
                    }
                    .padding(12)
                }
                .frame(width: sizing.selectionSize.width, height: sizing.selectionSize.height)
            }
        }
        .appThemedBackground()
        .navigationTitle(L10n.SkillRotation.editorTitle(jobName: store.job.displayName, abbreviation: store.job.abbreviation))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if !store.rotation.isEmpty {
                    Button(L10n.Common.clear, systemImage: "trash", role: .destructive) {
                        store.send(.clearTapped)
                    }
                    .labelStyle(.iconOnly)
                }
            }
        }
        .appThemedScreen(tint: HomeFeature.skillRotation.accent)
    }

    @ViewBuilder
    private var actionGrid: some View {
        if !store.filteredActions.isEmpty {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(store.filteredActions) { action in
                    SkillGridIcon(item: .action(action))
                        .onTapGesture {
                            store.send(.actionAdded(action))
                        }
                        .contextMenu {
                            Button {
                                store.send(.actionAdded(action))
                            } label: {
                                Label(L10n.SkillRotation.addToRotation, systemImage: "plus.circle")
                            }
                        } preview: {
                            RotationItemDetailCard(item: .action(action), statName: nil, level: store.selectedLevel)
                        }
                }
            }
        }
    }

    @ViewBuilder
    private var tinctureGrid: some View {
        if !store.filteredTinctures.isEmpty {
            if store.showsTinctureSectionSeparator {
                Text(L10n.SkillRotation.itemSection)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.mutedInk)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 4)
            }

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(store.filteredTinctures) { tincture in
                    SkillGridIcon(item: .tincture(tincture))
                        .onTapGesture {
                            store.send(.tinctureAdded(tincture))
                        }
                        .contextMenu {
                            Button {
                                store.send(.tinctureAdded(tincture))
                            } label: {
                                Label(L10n.SkillRotation.addToRotation, systemImage: "plus.circle")
                            }
                        } preview: {
                            RotationItemDetailCard(
                                item: .tincture(tincture),
                                statName: store.state.statName(for: tincture),
                                level: store.selectedLevel
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
                    filterChip(label: level.label, isSelected: store.selectedLevel == level) {
                        store.send(.levelSelected(level))
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
                    filterChip(label: category.label, isSelected: store.selectedCategory == category) {
                        store.send(.categorySelected(category))
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
                .fixedSize(horizontal: false, vertical: true)
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

    private var rotationPanel: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 6) {
                    VStack(alignment: .leading, spacing: 4) {
                        rotationTitle
                        rotationCount
                        rotationReorderHint
                    }
                    .padding(.horizontal)

                    if store.rotation.isEmpty {
                        Text(L10n.SkillRotation.emptyRotationHint)
                            .font(.footnote)
                            .foregroundStyle(AppTheme.mutedInk)
                            .frame(maxWidth: .infinity)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(20)
                    } else {
                        rotationGrid
                    }

                    // A full-width target prevents scrolling toward an individual grid column.
                    Color.clear
                        .frame(height: 1)
                        .frame(maxWidth: .infinity)
                        .id("rotationEnd")
                }
                .padding(.top, 10)
            }
            .onChange(of: store.rotation.count) { oldValue, newValue in
                guard newValue > oldValue else { return }
                // Keep short content in place and reveal only the vertical overflow.
                proxy.scrollTo("rotationEnd")
            }
        }
        // Stay out of the horizontal safe area, such as iPhone Duo's trailing toolbar column.
        .background(AppTheme.surface, ignoresSafeAreaEdges: .vertical)
    }

    private var rotationTitle: some View {
        Text(L10n.SkillRotation.rotationTitle(level: store.selectedLevel.label))
            .font(.subheadline)
            .fontWeight(.semibold)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var rotationCount: some View {
        Text(L10n.SkillRotation.rotationCount(store.rotation.count))
            .font(.caption)
            .foregroundStyle(AppTheme.mutedInk)
    }

    @ViewBuilder
    private var rotationReorderHint: some View {
        if !store.rotation.isEmpty {
            Text(L10n.SkillRotation.reorderHint)
                .font(.caption)
                .foregroundStyle(AppTheme.mutedInk)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var rotationGrid: some View {
        LazyVGrid(columns: rotationColumns, alignment: .leading, spacing: 8) {
            ForEach(Array(store.rotation.enumerated()), id: \.element.id) { index, slot in
                HStack(spacing: 8) {
                    RotationSlotView(slot: slot, iconSize: 44) {
                        store.send(.slotRemoved(id: slot.id))
                    }
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppTheme.mutedInk)
                        .opacity(index == store.rotation.count - 1 ? 0 : 1)
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
                    store.send(.slotMoved(id: droppedID, toIndex: index))
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
            .padding(.top, onDelete == nil ? 0 : 6)
            .padding(.trailing, onDelete == nil ? 0 : 6)

            if let onDelete {
                Button(action: onDelete) {
                    // The badge sits on the icon's top-trailing corner; the tap target stays 44pt.
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, .red)
                        .shadow(color: .black.opacity(0.2), radius: 1, y: 1)
                        .frame(width: 44, height: 44, alignment: .topTrailing)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Rotation Item Detail Card

struct RotationItemDetailCard: View {
    let item: RotationItem
    let statName: String?
    /// The level selected in the editor; a skill's description depends on it.
    let level: SkillRotationLevel

    var body: some View {
        switch item {
        case .action(let action):
            SkillDetailCard(action: action, level: level)
        case .tincture(let tincture):
            TinctureDetailCard(tincture: tincture, statName: statName ?? tincture.stat)
        }
    }
}

// MARK: - Skill Detail Card

struct SkillDetailCard: View {
    let action: BattleAction
    let level: SkillRotationLevel

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
            .fixedSize(horizontal: false, vertical: true)

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
            .fixedSize(horizontal: false, vertical: true)

            if let description = action.description(at: level.rawValue), !description.isEmpty {
                Divider()
                // The context menu can lay the preview out narrower or shorter than its ideal
                // size and clips what overflows; shrink the description to fit instead.
                ViewThatFits(in: .vertical) {
                    descriptionText(description)
                        .fixedSize(horizontal: false, vertical: true)
                    descriptionText(description)
                        .minimumScaleFactor(0.6)
                }
            }
        }
        .padding(16)
        .frame(minWidth: 280, maxWidth: 360, alignment: .leading)
        .appThemedCard()
    }

    private func descriptionText(_ description: String) -> some View {
        Text(description)
            .font(.footnote)
            .foregroundStyle(AppTheme.ink)
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
