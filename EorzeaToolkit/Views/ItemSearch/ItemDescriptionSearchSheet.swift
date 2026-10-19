import SwiftUI

/// Describes the item to find in one sentence, and turns it into the item search's filter and
/// search text (prompts/item-description-search.md, 「描述搜尋畫面」).
struct ItemDescriptionSearchSheet: View {
    let viewModel: ItemSearchViewModel
    @FocusState private var isSentenceFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(
                        text: sentence,
                        prompt: Text(L10n.ItemSearch.DescriptionSearch.placeholder),
                        axis: .vertical
                    ) {
                        Text(L10n.ItemSearch.DescriptionSearch.title)
                    }
                    .lineLimit(2...6)
                    .submitLabel(.search)
                    .onSubmit(submit)
                    .focused($isSentenceFocused)
                    .disabled(viewModel.isParsingDescription)
                } footer: {
                    Text(L10n.ItemSearch.DescriptionSearch.hint)
                }
                .appThemedListRow()

                if let availabilityText {
                    Section {
                        Label(availabilityText, systemImage: "exclamationmark.circle")
                    }
                    .appThemedListRow()
                }

                if viewModel.isParsingDescription {
                    Section {
                        HStack(spacing: 8) {
                            ProgressView()
                            Text(L10n.ItemSearch.DescriptionSearch.parsing)
                                .foregroundStyle(AppTheme.mutedInk)
                        }
                    }
                    .appThemedListRow()
                } else if let messageText {
                    Section {
                        Label(messageText, systemImage: "info.circle")
                    }
                    .appThemedListRow()
                }
            }
            .appThemedScrollContent()
            .navigationTitle(L10n.ItemSearch.DescriptionSearch.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Common.cancel) {
                        viewModel.closeDescriptionSearch()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.Common.search, action: submit)
                        .disabled(!viewModel.canSubmitDescription)
                }
            }
            .appThemedScreen(tint: HomeFeature.itemSearch.accent)
        }
        .task {
            // Focusing as the sheet or popover appears is ignored; a moment later it holds.
            try? await Task.sleep(nanoseconds: 300_000_000)
            isSentenceFocused = true
        }
    }

    /// Long sentences wrap, but the field never breaks a line: the return key searches.
    private var sentence: Binding<String> {
        Binding(
            get: { viewModel.descriptionSentence },
            set: { newValue in
                let edit = ItemDescriptionInput.edit(from: viewModel.descriptionSentence, to: newValue)
                viewModel.descriptionSentence = edit.text
                if edit.submits {
                    submit()
                }
            }
        )
    }

    private func submit() {
        viewModel.submitDescription()
    }

    private var availabilityText: LocalizedStringKey? {
        switch viewModel.descriptionSearchAvailability {
        case .available:
            return nil
        case .appleIntelligenceNotEnabled:
            return L10n.ItemSearch.DescriptionSearch.appleIntelligenceNotEnabled
        case .modelNotReady:
            return L10n.ItemSearch.DescriptionSearch.modelNotReady
        case .unavailable:
            return L10n.ItemSearch.DescriptionSearch.unavailable
        }
    }

    private var messageText: LocalizedStringKey? {
        switch viewModel.descriptionSearchMessage {
        case .notAnItemQuery:
            return L10n.ItemSearch.DescriptionSearch.notAnItemQuery
        case .nothingFound:
            return L10n.ItemSearch.DescriptionSearch.nothingFound
        case .failed:
            return L10n.ItemSearch.DescriptionSearch.failed
        case nil:
            return nil
        }
    }
}
