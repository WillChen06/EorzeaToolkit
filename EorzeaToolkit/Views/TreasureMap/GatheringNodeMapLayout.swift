import Foundation

struct GatheringNodeMapLayout {
    let isHorizontal: Bool
    let spacing: CGFloat
    let mapSize: CGSize
    let informationSize: CGSize

    init(availableSize: CGSize, minimumMapWidth: CGFloat = 320,
         minimumInformationWidth: CGFloat = 240, isAccessibilitySize: Bool) {
        let width = max(0, availableSize.width)
        let height = max(0, availableSize.height)
        let minimumMap = max(0, minimumMapWidth)
        let minimumInformation = max(0, minimumInformationWidth)
        isHorizontal = !isAccessibilitySize && width >= minimumMap + 16 + minimumInformation

        if isHorizontal {
            spacing = 16
            let contentWidth = width - spacing
            let informationWidth = min(contentWidth, min(max(contentWidth * 0.35, minimumInformation), minimumInformation * 4 / 3))
            mapSize = CGSize(width: contentWidth - informationWidth, height: height)
            informationSize = CGSize(width: informationWidth, height: height)
        } else {
            spacing = min(16, height)
            let contentHeight = height - spacing
            let mapHeight = min(width, contentHeight * 0.65)
            mapSize = CGSize(width: width, height: mapHeight)
            informationSize = CGSize(width: width, height: contentHeight - mapHeight)
        }
    }

    static func squareSide(in size: CGSize) -> CGFloat {
        max(0, min(size.width, size.height))
    }
}

enum GatheringMapProjection {
    static func position(x: Double, y: Double, sizeFactor: Int? = nil, mapSize: CGFloat) -> CGPoint {
        let factor = Double(sizeFactor ?? 100)
        return CGPoint(
            x: (x - 1) * factor / 100 / 41 * mapSize,
            y: (y - 1) * factor / 100 / 41 * mapSize
        )
    }
}
