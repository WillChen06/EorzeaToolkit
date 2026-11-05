import SwiftUI

extension View {
    /// Presents `content` as an anchored popover in regular space and as a sheet when either
    /// size class is compact.
    ///
    /// The sheet is presented directly instead of through `presentationCompactAdaptation(.sheet)`.
    /// On an iOS 27.0.1 device, swiping that adapted sheet closed and opening it again crashes
    /// with "Attempt to dismiss (null)"; the iOS 27.0 simulator does not reproduce it. Recheck
    /// on newer iOS releases before dropping this workaround.
    func adaptivePopover<Content: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        modifier(AdaptivePopoverModifier(isPresented: isPresented, popoverContent: content))
    }
}

private struct AdaptivePopoverModifier<PopoverContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let popoverContent: () -> PopoverContent

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    private var isCompact: Bool {
        horizontalSizeClass == .compact || verticalSizeClass == .compact
    }

    func body(content: Content) -> some View {
        // Both presentations stay attached so the anchor keeps its identity across a resize;
        // only the one matching the current space reads as presented.
        content
            .sheet(isPresented: presentation(whenCompact: true), content: popoverContent)
            .popover(isPresented: presentation(whenCompact: false), content: popoverContent)
    }

    /// Ignores the dismissal of the presentation a resize just swapped out, so the content
    /// reopens in the other style instead of closing.
    private func presentation(whenCompact: Bool) -> Binding<Bool> {
        Binding(
            get: { isPresented && isCompact == whenCompact },
            set: { newValue in
                guard isCompact == whenCompact else { return }
                isPresented = newValue
            }
        )
    }
}
