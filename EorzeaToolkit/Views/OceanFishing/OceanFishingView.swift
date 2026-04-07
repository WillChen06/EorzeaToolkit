import SwiftUI

struct OceanFishingView: View {
    @State private var viewModel = OceanFishingViewModel()

    var body: some View {
        List {
            ForEach(viewModel.routes) { route in
                Section(route.name) {
                    ForEach(route.stops) { stop in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(stop.zone)
                                .font(.headline)
                            Text(stop.zoneEn)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            ForEach(stop.fish) { fish in
                                HStack {
                                    Text(fish.name)
                                    Spacer()
                                    Text("餌：\(fish.bait)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("海釣")
        .task {
            viewModel.loadRoutes()
        }
    }
}

#Preview {
    NavigationStack {
        OceanFishingView()
    }
}
