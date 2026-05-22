# Phase B — 道具 Detail Page：配方

## 目標
在道具 detail page 新增「配方」區塊，顯示該道具**如何被製作出來**；
無法製作的道具也要顯示明確空狀態。
資料來自 `recipes.json`（已由 `Recipe.csv` + `RecipeLevelTable.csv` 轉檔產生）。

## 範圍（Phase B 只做這些）
- detail page 新增「配方」section
- 顯示「怎麼做出這個道具」（道具作為產出）
- 多重配方全部列出
- 材料 item 可點擊，push 一頁到該材料的 detail page

## 不在這個 Phase
- 用途反查（這道具被拿去做什麼）→ 之後的 Phase B2
- 配方材料的遞迴 / 巢狀展開（只顯示一層，靠導航堆疊探索）
- 採集、取得方式區塊（Phase C / D）

---

## 資料來源

### recipes.json（隨此 Phase 一併加入專案）
- 結構：`{ "_meta": {...}, "recipes": { "<產出item_id>": [recipe, ...] } }`
- key 為產出道具 id（字串），值為配方陣列（可多筆）
- 單筆 recipe 欄位：
  - `recipe_number`：配方自身編號（int）
  - `craft_type`：職業數字代碼（int，特殊配方為非標準值）
  - `craft_job`：職業名（string，木工/鍛冶/鎧甲/雕金/製革/裁縫/鍊金/烹調）；
    特殊配方為 `null`
  - `recipe_level`：所需職業等級（int，0~100）
  - `stars`：配方星數（int，0~5）
  - `result_amount`：一次製作產出的數量（int）
  - `ingredients`：材料陣列，每筆含
    - `item_id`：材料道具 id（int）
    - `amount`：所需數量（int）
    - `resolvable`：此 id 是否能在 items.json 對到（bool）

### items.json（已在專案內）
- 材料 / 產出道具的名稱、icon 由 `item_id` 對回 items.json 取得
- 道具名稱一律用 `name_tw`

---

## 顯示邏輯（配方區塊）

1. 用當前 detail page 的 `item_id`（轉成字串）查 `recipes.recipes`
2. 查無 → 仍 render「配方」區塊，內容顯示「無法製作」
3. 查到 → 顯示配方陣列：
   - 多筆配方全部列出，每筆一個子卡片 / 子區段
   - 每筆配方顯示：
     - 職業（`craft_job`；為 `null` 時顯示「特殊配方」之類字樣，不可空白）
     - 製作等級：`recipe_level` + `stars`
       （星數可用 ★ 呈現，例：「Lv.90 ★★」；stars=0 不顯示星）
     - 產出數量：`result_amount`（若 >1 要標示，例「產出 ×3」）
     - 材料清單：逐項顯示 材料名 ×數量

---

## 材料點擊行為

- 每個材料 item 顯示：icon + `name_tw` + `× amount`
- `resolvable == true`：整列可點擊，點擊 push 一頁到該材料的 detail page
  （重用既有 detail page view）
- `resolvable == false`：材料無法對到 items.json（少數新道具 / 殘值）
  - 顯示時退化為「道具 #<item_id>」之類，**不可點擊**
  - 不可因此 crash 或顯示空白列

### 導航備註
- 材料跳轉用 NavigationStack push。A→B→A 的循環導航是允許的
  （就是堆疊變深），不需做去重或防呆。
- 水晶 / 碎晶 / 微塵 這類低 id 材料（如 item_id 2、7）會頻繁出現在材料清單，
  它們在 items.json 對得到（`resolvable: true`）故可點擊，但跳過去通常沒有
  配方 / 市場資料 —— 這是正常的，不需特別處理。

---

## 狀態處理
- `recipes.json` 為本地檔案，無網路請求，不需 loading / 錯誤狀態
- 唯一分支：查得到配方 → 顯示配方；查不到 → 顯示「無法製作」

---

## 技術備註
- SwiftUI，target iOS 17+
- 配方區塊固定顯示：查無配方則顯示空狀態
- `recipes.json` 體積約 4.5MB，App 啟動或首次需要時載入並建記憶體索引；
  載入策略可比照既有 `items.json` 的做法
- recipe model 用 `Codable` 對應上述 schema

## 驗收
- 可製作道具進入 detail page → 顯示配方區塊與正確材料 / 職業 / 等級
- 非可製作道具 → 配方區塊顯示「無法製作」
- 多重配方道具 → 全部配方列出
- 點擊可解析材料 → 正確 push 到該材料 detail page
- 含不可解析材料的配方 → 該材料顯示為不可點擊、不 crash
- 產出數量 >1 的配方 → 正確標示產出數量
