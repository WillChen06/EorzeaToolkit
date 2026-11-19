---
description: Implement relic weapon progress tracker (MVP: Zodiac/古武 only)
---

# 任務：實作發光武器製作進度追蹤（MVP - 古武）

## 需求概述

新增「發光武器」功能，第一版只實作 **古武（黃道武器，2.x ARR 系列）**，驗證整體流程後再擴展到其他 5 個系列（魂武、優武、義武、曼武、幻武）。

## 兩種模式

### 模式 1：檢視（View Mode）
- 純粹瀏覽武器各階段的內容
- 不需要選擇職業
- 不顯示 checkbox 和進度條
- 點擊階段可展開看詳細任務說明 + 素材清單

### 模式 2：追蹤（Tracking Mode）
- 先選擇職業（10 個可用職業：PLD/WAR/WHM/SCH/MNK/DRG/NIN/BRD/BLM/SMN）
- 顯示所有階段
- 每個階段有 checkbox 標記是否完成
- 頂部顯示總進度條（X / 9 階段完成，百分比）
- 階段預設摺疊，點擊展開看細節
- 進度資料本地儲存（用 SwiftData 或 @AppStorage + JSON）

## UI 結構

```
頁面標題：發光武器 - 古武（黃道武器）

[檢視] [追蹤]  ← 模式切換 Segmented Control

(追蹤模式時顯示)
職業選擇：[PLD ▼]
進度：████████░░ 7/9 (78%)

────────────────────
✓ ▶ [前置任務]                       iLv --
✓ ▶ [古武+0]                         iLv 80
✓ ▶ [古武+1 天極]                    iLv 90
✓ ▶ [古武+1.5 魂晶]                  iLv 100
✓ ▶ [古武+2 魂靈]                    iLv 100
✓ ▶ [古武+3 新星]                    iLv 110
✓ ▶ [古武+4 鎮魂]                    iLv 115
☐ ▼ [古武+5 黃道武器]                iLv 125     ← 展開狀態
    任務：ℚ 踏上黃道的徵途
          第n把攜帶古武+4（鎮魂）和任務給的 4 樣材料...
    素材：
      • 大炎獸核心 ×80000  [軍票]
      • 靈峯泉水 ×800  [詩學]
      • 石綠湖水晶 ×100000G
      • 熔火指環HQ  (製作或購買)
      • ...
☐ ▶ [古武+6 本我]                    iLv 135
```

## 階段標題顯示規則

按你的需求，標題顯示「階段 / 任務名 / iLv tag」：

- 階段名稱：`stages[].name_tw` (例如 "古武+5 / 黃道武器")
- iLv：用 tag/badge 樣式顯示 `stages[].ilvl`（若為 null 顯示 "--"）

## 展開後的細節區

- 任務說明：`stages[].task_description_tw`（可能是多行文字）
- 素材清單：`stages[].materials[]`
  - 名稱：`name_tw`
  - 數量：`quantity`（可能是 Int 或 String 如 "100000G", "制作或购买"）
  - 來源：`source_tw`（可能為 null，例如「詩學」「軍票」「同盟」）
  - 取得備註：`note_tw`（可能為 null，例如 NPC 位置、兌換方式、特殊技巧等）

素材顯示格式建議：
```
• {name_tw} ×{quantity}  [{source_tw}]   ⓘ
   └─（展開後）取得備註：{note_tw}
```
- 如果 quantity 是 String（如 "100000G"、"制作或購買"），不顯示 ×
- 如果 source 是 null，不顯示後面的 [...]
- 如果 note_tw 不為 null，在素材右側顯示 info icon（如 `ⓘ` 或 `info.circle`），點擊或長按展開顯示備註
- 備註是多行文字，可能很長（如十二魂晶有 12 個星座地點），UI 上可以用 expandable 區塊或浮動 popover 顯示

範例備註內容：
- 「星光變石」：可從 NPC 兌換、神秘地圖任務、同盟徽章三種方式取得
- 「十二魂晶」：列出 12 個星座對應的地圖區域
- 「石綠湖水晶」：商人 NPC 的精確座標（拉諾西亞高地 X: 26.1, Y: 26.4）

