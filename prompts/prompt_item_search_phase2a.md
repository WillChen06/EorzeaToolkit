---
description: Add basic filters to item search (Phase 2a - iLv range, rarity, HQ, tradable)
---

# Phase 2a：道具搜尋 Filter（基本版）

## 目標

在現有的道具搜尋頁面上加入 4 個基本 Filter。這個 Phase 不需要新的 CSV 資料來源，僅擴充現有 `items.json`。

進階 Filter（物品分類、可裝備職業）會在 Phase 2b 處理。

## 資料變更

`items.json` 已更新，每個 item 新增兩個欄位：

```json
{
  "id": 36060,
  "name_cn": "高山茶",
  "name_tw": "高山茶",
  "icon_id": 27087,
  "icon_path": "027000/027087_hr1.tex",
  "ilvl": 554,
  "rarity": 1,
  "can_be_hq": true,         // 新增
  "is_untradable": false     // 新增
}
```

JSON `_meta` 新增 `rarity_meaning` 和 `ilvl_range` 資訊供參考。

檔案大小從 7.2 MB → 9.0 MB（新增兩個 bool 欄位的成本）。

## 4 個 Filter

### 1. iLv 範圍

- **資料範圍**：1 ~ 795
- **UI**：Range slider（雙滑桿）或兩個輸入框 min/max
- **預設**：不限制（min=1, max=795 都顯示）
- **空值處理**：少數道具 `ilvl=0`（無等級概念），歸類為「不限」時都顯示

### 2. 稀有度

- **資料**：5 種值（1, 2, 3, 4, 7）
- **UI**：多選 chip / 多選按鈕
- **預設**：全選

對應表（在 JSON `_meta.rarity_meaning` 裡）：

| 值 | 顯示名稱 | 顏色提示 |
|---|---|---|
| 1 | 一般 | 白色 / 灰色 |
| 2 | 稀有 | 綠色 |
| 3 | 貴重 | 藍色 |
| 4 | 武勳 | 紫色 |
| 7 | 紅蓮 | 粉色 / 玫紅 |

### 3. 可否 HQ

- **資料**：`can_be_hq: bool`
- **UI**：三態切換（不限 / 只看可 HQ / 只看不可 HQ）或 nullable Toggle
- **預設**：不限

### 4. 是否可交易

- **資料**：`is_untradable: bool`（注意是「不可交易」）
- **UI**：三態切換（不限 / 只看可交易 / 只看不可交易）
- **預設**：不限

> 注意 JSON 欄位是 `is_untradable`，UI 邏輯記得反過來：「可交易」= `is_untradable == false`

## UI 設計

採用 **Bottom Sheet** 樣式（你選定的設計）：

```
┌─────────────────────────────────┐
│  道具搜尋                        │
├─────────────────────────────────┤
│ 🔍 [搜尋...]          [Filter ⚙] ← 點擊開啟 Sheet
├─────────────────────────────────┤
│  (搜尋結果列表)                  │
│  目前篩選：iLv 700-795 · 可HQ   ← 已套用 filter 的提示
└─────────────────────────────────┘
```

### Filter Sheet 內容

```
┌─────────────────────────────────┐
│  篩選            [清除] [完成]   │
├─────────────────────────────────┤
│  品級 (iLv)                     │
│  [████████──────] 700 ~ 795     │
│                                  │
│  稀有度                          │
│  [✓一般] [✓稀有] [✓貴重]        │
│  [✓武勳] [✓紅蓮]                │
│                                  │
│  可否 HQ                         │
│  ( ) 不限  ( ) 可HQ  ( ) 不可HQ │
│                                  │
│  是否可交易                      │
│  ( ) 不限  ( ) 可交易  ( ) 不可 │
└─────────────────────────────────┘
```

### 互動細節

- **Filter 按鈕**：搜尋框右側放一個 icon button（如 `slider.horizontal.3`），點擊 present sheet
- **Filter Badge**：如果有套用任何 filter，按鈕上加紅點或顯示套用數量
- **清除按鈕**：把所有 filter 重置為預設
- **完成按鈕**：關閉 sheet，套用 filter
- **即時套用 vs 確認套用**：建議**即時套用**（拖動 slider 時就更新搜尋結果），用戶體驗較好；如果效能有問題改成「完成」才套用

### 已套用 Filter 提示

主畫面顯示一行小字標示套用了哪些 filter，例如：
- `品級 700-795 · 可HQ · 可交易`
- 點擊這行可以快速開啟 Filter Sheet

## Swift Model 建議

### Item Model 更新

```swift
struct Item: Codable, Identifiable, Hashable {
    let id: Int
    let nameCn: String
    let nameTw: String
    let iconId: Int
    let iconPath: String
    let ilvl: Int
    let rarity: Int
    let canBeHq: Bool         // 新增
    let isUntradable: Bool    // 新增

    enum CodingKeys: String, CodingKey {
        case id, ilvl, rarity
        case nameCn = "name_cn"
        case nameTw = "name_tw"
        case iconId = "icon_id"
        case iconPath = "icon_path"
        case canBeHq = "can_be_hq"
        case isUntradable = "is_untradable"
    }
}
```

### Filter State

```swift
struct ItemFilter {
    var ilvlRange: ClosedRange<Int> = 1...795
    var selectedRarities: Set<Int> = [1, 2, 3, 4, 7]  // 全選
    var hqState: BoolFilterState = .any              // any / only / exclude
    var tradableState: BoolFilterState = .any

    var isActive: Bool {
        ilvlRange != 1...795 ||
        selectedRarities != [1, 2, 3, 4, 7] ||
        hqState != .any ||
        tradableState != .any
    }
}

enum BoolFilterState {
    case any        // 不限
    case only       // 只看符合
    case exclude    // 只看不符合
}
```

### Filter 套用邏輯

在現有的搜尋邏輯中加入 filter 篩選步驟：

```swift
func filteredItems(query: String, filter: ItemFilter) -> [Item] {
    items
        .filter { item in
            // 1. ilvl range
            (filter.ilvlRange.contains(item.ilvl) || item.ilvl == 0 && filter.ilvlRange == 1...795)
            // 2. rarity
            && filter.selectedRarities.contains(item.rarity)
            // 3. HQ
            && (filter.hqState == .any || filter.hqState == .only && item.canBeHq || filter.hqState == .exclude && !item.canBeHq)
            // 4. tradable (注意: is_untradable 是反向)
            && (filter.tradableState == .any || filter.tradableState == .only && !item.isUntradable || filter.tradableState == .exclude && item.isUntradable)
        }
        .filter { /* 原本的 name 搜尋邏輯 */ }
        .sorted { /* 原本的排序邏輯 */ }
        .prefix(50)
        .map { $0 }
}
```

## 效能注意事項

- 49k 筆道具，4 個 filter 都是 O(1) 判斷，整體搜尋仍然非常快
- 即時套用 filter 時建議跟搜尋輸入用同一個 debounce
- Filter 邏輯放 background thread，跟搜尋一致

## 注意事項

- 本專案 SwiftUI, target iOS 17+
- 不需要修改 TabBar 或頁面結構，只在現有的搜尋頁面上擴充
- 沒有「物品分類」和「可裝備職業」filter — 這兩個會在 **Phase 2b** 補上（需要額外 CSV）
- iLv slider 建議用 `Slider` 配合 `step: 1` 或自訂雙滑桿元件
- 稀有度的顏色對照表沒有官方規範，可以參考遊戲內視覺風格（白/綠/藍/紫/粉/橘）自行調整
