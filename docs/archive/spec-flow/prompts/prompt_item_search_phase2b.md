---
description: Add advanced filters to item search (Phase 2b - UI category, equippable jobs, equip slot)
---

# Phase 2b：道具搜尋進階 Filter

## 目標

在 Phase 2a 的 4 個基本 filter 之上，新增 3 個進階 filter：物品分類、可裝備職業、裝備部位。

## 資料變更

`items.json` 結構大幅擴充：

```json
{
  "items": [
    {
      "id": 36060,
      "name_cn": "高山茶",
      "name_tw": "高山茶",
      "icon_id": 27087,
      "icon_path": "027000/027087_hr1.tex",
      "ilvl": 554,
      "rarity": 1,
      "can_be_hq": true,
      "is_untradable": false,
      "ui_category_id": 46,           // 新增：物品分類
      "classjob_category_id": 0,      // 新增：職業分類
      "equip_slot": 0                  // 新增：裝備部位
    }
  ],

  "ui_categories": [                   // 新增：分類定義
    {
      "id": 1,
      "name_cn": "格斗武器",
      "name_tw": "格鬥武器",
      "order_minor": ...,
      "order_major": 1                  // 用於分組
    }
  ],

  "classjob_categories": [             // 新增：職業組合定義
    {
      "id": 64,
      "name_cn": "骑士",
      "name_tw": "騎士",
      "jobs": ["PLD"]                    // 該分類包含哪些職業
    },
    {
      "id": 1,
      "name_cn": "所有职业",
      "name_tw": "所有職業",
      "jobs": ["ADV", "GLA", "PGL", ...]
    }
  ],

  "equip_slots": [                     // 新增：裝備部位定義
    { "id": 1, "name_tw": "主手" },
    { "id": 3, "name_tw": "頭部" },
    ...
  ]
}
```

**檔案大小**：9.0 MB → 12.0 MB（多了 categories 對照表和每個 item 三個 ID）

**統計**：
- 49,311 個道具
- 112 個物品分類（UI category）
- 188 個職業分類組合
- 22 種裝備部位

## 3 個新增 Filter

### 1. 物品分類（UI Category）

- **資料**：112 種分類（單手劍、大斧、頭部防具、藥品、食材、金屬...）
- **UI**：多選，按 `order_major` 分組顯示

#### 分類層級結構

從 `order_major` 可以看出 7 大類群組：

| Major | 群組概念 | 範例分類 |
|---|---|---|
| 1 | 武器（戰職） | 單手劍、大斧、雙手劍、槍刃、長槍、弓 ... (24 個) |
| 2 | 生產職工具 | 刻木工具（主工具）、鍛鐵工具（主工具）... (22 個) |
| 3 | 防具 | 盾、頭部防具、身體防具、手部防具... (6 個) |
| 4 | 飾品 | 耳飾、項鍊、手鐲、戒指、靈魂水晶 (5 個) |
| 5 | 消耗品 | 藥品、食品 (2 個) |
| 6 | 素材 | 食材、水產品、石材、金屬、木材... (19 個) |
| 7 | 雜項 | 魔晶石、水晶、觸媒、雜貨... (34 個) |

UI 建議用 **可摺疊的群組列表**：

```
┌─ 物品分類（多選）─────────┐
│  ▼ 武器（24）              │
│    [✓] 單手劍              │
│    [✓] 大斧                │
│    [ ] 雙手劍              │
│    ...                     │
│  ▶ 防具（6）               │
│  ▶ 飾品（5）               │
│  ▶ 消耗品（2）             │
│  ...                       │
└──────────────────────────┘
```

**預設**：全不選 = 不限

### 2. 可裝備職業

- **資料**：21 個戰鬥職業 + 8 個生產職 + 3 個採集職
- **UI**：多選職業 icon grid（沿用既有的 Job 圖標）

#### 邏輯

