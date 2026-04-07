import SwiftUI

struct ProgressTrackerView: View {
    var body: some View {
        ContentUnavailableView(
            "尚未追蹤任何進度",
            systemImage: "checklist",
            description: Text("在藏寶圖或發光武器頁面開始追蹤進度")
        )
        .navigationTitle("進度追蹤")
    }
}

#Preview {
    NavigationStack {
        ProgressTrackerView()
    }
}
