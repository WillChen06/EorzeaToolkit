import SwiftUI

struct MarketPriceSection: View {
    let item: Item

    @Environment(MarketPriceSettings.self) private var marketPriceSettings
    @State private var viewModel = MarketPriceViewModel()

    var body: some View {
        Group {
            Section("市場價格") {
                marketScopePicker
                marketStatusContent
            }

            if case .loaded(let marketPrice) = viewModel.loadState {
                MarketListingsSection(listings: marketPrice.listings)
                MarketRecentSalesSection(sales: marketPrice.recentSales)
            }
        }
        .task(id: loadTaskID) {
            viewModel.load(item: item, scope: marketPriceSettings.selectedScope)
        }
    }

    private var loadTaskID: String {
        "\(item.id)-\(marketPriceSettings.selectedScope.id)"
    }

    @ViewBuilder
    private var marketScopePicker: some View {
        if !item.isUntradable {
            @Bindable var settings = marketPriceSettings

            Picker("查詢範圍", selection: $settings.selectedScope) {
                ForEach(MarketPriceScope.allCases) { scope in
                    Text(scope.displayLabel).tag(scope)
                }
            }
            .pickerStyle(.menu)
        }
    }

    @ViewBuilder
    private var marketStatusContent: some View {
        switch viewModel.loadState {
        case .idle, .loading:
            HStack(spacing: 10) {
                ProgressView()
                    .controlSize(.small)

                Text("查詢市場價格")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        case .untradable:
            Label("此道具無法在市場交易", systemImage: "cart.badge.minus")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        case .empty:
            Label("目前無市場資料", systemImage: "chart.line.downtrend.xyaxis")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        case .loaded(let marketPrice):
            MarketPriceSummaryView(item: item, marketPrice: marketPrice)
        case .failed(let message):
            VStack(alignment: .leading, spacing: 10) {
                Label(message, systemImage: "exclamationmark.triangle")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Button {
                    viewModel.load(item: item, scope: marketPriceSettings.selectedScope)
                } label: {
                    Label("重試", systemImage: "arrow.clockwise")
                }
            }
        }
    }
}

private struct MarketPriceSummaryView: View {
    let item: Item
    let marketPrice: MarketPriceData

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(marketPrice.scope.displayLabel, systemImage: "globe.asia.australia")
                .font(.subheadline.weight(.semibold))

            VStack(spacing: 10) {
                MarketPriceMetricRow(
                    title: item.canBeHq ? "NQ 最低價" : "當前最低價",
                    value: marketPriceText(marketPrice.lowestPriceNQ)
                )

                if item.canBeHq {
                    MarketPriceMetricRow(
                        title: "HQ 最低價",
                        value: marketPriceText(marketPrice.lowestPriceHQ)
                    )
                }

                MarketPriceMetricRow(
                    title: "近期平均成交價",
                    value: marketPriceText(marketPrice.averagePrice)
                )
            }

            if item.canBeHq, marketPrice.averagePriceNQ != nil || marketPrice.averagePriceHQ != nil {
                HStack(spacing: 8) {
                    Text("NQ \(marketPriceText(marketPrice.averagePriceNQ))")
                    Text("HQ \(marketPriceText(marketPrice.averagePriceHQ))")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            if let lastUploadDate = marketPrice.lastUploadDate {
                Text("最後更新 \(lastUploadDate.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Link(destination: MarketPriceService.universalisMarketURL(itemID: item.id)) {
                Label("在 Universalis 開啟", systemImage: "safari")
                    .font(.subheadline.weight(.semibold))
            }
        }
        .padding(.vertical, 4)
    }
}

private struct MarketListingsSection: View {
    let listings: [MarketListing]

    @State private var isExpanded = false

    private var visibleListings: [MarketListing] {
        Array(listings.prefix(isExpanded ? 10 : 3))
    }

    var body: some View {
        Section("目前上架") {
            if listings.isEmpty {
                Label("目前無上架資訊", systemImage: "cart")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(visibleListings) { listing in
                    MarketListingRow(listing: listing)
                }

                if listings.count > 3 {
                    Button {
                        isExpanded.toggle()
                    } label: {
                        Label(
                            isExpanded ? "收合" : "顯示全部 \(min(listings.count, 10)) 筆",
                            systemImage: isExpanded ? "chevron.up" : "chevron.down"
                        )
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
        }
    }
}

private struct MarketRecentSalesSection: View {
    let sales: [MarketSale]

    var body: some View {
        Section("近期成交") {
            if sales.isEmpty {
                Label("尚無近期成交", systemImage: "clock")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(Array(sales.prefix(5))) { sale in
                    MarketSaleRow(sale: sale)
                }
            }
        }
    }
}

private struct MarketListingRow: View {
    let listing: MarketListing

    var body: some View {
        MarketTransactionRow(
            qualityLabel: listing.hq ? "HQ" : "NQ",
            pricePerUnit: listing.pricePerUnit,
            quantity: listing.quantity,
            total: listing.total,
            worldName: listing.worldName,
            secondaryText: listing.retainerName,
            date: listing.lastReviewDate
        )
    }
}

private struct MarketSaleRow: View {
    let sale: MarketSale

    var body: some View {
        MarketTransactionRow(
            qualityLabel: sale.hq ? "HQ" : "NQ",
            pricePerUnit: sale.pricePerUnit,
            quantity: sale.quantity,
            total: sale.total,
            worldName: sale.worldName,
            secondaryText: nil,
            date: sale.saleDate
        )
    }
}

private struct MarketTransactionRow: View {
    let qualityLabel: String
    let pricePerUnit: Int
    let quantity: Int
    let total: Int
    let worldName: String?
    let secondaryText: String?
    let date: Date?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(qualityLabel)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(qualityLabel == "HQ" ? .blue : .secondary)
                    .frame(width: 24, alignment: .leading)

                Text(marketPriceText(pricePerUnit))
                    .font(.headline.monospacedDigit())

                Text("x\(quantity.formatted())")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)

                Spacer(minLength: 8)

                Text(marketPriceText(total))
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            if !detailText.isEmpty {
                Text(detailText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }

    private var detailText: String {
        var parts: [String] = []

        if let worldName {
            parts.append(worldName)
        }

        if let secondaryText, !secondaryText.isEmpty {
            parts.append(secondaryText)
        }

        if let date {
            parts.append(date.formatted(date: .omitted, time: .shortened))
        }

        return parts.joined(separator: " · ")
    }
}

private struct MarketPriceMetricRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer(minLength: 12)

            Text(value)
                .font(.headline.monospacedDigit())
                .multilineTextAlignment(.trailing)
        }
    }
}

private func marketPriceText(_ price: Int?) -> String {
    guard let price else {
        return "無資料"
    }

    return "\(price.formatted()) gil"
}
