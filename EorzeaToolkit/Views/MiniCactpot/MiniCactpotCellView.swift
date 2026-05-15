import SwiftUI

struct MiniCactpotCellView: View {
    let value: Int?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(value == nil ? Color(.secondarySystemGroupedBackground) : Color.accentColor.opacity(0.16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(value == nil ? Color.secondary.opacity(0.25) : Color.accentColor, lineWidth: 1)
                    )

                Text(value.map(String.init) ?? "")
                    .font(.title2.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.primary)
            }
            .aspectRatio(1, contentMode: .fit)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(value.map { "數字 \($0)" } ?? "空格")
        .accessibilityHint("點兩下選擇數字")
    }
}

#Preview {
    HStack {
        MiniCactpotCellView(value: nil) {}
        MiniCactpotCellView(value: 7) {}
    }
    .padding()
}
