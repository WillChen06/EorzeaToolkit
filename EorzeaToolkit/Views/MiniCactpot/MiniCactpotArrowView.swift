import SwiftUI

struct MiniCactpotArrowView: View {
    let line: MiniCactpotLine
    let isHighlighted: Bool

    var body: some View {
        Text(line.arrowSymbol)
            .font(.headline.weight(.bold))
            .foregroundStyle(isHighlighted ? .orange : .secondary)
            .frame(width: 34, height: 34)
            .background(
                Circle()
                    .fill(isHighlighted ? Color.orange.opacity(0.18) : Color.clear)
            )
            .overlay(
                Circle()
                    .stroke(isHighlighted ? Color.orange : Color.clear, lineWidth: 2)
            )
            .scaleEffect(isHighlighted ? 1.1 : 1)
            .animation(.snappy(duration: 0.18), value: isHighlighted)
            .accessibilityLabel(line.name)
            .accessibilityAddTraits(isHighlighted ? .isSelected : [])
    }
}

#Preview {
    HStack {
        MiniCactpotArrowView(line: MiniCactpotLine.all[0], isHighlighted: false)
        MiniCactpotArrowView(line: MiniCactpotLine.all[6], isHighlighted: true)
    }
}
