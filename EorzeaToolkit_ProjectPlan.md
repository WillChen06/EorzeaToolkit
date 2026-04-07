# Eorzea Toolkit — 專案計畫

## 專案概述

一款 iOS App，讓玩家在 App 內快速查閱 FF14 遊戲資料（藏寶圖位置、海釣資訊、副本資訊、發光武器等），並可追蹤個人進度，不需每次重新 Google 搜尋。

## 技術規格

| 項目 | 選擇 |
|------|------|
| Language | Swift / SwiftUI |
| 最低支援版本 | iOS 17+ |
| IDE | VSCode + Claude Code CLI |
| Source Control | GitHub |
| 資料策略 | 本地 JSON 為主，API 為輔 |
| 本地儲存 | SwiftData（進度追蹤、使用者筆記） |
| App 語言 | 繁體中文（預留多語系架構） |
| License | MIT |

## Source Control
遵照Git flow，建立對應branch

## 資料策略

### 本地 JSON（主要）

遊戲攻略類資料，更新頻率低，適合離線使用：

- 藏寶圖地點座標與地圖對照
- 發光武器（版本武器）製作步驟與素材
- 海釣時刻表（固定循環規則）
- 副本攻略筆記

### API 為輔（未來擴充）

如需查詢道具、技能等遊戲原始資料時：

- XIVAPI v2（`https://v2.xivapi.com`）— 支援 EN/JA/DE/FR，**不支援中文**
- Cafemaker（`https://cafemaker.wakingsands.com`）— 簡體中文（國服資料）
- 策略：需要時用 XIVAPI 拿日文/英文資料，搭配本地中文對照表

## 專案結構

```
EorzeaToolkit/
├── EorzeaToolkit/
│   ├── App/
│   │   └── EorzeaToolkitApp.swift         # App entry point
│   ├── Models/
│   │   ├── TreasureMap.swift              # 藏寶圖資料模型
│   │   ├── RelicWeapon.swift              # 發光武器資料模型
│   │   ├── OceanFishing.swift             # 海釣資料模型
│   │   └── ProgressRecord.swift           # 進度追蹤模型（SwiftData）
│   ├── Views/
│   │   ├── MainTabView.swift              # 主要 Tab 導航
│   │   ├── TreasureMap/
│   │   │   ├── TreasureMapListView.swift
│   │   │   └── TreasureMapDetailView.swift
│   │   ├── RelicWeapon/
│   │   │   ├── RelicWeaponListView.swift
│   │   │   └── RelicWeaponDetailView.swift
│   │   ├── OceanFishing/
│   │   │   └── OceanFishingView.swift
│   │   └── Progress/
│   │       └── ProgressTrackerView.swift
│   ├── ViewModels/
│   │   ├── TreasureMapViewModel.swift
│   │   ├── RelicWeaponViewModel.swift
│   │   └── OceanFishingViewModel.swift
│   ├── Services/
│   │   ├── LocalDataService.swift         # 讀取本地 JSON
│   │   └── XIVAPIService.swift            # API 請求（未來擴充）
│   ├── Resources/
│   │   └── Data/
│   │       ├── treasure_maps.json         # 藏寶圖資料
│   │       ├── relic_weapons.json         # 發光武器資料
│   │       └── ocean_fishing.json         # 海釣資料
│   └── Localization/
│       ├── zh-Hant.lproj/
│       │   └── Localizable.strings
│       └── en.lproj/
│           └── Localizable.strings
├── EorzeaToolkit.xcodeproj
└── README.md
```

## 開發階段

### Phase 1：專案骨架（目前）

- [ ] 建立 Xcode 專案（SwiftUI, iOS 17+）
- [ ] 推上 GitHub repo - https://github.com/WillChen06/EorzeaToolkit.git
- [ ] 建立 Swift git ignore檔案，推上GitHub
- [ ] 建立 MainTabView（Tab 導航框架）
- [ ] 建立 LocalDataService（JSON 讀取服務）
- [ ] 準備一份範例 JSON 資料（藏寶圖或發光武器擇一）
- [ ] 建立對應的 Model + ViewModel + View（列表 + 詳情頁）

### Phase 2：核心功能完善

- [ ] 完成藏寶圖模組（座標、地圖名稱、備註）
- [ ] 完成發光武器模組（版本分類、步驟列表、素材需求）
- [ ] 搜尋功能

### Phase 3：進度追蹤

- [ ] SwiftData 設定
- [ ] 進度記錄 Model（ProgressRecord）
- [ ] 進度條 UI（已完成 / 總步驟）
- [ ] 支援多個目標同時追蹤

### Phase 4：海釣時刻表

- [ ] 海釣時間循環計算邏輯
- [ ] 當前/下次航班顯示
- [ ] 目標魚種與釣餌對照

### Phase 5：Polish & 擴充

- [ ] 多語系支援（英文、日文）
- [ ] 收藏功能
- [ ] API 整合（XIVAPI v2）
- [ ] 深色模式適配
- [ ] Widget（桌面小工具，如海釣倒數）

## JSON 資料結構範例

### 藏寶圖（treasure_maps.json）

```json
{
  "maps": [
    {
      "id": "timeworn_loboskin",
      "name": "古舊的山羊革地圖",
      "name_en": "Timeworn Loboskin Map",
      "name_ja": "古びた山羊革の地図",
      "level": 40,
      "locations": [
        {
          "zone": "東乞靈草原",
          "zone_en": "East Shroud",
          "coordinates": { "x": 25.3, "y": 19.7 },
          "notes": "靠近悄語洞窟入口"
        }
      ]
    }
  ]
}
```

### 發光武器（relic_weapons.json）

```json
{
  "expansions": [
    {
      "id": "arr",
      "name": "新生艾奧傑亞",
      "name_en": "A Realm Reborn",
      "weapons": [
        {
          "id": "curtana_zenith",
          "name": "聖劍天頂",
          "name_en": "Curtana Zenith",
          "job": "PLD",
          "steps": [
            {
              "step": 1,
              "title": "基礎武器取得",
              "description": "完成職業任務取得聖劍",
              "materials": [
                { "name": "蠻神白銀鏡", "quantity": 3 }
              ]
            }
          ]
        }
      ]
    }
  ]
}
```

## Claude Code 使用指引

在 Claude Code CLI 中開始時，可以這樣下指令：

```
# Phase 1 起步
請根據 EorzeaToolkit_ProjectPlan.md 建立 iOS 專案骨架。
使用 SwiftUI，目標 iOS 17+。
先建立專案結構、MainTabView、和 LocalDataService。
準備一份藏寶圖的範例 JSON 資料，並建立對應的 Model、ViewModel、View。
```

## 備註

- 遊戲資料來源：灰機wiki、素素攻略、狩獵時刻等中文社群網站
- 圖片資源：暫不放入，先用文字座標，後期再考慮地圖截圖
- 不吃煮熟的番茄（跟專案無關但很重要）
