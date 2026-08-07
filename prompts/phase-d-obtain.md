# Phase D — 道具 Detail Page：取得方式

## 目標
在道具 detail page 加入「取得方式」目錄區塊與「商店購買」內容區塊。
- 「取得方式」是頁內目錄,聚合 Phase A/B/C 與 Phase D 商店的判斷結果,
  點擊跳到對應區塊
- 「商店購買」是新區塊,顯示 NPC 商店售價

## 範圍（Phase D 只做這些）
- 新增「取得方式」目錄區塊
- 新增「商店購買」內容區塊(售價,NPC 與地點不提供)
- 串接 Phase A/B/C 既有區塊的判斷與捲動跳轉

## 不在這個 Phase
- 商店 NPC 名稱、所在地、所屬城鎮
- 任務 / 成就 / State 解鎖判斷(資料雖在 GilShopItem.csv,但暫不處理)
- 釣魚來源(Phase C2 之後)

---

## 資料來源

### item_shop.json(隨此 Phase 一併加入專案)
- 結構:`{ "_meta": {...}, "shop": { "<item_id>": { ... } } }`
- key 為道具 id(字串),值為:
  - `price_mid`(int,optional):NPC 售價 / 收購價(單位 Gil)
  - `in_gil_shop`(bool,optional):該道具是否確實出現在某間 GilShop 中
- **關鍵語意:**
  - **`in_gil_shop == true`** → `price_mid` 是「商店購買價」,可顯示為「商店購買」
  - **沒有 `in_gil_shop` / `in_gil_shop != true`** → `price_mid` 是「NPC 收購價」
    (玩家賣給 NPC 的價錢),**Phase D 不使用此情境**,不顯示為商店購買
- 道具完全沒在此檔案中 → 無商店資料

### 既有資料(來自 Phase A/B/C)
- 配方:用 `item_id` 查 `recipes.json` 是否有對應 → 可製作
- 採集:用 `item_id` 查 `gathering.json` 是否有對應 → 可採集
- 市場:items.json 的 `is_untradable == false` → 可在市場交易

---

## 「取得方式」目錄區塊

### 顯示條件
聚合下列四種來源的有無,得到一個 set:
1. 製作(`recipes.json` 中有此 item_id)
2. 採集(`gathering.json` 中有此 item_id)
3. 商店購買(`item_shop.json` 中此 item 的 `in_gil_shop == true`)
4. 市場交易(`is_untradable == false`)

- 來源數量 **≥ 2** → 顯示「取得方式」目錄區塊
- 來源數量 ≤ 1 → 目錄區塊**整塊不 render**
  - 0 種 → 沒有任何來源,detail page 上不出現任何來源相關區塊
  - 1 種 → 直接顯示該來源的內容區塊本身,不必再做目錄

### 顯示位置
道具基本資訊區塊**下方**、其他來源區塊**上方**。
理由:目錄需在內容之前,才有導覽意義。

### 顯示內容
每個來源一列,純跳轉按鈕風格,只包含:
- 來源圖示(製作 ti-hammer / 採集 ti-pick / 商店購買 ti-building-store /
  市場 ti-coins,Phase 一致)
- 來源名稱(製作 / 採集 / 商店購買 / 市場交易)
- 右側下箭頭(`ti-arrow-down`),暗示捲動跳轉

**不**在目錄項上顯示摘要數字(售價、材料數、最低等級等)—— 詳細資訊在下方
對應區塊本身。

### 點擊行為
點擊某個來源 → 平滑捲動到該來源的內容區塊。
SwiftUI 實作:`ScrollViewReader` + 每個來源區塊掛 `.id(SourceID)` 錨點,
點擊時 `proxy.scrollTo(id, anchor: .top)`,加 `withAnimation` 平滑。

---

## 「商店購買」內容區塊(新)

### 顯示條件
`item_shop.json` 中此 item 的 `in_gil_shop == true`。否則整塊不 render。

### 顯示內容
- 區塊標題:「商店購買」+ ti-building-store 圖示
- 售價:`price_mid` 數字大字 + 「G」字尾(數字使用千分位分隔,例 3,200 G)
- 一行小字附註:「售價來源:Item.PriceMid・NPC 與店家位置未提供」
  (讓玩家知道為什麼沒有 NPC / 地點資訊,避免被認為功能殘缺)

### 顯示位置
與其他來源區塊並列,排在「配方」「採集」「市場價格」之間。
具體建議順序(由上到下):配方 → 採集 → 商店購買 → 市場價格。
此順序由「玩家通常想優先知道哪一種」決定;若 UI 想調整可自行決定,
但需與目錄項點擊的捲動目標一致。

---

## 既有區塊行為調整

Phase A/B/C 區塊**現有顯示邏輯不變**,但需確認:
- 每個來源區塊掛上 `ScrollViewReader` 可定位的 id(供目錄跳轉)
- 若該 item 有 0 或 1 個來源 → 不顯示目錄區塊(見上)

## 狀態處理
- `item_shop.json` 為本地檔案,無網路請求
- 商店區塊:`in_gil_shop == true` → 顯示;否則整塊不 render
- 目錄區塊:依四種來源判斷的有無聚合決定是否顯示

---

## 技術備註
- SwiftUI,target iOS 17+
- 目錄區塊與商店區塊都是 optional section
- `item_shop.json` 體積約 1.4MB,載入策略比照既有本地 JSON
- shop model 用 `Codable`;`price_mid` 與 `in_gil_shop` 都是 optional
- 千分位數字格式化:`NumberFormatter` 或 `Int.formatted(.number)`
- 目錄項與對應區塊用 enum `ObtainSource` 統一管理,避免 id 字串散落

## 驗收
- 同時可製作 + 可採集 + 商店有賣 + 可市場交易的道具 → 顯示完整目錄
  4 項,商店區塊顯示售價
- 只能採集的道具 → 不顯示目錄,只顯示採集區塊
- 完全沒任何來源的道具 → 不顯示目錄、不顯示任何來源區塊
- 點擊目錄項 → 平滑捲動到對應區塊
- 商店有賣但無 `price_mid`(罕見) → 區塊仍顯示「商店購買」,但售價以
  「—」或「未提供」呈現,不可空白或 0
- `price_mid` 存在但 `in_gil_shop` 不為 true → 商店區塊**不**顯示
  (那是 NPC 收購價,非購買價)
