---
description: Add item search feature (Phase 1 - basic name search without filters)
---

# Phase 1：道具搜尋功能（無 Filter 版）

## 目標

新增一個道具搜尋分頁，使用者輸入關鍵字 → 列出符合的道具基本資訊。

Phase 1 範圍**只做最基本的名稱搜尋**，不做 Filter、不做配方/取得方式/採集/價格細節。後續 Phase 會擴充。

## UI 設計

```
┌─────────────────────────────┐
│  道具搜尋                    │
├─────────────────────────────┤
│ 🔍 [輸入道具名稱...        ] │
├─────────────────────────────┤
│ [icon] 高山茶                │
│         iLv 554              │
├─────────────────────────────┤
│ [icon] 高山茶餅乾            │
│         iLv 554              │
├─────────────────────────────┤
│ [icon] 高山茶葉              │
│         iLv 539              │
└─────────────────────────────┘
```

- TabBar 新增「道具」分頁
- 上方一個搜尋框（`searchable` 或自訂 TextField）
- 下方 List 顯示符合的道具：icon + 名稱 + iLv
- 點擊單一道具：Phase 1 先顯示一個基本詳情頁（只有大張 icon + 名稱 + iLv），預留之後 Phase 擴充配方/採集/價格的位置

## 資料來源

`items.json` 放在專案 Resources 目錄中。

### JSON 結構

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
      "rarity": 1
    },
    ...
  ],
  "_meta": {
    "count": 49311,
    "icon_url_template": "https://beta.xivapi.com/api/1/asset/ui/icon/{icon_path}?format=png"
  }
}
```

### 資料量

**49,311 筆道具**（檔案約 7.2 MB）。所有搜尋邏輯都在本地做，不需呼叫 API。

## 搜尋邏輯

### 基本要求

- 模糊比對（substring 即可，不需要 fuzzy matching）
- 同時比對 `name_tw` 和 `name_cn`（玩家可能用任一種輸入）
- 不區分大小寫（雖然中文沒這問題，但英數字情境要支援）
- 空字串不搜尋（顯示空列表或提示文字）

### 結果排序

- 名稱完全相等的排最前
- 名稱開頭符合的次之
- 其他包含關鍵字的依 iLv 降序

### 結果上限

- 限制最多顯示 50 筆（避免單次渲染太多 cell）
- 超過時顯示「還有 N 筆未顯示，請輸入更精確的關鍵字」之類的提示

### 效能考量

49k 筆資料的 substring 搜尋在現代手機上完全沒問題，**不需要建索引、不需要 SQLite**。但要注意：

- 載入 JSON 時用 background thread decode，避免阻塞主執行緒
- 搜尋本身也建議丟到 background（用 `.task` + `Task.detached` 或類似）
- 輸入時加 debounce（300ms 左右），避免每打一個字就觸發搜尋
- List 用 `LazyVStack` / `List`，避免一次渲染太多 cell

## Swift Model 建議

```swift
struct Item: Codable, Identifiable, Hashable {
    let id: Int
    let nameCn: String
    let nameTw: String
    let iconId: Int
    let iconPath: String
    let ilvl: Int
    let rarity: Int

    enum CodingKeys: String, CodingKey {
        case id, ilvl, rarity
        case nameCn = "name_cn"
        case nameTw = "name_tw"
        case iconId = "icon_id"
        case iconPath = "icon_path"
    }

    var iconURL: URL? {
        URL(string: "https://beta.xivapi.com/api/1/asset/ui/icon/\(iconPath)?format=png")
    }
}

struct ItemDataResponse: Codable {
    let items: [Item]
}
```

## 注意事項

- 本專案為 SwiftUI, target iOS 17+
- 語言：繁體中文為主
- **Phase 1 不做 Filter**（分類、等級範圍、職業等都不做）
- **不做網路請求** — 完全離線搜尋
- 詳情頁先做基本版（icon + 名稱 + iLv），Phase 2/3 才會接 Universalis 市場價、配方、採集等
- 翻譯註記：`name_tw` 是 OpenCC 簡轉繁，部分用詞可能跟 FF14 繁中官方有差（國服與繁中服翻譯不同），先用這個版本，使用者如果回報問題再優化
- TabBar 順序：建議放在現有分頁之後（藏寶圖、發光武器、海釣、技能循環、進度、仙人微彩、**道具**）
