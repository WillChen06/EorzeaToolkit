import SwiftUI

struct ItemSearchView: View {
    @State private var viewModel = ItemSearchViewModel()

    var body: some View {
        Group {
            switch viewModel.loadState {
            case .idle, .loading:
                ProgressView("載入道具資料")
                    .navigationTitle("道具搜尋")
            case .loaded:
                searchContent
                    .navigationTitle("道具搜尋")
            case .failed(let message):
                ContentUnavailableView(
                    "無法載入道具資料",
                    systemImage: "exclamationmark.triangle",
                    description: Text(message)
                )
                .navigationTitle("道具搜尋")
            }
        }
        .searchable(
            text: Binding(
                get: { viewModel.query },
                set: { viewModel.updateSearchQuery($0) }
            ),
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "輸入道具名稱..."
        )
        .task {
            viewModel.loadItems()
        }
    }

    @ViewBuilder
    private var searchContent: some View {
        if viewModel.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            ContentUnavailableView(
                "搜尋道具",
                systemImage: "magnifyingglass",
                description: Text("輸入道具名稱開始搜尋")
            )
        } else if viewModel.results.isEmpty {
            if viewModel.isSearching {
                ProgressView("搜尋中")
            } else {
                ContentUnavailableView(
                    "找不到道具",
                    systemImage: "shippingbox",
                    description: Text("請試著輸入其他名稱")
                )
            }
        } else {
            List {
                ForEach(viewModel.results) { item in
                    NavigationLink(destination: ItemDetailView(item: item)) {
                        ItemSearchRow(item: item)
                    }
                }

                if viewModel.hiddenResultCount > 0 {
                    Button {
                        viewModel.loadMoreResults()
                    } label: {
                        VStack(spacing: 4) {
                            Text("載入更多")
                                .font(.subheadline.weight(.semibold))

                            Text("已顯示 \(viewModel.results.count) / \(viewModel.totalMatchCount) 筆，還有 \(viewModel.hiddenResultCount) 筆")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .buttonStyle(.plain)
                        .listRowBackground(Color.clear)
                }
            }
            .overlay(alignment: .topTrailing) {
                if viewModel.isSearching {
                    ProgressView()
                        .controlSize(.small)
                        .padding()
                }
            }
        }
    }
}

private struct ItemSearchRow: View {
    let item: Item

    var body: some View {
        HStack(spacing: 12) {
            ItemIconView(item: item, size: 42)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.displayName)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text("iLv \(item.ilvl)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct ItemDetailView: View {
    let item: Item

    var body: some View {
        List {
            Section {
                VStack(spacing: 16) {
                    ItemIconView(item: item, size: 96)

                    VStack(spacing: 6) {
                        Text(item.displayName)
                            .font(.title2.weight(.semibold))
                            .multilineTextAlignment(.center)

                        Text("iLv \(item.ilvl)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }

            Section("後續擴充") {
                Label("取得方式、配方、採集與市場價格將在後續 Phase 補上", systemImage: "clock")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(item.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ItemIconView: View {
    let item: Item
    let size: CGFloat

    var body: some View {
        AsyncImage(url: item.iconURL) { phase in
            switch phase {
            case .empty:
                placeholder
            case .success(let image):
                image
                    .resizable()
                    .scaledToFit()
                    .padding(size * 0.08)
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            case .failure:
                placeholder
            @unknown default:
                placeholder
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    private var placeholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(.blue.opacity(0.12))

            Image(systemName: "shippingbox.fill")
                .font(.system(size: size * 0.46, weight: .semibold))
                .foregroundStyle(.blue)
        }
    }
}

#Preview {
    NavigationStack {
        ItemSearchView()
    }
}
