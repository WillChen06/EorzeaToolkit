# Phase A — 道具 Detail Page：市場價格

## 目標
在道具 detail page 新增一個 optional 的「市場價格」區塊，透過 Universalis API
查詢當前掛單與成交資料。這是道具 detail page 四大區塊（取得方式 / 配方 /
採集 / 市場價格）的第一個實作階段。

## 範圍（Phase A 只做這些）
- detail page 新增「市場價格」section
- 接 Universalis API 查價
- DC / world 範圍的全域設定
- loading / 錯誤 / 查無資料 狀態處理

## 不在這個 Phase（之後階段）
- 歷史價格走勢圖（Phase A2）
- 配方、採集、取得方式區塊（Phase B / C / D）
- 跨道具的查價快取策略（先用最單純的逐次查詢）

---

## 資料來源

### Universalis API
- Base：`https://universalis.app/api/v2`
- 端點：`GET /api/v2/{worldDcRegion}/{itemIds}`
- `{worldDcRegion}` 為 path 參數，可帶 world / DC / region，且可帶 **ID 或名稱**
  （文檔原文：This may be an ID or a name）
- `{itemIds}` 為 path 參數，單一 id 或逗號分隔多個（上限 100）。Phase A 只需單一 id
- 回傳含當前掛單（listings）、近期成交（recentHistory）、均價等欄位

#### Query 參數
- `listings`（query）：每件道具回傳的掛單數。**不帶則回傳全部掛單** ——
  熱門道具可能上百筆，務必設限。Phase A 設 **`listings=10`**
  （足夠算最低價，並為日後掛單預覽清單留餘裕）
- `entries`（query）：回傳的近期成交歷史筆數，預設最多 5。Phase A 設 `entries=5`
  （或不帶用預設）。近期均價可直接讀回傳的均價欄位，不必靠 entries 自行計算

組出的請求範例（預設範圍）：
`https://universalis.app/api/v2/陸行鳥/{itemId}?listings=10&entries=5`

### items.json
- 每筆 item 已有 `is_untradable` 布林欄位 → 直接讀，不需另查
- 每筆 item 已有 `can_be_hq` 布林欄位 → 決定要不要分 NQ / HQ 顯示

---

## DC / world 範圍設定

做成 **App 全域設定**（不是每個道具各自選）。

- 預設值：DC「陸行鳥」（查整個 DC 的聚合資料）
- 不記憶使用者上次選擇 —— 每次 App 啟動都回到預設「陸行鳥」
- 可選範圍：
  - DC：陸行鳥（預設）
  - World：伊弗利特 / 迦樓羅 / 利維坦 / 鳳凰 / 奧汀 / 巴哈姆特 / 拉姆 / 泰坦
- 市場價格區塊讀這個全域設定值來組 API 路徑
- 設定變更後，已開啟的 detail page 市場區塊重新查詢即可（不需特別做即時同步，
  下次進入 detail page 生效也可接受 —— 實作簡單者優先）

### 名稱參數備註（實作時確認一次即可）
Universalis 文檔已明示 `worldDcRegion` 可帶名稱，且 region 範例直接列出
中文「中国」，繁中服 world / DC 中文名（陸行鳥、迦樓羅 等）能直接帶的機率很高。
實作時用一個可交易道具打一發 API 確認即可，不需事先建對照表。
若中文名意外不可行，再退回建「中文名 → API 參數（英文名 or 數字 id）」對照表。

---

## 顯示內容（市場價格區塊）

可交易道具且查詢成功時顯示：
- 當前最低價：NQ 與 HQ 分開列（`can_be_hq == false` 的道具只顯示 NQ）
- 近期平均成交價
- 資料最後更新時間（Universalis 是群眾上傳，需讓使用者知道新鮮度）
- 目前查詢範圍標示（例：「DC 陸行鳥」或「迦樓羅」）—— 讓使用者清楚現在
  看的是整個 DC 還是單一 world
- 「在 Universalis 開啟」外連按鈕

---

## 狀態處理

市場價格區塊需區分以下狀態：

1. **不可交易**（`is_untradable == true`）
   - 不打 API
   - 區塊顯示「此道具無法在市場交易」灰字，或整塊不 render（擇一，UI 決定）

2. **Loading**
   - 查詢中顯示 loading 指示

3. **查無資料**（API 成功回應，但該道具無掛單 / 無成交）
   - 冷門道具的正常情況
   - 顯示「目前無市場資料」之類訊息
   - 必須與「API 錯誤」明確區分

4. **API 錯誤**（網路失敗、Universalis 服務異常、逾時）
   - 顯示錯誤訊息 + 可重試
   - 不可與「查無資料」混為一談

---

## 技術備註
- SwiftUI，target iOS 17+
- 市場區塊為 optional section：依狀態決定是否 render
- 道具名稱顯示一律用 `name_tw`
- API model 用 `Codable` 對應 Universalis 回傳；只解出需要的欄位即可，
  不必對應整個 response

## 驗收
- 可交易道具進入 detail page → 顯示市場價格區塊與正確數據
- 不可交易道具 → 區塊不顯示（或顯示無法交易說明）
- 切換全域 DC / world 設定 → 查詢範圍正確改變
- 斷網 / 逾時 → 顯示錯誤狀態且可重試
- 冷門但可交易道具（無掛單）→ 顯示「查無資料」而非錯誤
