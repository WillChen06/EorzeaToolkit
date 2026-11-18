---
description: Extend relic weapon tracker from MVP (古武 only) to all 6 weapon series
---

# 擴充發光武器追蹤：從古武 MVP 擴展到全部 6 個系列

## 背景

MVP 階段只實作了古武（黃道武器，2.x），現在要擴展到全部 6 個系列。

## 資料結構變更

`relic_weapons.json` 已更新為新結構，**最外層改為陣列**包含 6 個系列：

**舊結構 (MVP)：**
```json
{ "weapon_series": { ... } }   // 單一物件
```

**新結構：**
```json
{
  "weapon_series_list": [
    { "id": "zodiac", ... },         // 2.x ARR
    { "id": "anima", ... },          // 3.x HW
    { "id": "eureka", ... },         // 4.x SB
    { "id": "bozja", ... },          // 5.x ShB
    { "id": "mandervilles", ... },   // 6.x EW
    { "id": "phantom", ... }         // 7.x DT
  ]
}
```

每個系列內部的 `stages` 結構保持不變，UI 邏輯可以複用。

## 6 個系列概覽

| ID | 名稱 | 完整名 | 版本 | 等級 | 階段數 | 可用職業數 |
|---|---|---|---|---|---|---|
| zodiac | 古武 | 黃道武器 | 2.x | 50 | 11 | 10 |
| anima | 魂武 | 靈魂武器 | 3.x | 60 | 9 | 13 |
| eureka | 優武 | 優雷卡武器 | 4.x | 70 | 15 | 14 |
| bozja | 義武 | 記憶武器 | 5.x | 80 | 14 | 17 |
| mandervilles | 曼武 | 曼德維爾武器 | 6.x | 90 | 5 | 19 |
| phantom | 幻武 | 幻境武器 | 7.x | 100 | 9 | 21 |

## UI 變更

### 1. 武器系列選擇頁面（新增）

進入「發光武器」分頁時，先顯示一個系列選擇頁面（卡片或列表）：

```
發光武器
─────────────────────
[古武]  黃道武器       2.x  Lv.50
[魂武]  靈魂武器       3.x  Lv.60
[優武]  優雷卡武器     4.x  Lv.70
[義武]  記憶武器       5.x  Lv.80
[曼武]  曼德維爾武器   6.x  Lv.90
[幻武]  幻境武器       7.x  Lv.100  ← 最新
```

點擊任一系列 → 進入該系列的階段追蹤頁（沿用 MVP 已實作的 UI）

### 2. 階段追蹤頁面（沿用既有實作）

- 結構不變：模式切換（檢視/追蹤）、職業選擇、進度條、階段展開
- 只是現在 ViewModel 接收一個 `WeaponSeries` 參數而不是寫死讀古武
- 不同系列的 `available_jobs` 不同，職業選擇器要動態顯示

### 3. 進度儲存

進度資料的 key 從「職業」變成「武器系列 + 職業」的組合：

```swift
@Model
class WeaponProgress {
    var weaponSeriesId: String   // "zodiac" / "anima" / ... / "phantom"
    var jobAbbreviation: String  // "PLD" / "WAR" / ...
    var completedStageIndices: [Int]
}
```

或用 `@AppStorage` 的話 key 可以是 `"progress_{seriesId}_{job}"`

## Model 變更

```swift
struct RelicWeaponData: Codable {
    let weaponSeriesList: [WeaponSeries]
    
    enum CodingKeys: String, CodingKey {
        case weaponSeriesList = "weapon_series_list"
    }
}

// WeaponSeries / WeaponStage / WeaponMaterial 結構不變，沿用 MVP 的定義
```

## 注意事項

- **`曼武` 階段數少（只有 5 個）** 是因為原始 Excel 表格的限制，實際遊戲中曼武有更多版本（6.0/6.1/6.2/6.3/6.4/6.5 共 6 個階段），表格只列了前 4 個。這是資料來源的限制，UI 上正常顯示即可，之後資料更新就會補上。
- **`幻武` 的階段包含「子任務」**（如「古代工匠的技術」、「蘊藏屬性之力的魔法球」），這些是主階段（半影/本影/黯影）之間需要完成的中間任務，正常顯示為獨立階段。
- 部分階段的 `ilvl` 為 null（前置任務、子任務），UI 上顯示「--」。
- 系列選擇頁的職業選擇要過濾掉「該系列不支援的職業」（例如古武沒有 GNB/AST/MCH 等後期職業）。
- 進度儲存：App 還未發布，直接用新 key 結構（`seriesId + job`）即可，不需要做 migration，舊的 MVP 進度資料可以直接捨棄。

## 實作順序建議

1. 更新 JSON loader 讀取 `weapon_series_list` 陣列
2. 新增武器系列選擇頁面
3. 重構既有的階段追蹤頁面，讓 ViewModel 接受 `WeaponSeries` 參數
4. 更新進度儲存的 key 結構（直接用新格式，無需 migration）
5. 測試每個系列的階段都能正常顯示