## 資料來源

`relic_weapons.json` 已放在專案中。結構如下：

```json
{
  "weapon_series": {
    "id": "zodiac",
    "name_tw": "古武",
    "full_name_tw": "黃道武器",
    "expansion": "2.x",
    "level_cap": 50,
    "available_jobs": ["PLD", "WAR", "WHM", "SCH", "MNK", "DRG", "NIN", "BRD", "BLM", "SMN"],
    "stages": [
      {
        "stage_index": 0,
        "name_tw": "前置任務",
        "task_description_tw": "ℚ 傳說中的武器工匠",
        "ilvl": null,
        "materials": []
      },
      {
        "stage_index": 1,
        "name_tw": "古武+0",
        "task_description_tw": "ℚ 復甦的上古武器",
        "ilvl": 80,
        "materials": [
          { "name_tw": "原型武器（鑲嵌魔晶石）", "quantity": 1, "source_tw": null },
          { "name_tw": "拉札罕淬火油", "quantity": 1, "source_tw": null }
        ]
      }
    ]
  }
}
```

共 9 個階段，最複雜的階段（古武+5）有 14 種素材。

## Swift Model 建議

```swift
struct WeaponSeries: Codable {
    let id: String
    let nameTw: String
    let fullNameTw: String
    let expansion: String
    let levelCap: Int
    let availableJobs: [String]
    let stages: [WeaponStage]

    enum CodingKeys: String, CodingKey {
        case id, expansion, stages
        case nameTw = "name_tw"
        case fullNameTw = "full_name_tw"
        case levelCap = "level_cap"
        case availableJobs = "available_jobs"
    }
}

struct WeaponStage: Codable, Identifiable {
    var id: Int { stageIndex }
    let stageIndex: Int
    let nameTw: String
    let taskDescriptionTw: String
    let ilvl: Int?
    let materials: [WeaponMaterial]

    enum CodingKeys: String, CodingKey {
        case ilvl
        case stageIndex = "stage_index"
        case nameTw = "name_tw"
        case taskDescriptionTw = "task_description_tw"
        case materials
    }
}

// quantity 可能是 Int 或 String，需要自訂 decoding
enum MaterialQuantity: Codable {
    case number(Int)
    case text(String)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let i = try? container.decode(Int.self) {
            self = .number(i)
        } else if let s = try? container.decode(String.self) {
            self = .text(s)
        } else {
            self = .text("?")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .number(let i): try container.encode(i)
        case .text(let s): try container.encode(s)
        }
    }
}

struct WeaponMaterial: Codable, Identifiable {
    var id: String { nameTw }  // 同一階段內素材名稱應唯一（已在資料處理時合併）
    let nameTw: String
    let quantity: MaterialQuantity
    let sourceTw: String?
    let noteTw: String?  // 取得備註（NPC 位置、兌換方式等）

    enum CodingKeys: String, CodingKey {
        case nameTw = "name_tw"
        case quantity
        case sourceTw = "source_tw"
        case noteTw = "note_tw"
    }
}
```

## 進度儲存

每個職業的進度是獨立的，建議用：

```swift
@Model
class WeaponProgress {
    var weaponSeriesId: String   // "zodiac"
    var jobAbbreviation: String  // "PLD"
    var completedStageIndices: [Int]  // [0, 1, 2, 3]
}
```

或用簡單的 `@AppStorage` + JSON encode/decode 也行，視專案現有架構而定。

## 注意事項

- 本專案為 SwiftUI, target iOS 17+
- 翻譯註記：JSON 裡的 `name_tw` 是 OpenCC 自動轉換的，部分字可能不是 FF14 繁中版官方用字（如「靈峯」應為「靈峰」），第一版先用這個，之後再優化
- 進度條樣式可用 `ProgressView` 或自訂 `Capsule`
- 階段展開/摺疊用 `DisclosureGroup` 或自訂動畫都行
- 在主頁面 TabBar 中已有「發光武器」分頁，這次是在那裡實作這個古武頁面
- 之後會擴充其他 5 個武器系列，建議 ViewModel 設計時把 weapon_series 當參數化，不要寫死「zodiac」