道具的 `classjob_category_id` 對應一個 ClassJobCategory，裡面的 `jobs[]` 列出可用職業。使用者選擇職業 → 找出 `classjob_category_id` 對應的分類中，`jobs[]` 包含使用者選的職業之一的道具。

```swift
// 偽代碼
let selectedJobAbbrs: Set<String> = ["PLD", "WAR"]

func matchesJobFilter(item: Item) -> Bool {
    guard !selectedJobAbbrs.isEmpty else { return true }  // 不限
    guard let category = classjobCategories[item.classjobCategoryId] else { return false }
    return !selectedJobAbbrs.isDisjoint(with: category.jobs)
}
```

**注意**：
- `classjob_category_id = 0` 的道具表示「不限職業使用」（素材、消耗品等），這類道具在套用職業 filter 時應該**也要顯示**（或加一個獨立的「素材」選項處理）
- 你可以延用之前 `battle_actions.json` 裡的職業順序和圖示

**預設**：全不選 = 不限

### 3. 裝備部位

- **資料**：22 種部位（主手、副手、頭部、身體、手部、腿部、腳部、耳飾、項鍊、手鐲、戒指、主副雙手、工具...）
- **UI**：多選 chip

只對 `equip_slot > 0` 的道具有意義（28,621 個）。`equip_slot = 0` 表示「非裝備」（素材、藥品、雜貨等）。

**預設**：全不選 = 不限

## UI 設計

延續 Phase 2a 的 Bottom Sheet，把新 filter 加進去：

```
┌──────────────────────────────────┐
│  篩選            [清除] [完成]    │
├──────────────────────────────────┤
│  品級 (iLv)                      │
│  [████████──────] 700 ~ 795      │
│                                   │
│  稀有度                           │
│  [✓一般] [✓稀有] ...             │
│                                   │
│  可否 HQ                          │
│  ( ) 不限  ( ) 可  ( ) 不可      │
│                                   │
│  是否可交易                       │
│  ( ) 不限  ( ) 可  ( ) 不可      │
│                                   │
│  ───────── 進階 ─────────         │
│                                   │
│  物品分類                         │
│  ▶ 武器（24）       │
│  ▶ 防具（6）        │
│  ▶ 飾品（5）        │
│  ...                              │
│                                   │
│  可裝備職業                       │
│  [PLD] [WAR] [DRK] [GNB]         │
│  [WHM] [SCH] [AST] [SGE]         │
│  ...                              │
│                                   │
│  裝備部位                         │
│  [主手] [副手] [頭部] [身體]      │
│  [手部] [腿部] [腳部] [耳飾]      │
│  [項鍊] [手鐲] [戒指] [主副雙手] │
└──────────────────────────────────┘
```

當套用了多個 filter，主畫面的「已套用 filter 提示」要能簡潔表達，例如：
- `品級 700-795 · 食品 · 可HQ`
- `頭部 · 身體 · 騎士`
- `5 個篩選條件套用中`（太多時可改成數字摘要）

## Swift Model 更新

