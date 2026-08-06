import SwiftUI

struct ObtainSourceSection: View {
    let sources: [ObtainSource]
    let onSelect: (ObtainSource) -> Void

    var body: some View {
        if sources.count >= 2 {
            Section(L10n.Obtain.sectionTitle) {
                ForEach(sources) { source in
                    Button {
                        onSelect(source)
                    } label: {
                        HStack(spacing: 12) {
                            Label(source.title, systemImage: source.systemImage)
                                .font(.subheadline.weight(.semibold))

                            Spacer(minLength: 12)

                            Image(systemName: "arrow.down")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .accessibilityHidden(true)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint(Text(L10n.Obtain.jumpHint(sourceTitle: source.title)))
                }
            }
        }
    }
}
