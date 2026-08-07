# Phase C — 道具 Detail Page：採集

## 目標
在道具 detail page 新增 optional 的「採集」區塊，顯示該道具可在哪些採集點取得
（採礦 / 園藝，**不含釣魚**）。資料來自 `gathering.json`。

## 範圍（Phase C 只做這些）
- detail page 新增「採集」section
- 顯示採集職業 / 方式 / 等級 / 地點 / 座標
- 標示傳說、時限、隱藏等採集點特性

## 不在這個 Phase
- 釣魚採集點（已於轉檔階段排除，未來 Phase C2）
- 採集點地圖視覺化（先用文字 + 座標，地圖之後再說）
- 取得方式聚合區塊（Phase D）

---

## 資料來源

### gathering.json（隨此 Phase 一併加入專案）
- 結構：`{ "_meta": {...}, "gathering": { "<item_id>": [採集點, ...] } }`
- key 為可採集道具 id（字串），值為採集點陣列
- 單筆採集點欄位：
  - `job`：採集職業（string，礦工 / 園藝工）
  - `method`：採集方式（string，採掘 / 碎屑採集 / 伐木 / 採伐）
  - `level`：採集等級（int，1~100）
  - `zone_id`：地區 id（int）
  - `zone_name`：繁中地名（string，已由 PlaceName.csv 經 OpenCC s2t 轉換）
  - `x` / `y`：地圖座標（number）；`z` 已捨棄不提供
  - `map_id`：地圖 id（int）
  - `is_hidden`：是否為隱藏道具（bool，需特定條件才採得到）
  - `is_legendary`：是否為傳說採集點（bool）
  - `is_ephemeral`：是否為時限採集點（bool）
  - `is_limited`：是否限時出現（bool）
  - `spawns`：限時採集點出現的 ET 時段（int 陣列；非限時點為空陣列）
  - `duration`：限時採集點持續時間，單位分鐘（int；非限時點為 0）

### items.json（已在專案內）
- 道具名稱顯示一律用 `name_tw`

---

## 顯示邏輯（採集區塊）

1. 用當前 detail page 的 `item_id`（轉成字串）查 `gathering.gathering`
2. 查無 → 採集區塊整塊不 render（非採集取得道具）
3. 查到 → 顯示採集點陣列，每個採集點一列 / 一張子卡：
   - 職業 + 方式（例：「礦工・採掘」）
   - 採集等級（例：「Lv.25」）
   - 地點：`zone_name` + 座標（例：「高徑 (16.0, 19.5)」）
   - 採集點特性標籤（有才顯示）：
     - `is_legendary` → 「傳說」標籤
     - `is_ephemeral` → 「時限」標籤
     - `is_hidden` → 「隱藏」標籤
     - `is_limited` 且 `spawns` 非空 → 顯示出現 ET 時段
       （`spawns` 為 ET 整點，例 `[9]` 表示 ET 9:00 出現，
       搭配 `duration` 分鐘數）

---

## 顯示細節與備註

- 同一道具可能有多個採集點，全部列出（已依等級排序）
- 座標 `x` / `y` 為地圖座標，顯示到小數一位即可
- 限時 / 傳說採集點的 ET 時段：`spawns` 是 Eorzea Time 的整點數字。
  Phase C 先單純把時段數字顯示出來（例：「ET 9:00 ~ 12:00」），
  不需做 ET 即時倒數 / 與現實時間換算（那是之後的事）
- 隱藏道具（`is_hidden: true`）仍是有效採集來源，照常顯示，只是多一個
  「隱藏」標籤讓玩家知道需要特定條件

## 狀態處理
- `gathering.json` 為本地檔案，無網路請求，不需 loading / 錯誤狀態
- 唯一分支：查得到 → 顯示；查不到 → 區塊不 render

---

## 技術備註
- SwiftUI，target iOS 17+
- 採集區塊為 optional section：查無採集點則不 render
- `gathering.json` 體積約 684K，載入策略比照既有本地 JSON
- gathering model 用 `Codable` 對應上述 schema

## 驗收
- 可採集道具進入 detail page → 顯示採集區塊與正確職業 / 等級 / 地點
- 非採集道具 → 採集區塊不顯示
- 多採集點道具 → 全部採集點列出，依等級排序
- 傳說 / 時限 / 隱藏採集點 → 正確顯示對應標籤
- 限時採集點 → 顯示 ET 出現時段
