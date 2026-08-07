# 任務：新增戰鬥職業技能施放順序編輯器

## 需求概述

新增一個功能讓玩家可以編輯戰鬥職業的技能施放順序（Rotation）。流程為：選擇職業 → 瀏覽技能（按 Category 分類篩選）→ 點選技能加到編輯區 → 排列施放順序。

## 功能流程

```
職業選擇頁面          技能施放順序編輯頁面
┌──────────┐         ┌─────────────────────────────────┐
│ 🛡 騎士   │ ──tap──▶│  PLD 騎士                        │
│ 👊 武僧   │         │                                  │
│ ⚔ 戰士   │         │  [戰技] [魔法] [能力] ← Category Tag │
│ ...      │         │                                  │
└──────────┘         │  ┌─────────────────────────┐     │
                      │  │ 技能選擇區（Grid）        │     │
                      │  │ [icon][icon][icon][icon] │     │
                      │  │ [icon][icon][icon]       │     │
                      │  └─────────────────────────┘     │
                      │                                  │
                      │  ──────── 編輯區 ────────         │
                      │  [1][2][3][4][5][6]...           │
                      │  ← 已加入的技能順序，可拖曳排序    │
                      └─────────────────────────────────┘
```

## UI 設計要點

### 1. 職業選擇頁面
- 顯示所有 21 個戰鬥職業（不含 BLU 青魔法師）
- 每個項目顯示：職業 icon + 職業名稱
- 職業 icon URL 組法：`https://beta.xivapi.com/api/1/asset/ui/icon/{icon_path}?format=png`

### 2. 技能施放順序編輯頁面

#### 技能選擇區
- 頂部顯示 Category 篩選 Tag（Segmented Control 或 Toggle 按鈕）
  - 「戰技」(weaponskill)、「魔法」(spell)、「能力」(ability)
  - 不是每個職業都有全部三種，例如純近戰職業沒有「魔法」
  - 預設顯示全部
- 技能以 Grid（LazyVGrid）呈現，只顯示 icon
- **長按** icon 才顯示技能詳細資訊（名稱 + 詳細面板），參考附圖
- **點擊** icon → 將技能加入下方編輯區

#### 技能詳細面板（長按顯示）
顯示以下資訊：
- 技能 icon + 名稱
- 類型（戰技/魔法/能力）
- 距離、範圍
- 詠唱時間、復唱時間
- 技能說明文字

數值轉換規則：
- `range`: -1 = "近戰"(3米), 0 = "自身", 其他 = 數值+"米"
- `effect_range`: 0 或 1 = 單體(不用特別顯示), >1 = 數值+"米"
- `cast_100ms`: 0 = "即時", 其他 = 值÷10 + "秒"（如 20 → "2.0秒"）
- `recast_100ms`: 0 = 無, 其他 = 值÷10 + "秒"（如 25 → "2.5秒"）

#### 編輯區
- 水平排列的技能 icon 序列
- 支持拖曳排序（可用 SwiftUI 的 `draggable` / `dropDestination` 或 `onMove`）
- 長按可刪除單個技能
- 同一個技能可以重複加入（Rotation 裡同一技能可能出現多次）

## 資料來源

`battle_actions.json` 放在專案的 Resources/Data 資料夾中。

### JSON 結構

```json
{
  "jobs": [
    {
      "id": 19,
      "name_cn": "骑士",
      "name_tw": "騎士",
      "abbreviation": "PLD",
      "icon_id": 62119,
      "icon_path": "062000/062119_hr1.tex",
      "actions": [
        {
          "id": 28,
          "name_cn": "钢铁信念",
          "name_tw": "鋼鐵信念",
          "icon_id": 2505,
          "icon_path": "002000/002505_hr1.tex",
          "category": "weaponskill|spell|ability",
          "level": 10,
          "range": 0,
          "effect_range": 1,
          "cast_100ms": 0,
          "recast_100ms": 20,
          "max_charges": 0,
          "description_cn": "...",
          "description_tw": "..."
        }
      ]
    }
  ],
  "role_actions": [ ... ],
  "category_names": {
    "weaponskill": { "en": "Weaponskill", "tw": "戰技" },
    "spell": { "en": "Spell", "tw": "魔法" },
    "ability": { "en": "Ability", "tw": "能力" }
  }
}
```

### Icon URL 組法

所有 icon（職業、技能）都用相同的 URL 模板：
```
https://beta.xivapi.com/api/1/asset/ui/icon/{icon_path}?format=png
```

範例：
- 職業 icon: `https://beta.xivapi.com/api/1/asset/ui/icon/062000/062119_hr1.tex?format=png`
- 技能 icon: `https://beta.xivapi.com/api/1/asset/ui/icon/002000/002505_hr1.tex?format=png`

建議用 AsyncImage 配合快取載入。

### 職業數量與技能分佈

- 21 個戰鬥職業，每職業 18~37 個技能
- 另有 24 個 Role Actions（共通技能），可暫時不處理或以獨立分類顯示
- category 分佈：ability(能力) 300 個、weaponskill(戰技) 175 個、spell(魔法) 157 個

## Swift Model 建議

```swift
struct BattleJob: Codable, Identifiable {
    let id: Int
    let nameCn: String
    let nameTw: String
    let abbreviation: String
    let iconId: Int
    let iconPath: String
    let actions: [BattleAction]
    
    enum CodingKeys: String, CodingKey {
        case id, abbreviation, actions
        case nameCn = "name_cn"
        case nameTw = "name_tw"
        case iconId = "icon_id"
        case iconPath = "icon_path"
    }
}

struct BattleAction: Codable, Identifiable {
    let id: Int
    let nameCn: String
    let nameTw: String
    let iconId: Int
    let iconPath: String
    let category: String          // "weaponskill" | "spell" | "ability"
    let level: Int
    let range: Int                // -1=melee, 0=self, N=yalms
    let effectRange: Int          // 0-1=single, N=AoE radius
    let cast100ms: Int            // 0=instant
    let recast100ms: Int
    let maxCharges: Int
    let descriptionCn: String?
    let descriptionTw: String?
    
    enum CodingKeys: String, CodingKey {
        case id, category, level, range
        case nameCn = "name_cn"
        case nameTw = "name_tw"
        case iconId = "icon_id"
        case iconPath = "icon_path"
        case effectRange = "effect_range"
        case cast100ms = "cast_100ms"
        case recast100ms = "recast_100ms"
        case maxCharges = "max_charges"
        case descriptionCn = "description_cn"
        case descriptionTw = "description_tw"
    }
}
```

## 注意事項

- 本專案為 SwiftUI，target iOS 17+
- 語言：目前名稱有 `name_cn`（簡中）和 `name_tw`（OpenCC 自動轉換的繁中，可能不完全準確）。先使用 `name_tw`，之後再優化翻譯。
- 先閱讀現有專案結構，了解 JSON 載入方式和既有的 View 模式再開始改
- `battle_actions.json` 如果尚未放入專案，請放到 Resources 或對應的 JSON 資料夾中
- Role Actions（共通技能）可以先不處理，第一版只做各職業自己的技能
- 編輯好的 Rotation 資料暫時不需要持久化儲存，先做 in-memory 即可
