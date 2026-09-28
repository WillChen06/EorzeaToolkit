import CoreGraphics

/// Sizes are local to the editor, including when it occupies a split-view detail column.
struct SkillRotationEditorLayout {
    let isHorizontal: Bool
    let rotationSize: CGSize
    let selectionSize: CGSize
    let dividerSize: CGSize

    init(size: CGSize, minimumPaneWidth: CGFloat, isAccessibilitySize: Bool) {
        let width = max(0, size.width)
        let height = max(0, size.height)
        isHorizontal = !isAccessibilitySize && width >= 2 * minimumPaneWidth + 1

        if isHorizontal {
            let paneWidth = max(0, width - 1) / 2
            rotationSize = CGSize(width: paneWidth, height: height)
            selectionSize = rotationSize
            dividerSize = CGSize(width: 1, height: height)
        } else {
            let dividerHeight = min(1, height)
            let contentHeight = height - dividerHeight
            rotationSize = CGSize(width: width, height: contentHeight * 0.4)
            selectionSize = CGSize(width: width, height: contentHeight * 0.6)
            dividerSize = CGSize(width: width, height: dividerHeight)
        }
    }
}
