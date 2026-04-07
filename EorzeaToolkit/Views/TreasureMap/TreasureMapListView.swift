import SwiftUI

struct TreasureMapListView: View {
    @State private var viewModel = TreasureMapViewModel()

    var body: some View {
        List(viewModel.maps) { map in
            NavigationLink(destination: TreasureMapDetailView(map: map)) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(map.name)
                        .font(.headline)
                    Text("Lv.\(map.level) · \(map.locations.count) 個地點")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("藏寶圖")
        .task {
            viewModel.loadMaps()
        }
    }
}

#Preview {
    NavigationStack {
        TreasureMapListView()
    }
}
