# 任務：新增藏寶圖採集點功能

## 需求概述

在現有的藏寶圖列表頁面上，為每個 list item 新增一個「採集點」按鈕。點擊後 present 一個 `.sheet` 浮動頁面，顯示該藏寶圖可以在哪些採集點取得。

## UI 設計（參考附圖）

Sheet 頁面的結構：

```
標題: "G14 - 陳舊的金毗羅鱷革地圖 (Lv.90 採集點)"    [X 關閉]

採掘師 (2個)
┌──────────────────────────────────────────┐
│  礦脈      天外天垓      (18.5, 12.3)   │
├──────────────────────────────────────────┤
│  石場      天外天垓      (21.5, 33.4)   │
└──────────────────────────────────────────┘

園藝師 (2個)
┌──────────────────────────────────────────┐
│  良材      天外天垓      (7.5, 21.6)    │
├──────────────────────────────────────────┤
│  草叢      天外天垓      (14.2, 28.6)   │
└──────────────────────────────────────────┘
```

重點：
- 按「職業」分兩個 Section：採掘師（type 0, 1）、園藝師（type 2, 3）
- Section header 顯示職業名稱和該職業的採集點數量
- 每一列顯示：節點類型名稱、區域名稱、座標 (x, y)
- 節點類型名稱用不同顏色區分（可參考截圖配色，礦脈/石場/良材/草叢 各一色）

## 資料來源

`treasure_maps_final.json` 已更新，每張藏寶圖都內嵌了 `gathering_nodes` 陣列。

### JSON 結構

每張藏寶圖的關鍵欄位：

```json
{
  "grade": "G14",
  "name_tw": "陳舊的金毗羅鱷革地圖",
  "level": 90,
  "gathering_nodes": [
    {
      "type": 0,
      "job": "miner",
      "zone_id": 3712,
      "x": 18.5,
      "y": 12.4
    },
    {
      "type": 1,
      "job": "miner",
      "zone_id": 3712,
      "x": 21.5,
      "y": 33.5
    },
    {
      "type": 2,
      "job": "botanist",
      "zone_id": 3712,
      "x": 7.6,
      "y": 21.6
    },
    {
      "type": 3,
      "job": "botanist",
      "zone_id": 3712,
      "x": 14.2,
      "y": 28.6
    }
  ]
}
```

### 節點類型對照（`type` 欄位）

| type | 繁中名稱 | 職業 | job 值 |
|------|---------|------|--------|
| 0 | 礦脈 | 採掘師 | miner |
| 1 | 石場 | 採掘師 | miner |
| 2 | 良材 | 園藝師 | botanist |
| 3 | 草叢 | 園藝師 | botanist |

### 區域名稱查詢

JSON 裡有 `zone_names` 對照表，用 `zone_id` 查繁中名稱：

```json
{
  "zone_names": {
    "3712": { "cn": "天外天垓", "tw": "天外天垓" },
    "3713": { "cn": "厄尔庇斯", "tw": "厄爾庇斯" }
  }
}
```

使用方式：`zone_names["\(node.zone_id)"].tw`

## 實作要點

1. **JSON 解析**：`treasure_maps_final.json` 已放在專案中，確認現有的 Model 是否需要新增 `gathering_nodes` 相關的 struct。需要新增的 struct 大致如下：

```swift
struct GatheringNode: Codable {
    let type: Int       // 0=礦脈, 1=石場, 2=良材, 3=草叢
    let job: String     // "miner" or "botanist"
    let zoneId: Int     // PlaceName ID
    let x: Double
    let y: Double
    
    enum CodingKeys: String, CodingKey {
        case type, job
        case zoneId = "zone_id"
        case x, y
    }
}
```

2. **列表按鈕**：在藏寶圖列表的每個 item 上加一個「採集點」按鈕，只在 `gathering_nodes` 非空時顯示。

3. **Sheet 頁面**：
   - 使用 `.sheet` modifier present
   - 用 `presentationDetents` 控制高度（建議 `.medium` 和 `.large`）
   - 按 `job` 分組顯示（miner section、botanist section）
   - Section header: `"採掘師 (\(count)個)"` / `"園藝師 (\(count)個)"`

4. **節點類型顯示名稱和顏色**：
   - type 0 礦脈：可用棕/橙色系
   - type 1 石場：可用灰色系
   - type 2 良材：可用綠色系
   - type 3 草叢：可用黃綠色系

5. **座標格式**：顯示為 `(x, y)`，小數保留一位。

## 注意事項

- 本專案為 SwiftUI，target iOS 17+
- 語言為繁體中文
- 先閱讀現有的藏寶圖列表頁面程式碼，了解現有的 Model 結構和 View 層級再開始改
- `treasure_maps_final.json` 如果尚未放入專案，請放到 Resources 或對應的 JSON 資料夾中
