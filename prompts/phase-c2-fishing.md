# Phase C2 — 道具 Detail Page:釣魚採集

## 目標
把釣魚採集點補進 detail page 的「採集」區塊,跟既有的採礦/園藝並列。
釣魚資料採**精簡顯示**(地點 / 等級 / 星數 / 條件標籤),詳細釣法(bait /
時段 / 天氣)以外連到 Teamcraft 處理。

## 範圍(Phase C2 只做這些)
- 採集區塊整合釣魚點(新資料源 `fishing.json`)
- 每個釣魚點顯示:漁夫・釣魚 / 等級 / 星數 / 地點 / 座標 / 條件標籤
- 條件標籤:「限時」/「限天氣」/「需釣魚筆記」(三者各自獨立顯示)
- 每個釣魚點底下加「查看完整釣法 →」按鈕外連 Teamcraft

## 不在這個 Phase
- bait(魚餌)詳細資訊(資料來源不含 — 設計上交由 Teamcraft)
- ET 時段細節(同上)
- 天氣細節(同上)
- 釣場地圖視覺化(沿用 Phase C 的「先文字 + 座標」策略)
- mooch 鏈展開 / 大物預咬時間 / tug 訊號(留給未來 Phase C3 若要做)

---

## 資料來源

### fishing.json(隨此 Phase 加入專案)
- 結構:`{ "_meta": {...}, "fishing": { "<item_id>": [釣魚點, ...] } }`
- key 為可釣魚道具 id(字串),值為釣魚點陣列
- 單筆釣魚點欄位:
  - `job`:固定為「漁夫」(string)
  - `method`:固定為「釣魚」(string)
  - `level`:魚的採集等級(int,1~100)
  - `stars`:星數(int,0~4)
  - `zone_id`:地區 id(int)
  - `zone_name`:繁中地名(string,已經 PlaceName.csv + OpenCC s2t)
  - `x` / `y`:地圖座標(number)
  - `map_id`:地圖 id(int)
  - `is_timed`:是否限時(bool,但無具體時段)
  - `is_weathered`:是否限天氣(bool,但無具體天氣)
  - `has_folklore`:是否需釣魚筆記(bool)
  - `teamcraft_url`:Teamcraft 該魚詳細頁 URL(string)

### 與既有 gathering.json 的關係
- 兩份檔案**獨立並存**,不合併
  - 既有 `gathering.json`:採礦/園藝採集點
  - 新增 `fishing.json`:釣魚點
- UI 採集區塊查詢時兩份都查,合併顯示

---

## 採集區塊整合邏輯

### 顯示條件
若 `gathering.json` 或 `fishing.json` 任一中有此 item_id → 顯示採集區塊。
否則整塊不 render。

### 顯示順序
同一道具同時可採集(採礦/園藝)+ 可釣魚的情況極少,但仍可能存在。
- 採礦 / 園藝點先列(沿用 Phase C 排序:依等級 → zone_id)
- 釣魚點接在後(依等級 → zone_id)
- 各釣魚點之間以視覺分隔(子卡片或細線),不混在同一張卡

### 釣魚點單一卡片內容
**頂部資訊行**:
- 「漁夫・釣魚」(同 Phase C 採礦/園藝的職業・方式 樣式)
- 「Lv.{level}」
- 「★」× stars(stars=0 不顯示星)
- 條件標籤(有才顯示,並列):
  - `is_timed` → 「限時」標籤
  - `is_weathered` → 「限天氣」標籤
  - `has_folklore` → 「需釣魚筆記」標籤

**地點行**:
- 「📍 `{zone_name}` ({x:.1f}, {y:.1f})」(沿用 Phase C 樣式)

**底部外連按鈕**:
- 「查看完整釣法 →」
- 點擊 → 用系統瀏覽器開啟 `teamcraft_url`(SwiftUI `Link` 或 `openURL`)
- 視覺上要明顯是個按鈕 / 連結,但不搶過釣魚點本身的版面

---

## Phase D 取得方式目錄調整

「採集」這個來源項的判斷邏輯需更新為:
> `gathering.json` 中有此 item_id **OR** `fishing.json` 中有此 item_id
> → 「採集」算一種取得方式

點擊「採集」目錄項仍捲到採集區塊(該區塊現在含釣魚點)。
**不**為釣魚新增獨立目錄項 —— 釣魚與採礦/園藝在玩家認知裡同屬「採集職業」,
UI 應一致歸類。

---

## 狀態處理
- `fishing.json` 為本地檔案,無網路請求
- 外連 Teamcraft 點擊時直接交給系統處理,無 loading / 錯誤狀態(用 `openURL`,
  失敗由系統處理)

---

## 技術備註
- SwiftUI,target iOS 17+
- `fishing.json` 體積約 832K,載入策略比照既有本地 JSON
- fishing model 用 `Codable`,直接對應 schema
- Teamcraft 外連用 `Link(destination: URL)` 或 `Environment(\.openURL)`,
  不需內嵌 WebView
- 三種條件標籤建議用 enum + 色彩語意:
  - 限時(時間相關,藍 / 青)
  - 限天氣(環境相關,灰 / 紫)
  - 需釣魚筆記(門檻相關,黃 / 金)
  顏色由你的 design system 決定,prompt 不強制

## 驗收
- 可釣魚道具進入 detail page → 採集區塊顯示釣魚點
- 同時可採礦 + 可釣魚(罕見但存在) → 兩種都顯示,採礦在上、釣魚在下
- 不可釣魚也不可採集的道具 → 採集區塊不顯示
- 條件標籤對齊資料(例:涅普特龍 8754 應顯示「限天氣」而非「限時」)
- 點擊「查看完整釣法 →」 → 系統瀏覽器開啟正確的 Teamcraft URL
- Phase D「取得方式」目錄中,可釣魚的道具會顯示「採集」項