```swift
struct Item: Codable, Identifiable, Hashable {
    let id: Int
    let nameCn: String
    let nameTw: String
    let iconId: Int
    let iconPath: String
    let ilvl: Int
    let rarity: Int
    let canBeHq: Bool
    let isUntradable: Bool
    let uiCategoryId: Int        // 新增
    let classjobCategoryId: Int  // 新增
    let equipSlot: Int            // 新增

    enum CodingKeys: String, CodingKey {
        case id, ilvl, rarity
        case nameCn = "name_cn"
        case nameTw = "name_tw"
        case iconId = "icon_id"
        case iconPath = "icon_path"
        case canBeHq = "can_be_hq"
        case isUntradable = "is_untradable"
        case uiCategoryId = "ui_category_id"
        case classjobCategoryId = "classjob_category_id"
        case equipSlot = "equip_slot"
    }
}

struct UICategory: Codable, Identifiable {
    let id: Int
    let nameCn: String
    let nameTw: String
    let orderMinor: Int
    let orderMajor: Int

    enum CodingKeys: String, CodingKey {
        case id
        case nameCn = "name_cn"
        case nameTw = "name_tw"
        case orderMinor = "order_minor"
        case orderMajor = "order_major"
    }
}

struct ClassJobCategory: Codable, Identifiable {
    let id: Int
    let nameCn: String
    let nameTw: String
    let jobs: [String]  // ["PLD", "WAR", ...]

    enum CodingKeys: String, CodingKey {
        case id, jobs
        case nameCn = "name_cn"
        case nameTw = "name_tw"
    }
}

struct EquipSlot: Codable, Identifiable {
    let id: Int
    let nameTw: String

    enum CodingKeys: String, CodingKey {
        case id
        case nameTw = "name_tw"
    }
}

struct ItemDataResponse: Codable {
    let items: [Item]
    let uiCategories: [UICategory]
    let classjobCategories: [ClassJobCategory]
    let equipSlots: [EquipSlot]

    enum CodingKeys: String, CodingKey {
        case items
        case uiCategories = "ui_categories"
        case classjobCategories = "classjob_categories"
        case equipSlots = "equip_slots"
    }
}
```

### Filter State 擴充

```swift
struct ItemFilter {
    // Phase 2a
    var ilvlRange: ClosedRange<Int> = 1...795
    var selectedRarities: Set<Int> = [1, 2, 3, 4, 7]
    var hqState: BoolFilterState = .any
    var tradableState: BoolFilterState = .any

    // Phase 2b
    var selectedUICategoryIds: Set<Int> = []      // 空 = 不限
    var selectedJobAbbrs: Set<String> = []         // 空 = 不限
    var selectedEquipSlots: Set<Int> = []          // 空 = 不限
}
```

### 套用邏輯

```swift
extension ItemFilter {
    func matches(item: Item, classjobCategoryLookup: [Int: ClassJobCategory]) -> Bool {
        // Phase 2a filters ...

        // UI category
        if !selectedUICategoryIds.isEmpty {
            guard selectedUICategoryIds.contains(item.uiCategoryId) else { return false }
        }

        // Classjob
        if !selectedJobAbbrs.isEmpty {
            guard let cjcat = classjobCategoryLookup[item.classjobCategoryId] else { return false }
            guard !Set(cjcat.jobs).isDisjoint(with: selectedJobAbbrs) else { return false }
        }

        // Equip slot
        if !selectedEquipSlots.isEmpty {
            guard selectedEquipSlots.contains(item.equipSlot) else { return false }
        }

        return true
    }
}
```

把 `classjobCategoryLookup` 在啟動時建好（`Dictionary(uniqueKeysWithValues: ...)`），filter 時用 O(1) lookup。

## 效能注意事項

- 多 filter 組合下仍是 O(N) 線性掃描，49k 筆 + 7 個 filter 在 background thread 上執行毫無壓力
- ClassJobCategory 的 `Set(cjcat.jobs).isDisjoint(with:)` 可以預先把 `jobs` 轉成 `Set<String>` 儲存以加速
- Filter sheet 的職業 grid 和分類列表是固定資料，啟動後可以快取

## 注意事項

- 本專案 SwiftUI, target iOS 17+
- 預期載入時間：12 MB JSON decode 在現代手機約 100-300ms，務必放 background
- 翻譯註記：分類名稱是 OpenCC s2t 轉換，可能跟玩家熟悉的繁中版用語略有差異
- 「分類」filter 預設**全不選 = 不限**（跟稀有度的「全選 = 不限」相反），UI 上要區分清楚
- 職業圖示沿用 `battle_actions.json` 裡的 `icon_path` 規則（`062000/062{100+row_id}_hr1.tex`），不需要重複下載
- ClassJobCategory id=0 的道具是「不限職業」（如素材、消耗品），套用職業 filter 時這些**會被排除** — 如果需要「不限職業也算」的邏輯可以另外加 toggle
