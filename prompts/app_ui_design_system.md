---
description: Extend the home adventurer-manual visual language across every existing feature screen
---

# App-wide UI Design System

## 目標

將首頁既有的明亮奇幻冒險手冊設計延伸至所有現有功能頁，使背景、文字、surface、
navigation 與互動強調色一致，同時保留各功能及狀態資訊的辨識性。

本 Phase 採輕量冒險手冊風格：功能頁使用羊皮紙背景、墨色文字、卡片 surface 與古金細節，
但不在每個 row 複製首頁的華麗角飾，以資料密度、可讀性與原生互動為優先。

## 範圍（這個 Phase 只做這些）

- 將首頁既有色彩整理為全 App 共用的語意化 design tokens。
- 統一頁面背景、主要／次要文字、卡片、list row、form section、邊框、陰影與 tint。
- 統一 navigation bar、toolbar、搜尋／篩選區域及 sheet 的視覺銜接。
- 套用至所有目前可由首頁進入的功能與子畫面：
  - 道具搜尋、篩選 sheet、道具詳情、配方、採集、商店、取得方式與市場價格區塊。
  - 藏寶圖列表、詳情、點位列表、採集點 sheet 與採集點全螢幕地圖。
  - 古武列表、系列追蹤與階段內容。
  - 仙人彩輸入、棋盤、結果與賠率內容。
  - 技能職業列表、循環編輯器與 context-menu preview 卡片。
- 使用首頁既有功能識別色作為各功能的主要互動 tint：
  - 道具搜尋：Crystal。
  - 藏寶圖：Gold。
  - 古武：Aether Blue。
  - 仙人彩：Crimson。
  - 技能循環：Crystal。
- 保留完成、錯誤、警告、稀有度、採集類型與技能分類等領域／狀態色。
- 支援既有 iOS 17 deployment target、Light Mode、Dark Mode、Dynamic Type、iPhone portrait
  與 iPad layout。

## 不在這個 Phase

- 不修改功能邏輯、資料模型、資料來源或導航資訊架構。
- 不新增功能、設定頁、插圖或其他媒體資產。
- 不將所有領域／狀態色收斂成單一品牌色。
- 不重做藏寶圖或採集地圖本身，也不改變其座標與 marker 行為。
- 不強制改造系統 confirmation dialog 或 context menu 的原生表面；只統一觸發元件、
  preview 與可由 SwiftUI theme 控制的 tint。
- 不導入第三方 UI framework、snapshot-test framework 或新的 UI test target。
- 不進行與主題套用無關的大型 view、navigation 或 state-management refactor。

---

## 資料來源

本 Phase 不新增或修改 gameplay data。設計基準來自：

- `EorzeaToolkit/Views/Home/HomeStyle.swift`：首頁現有背景、surface、文字、品牌色與陰影。
- `EorzeaToolkit/Resources/Assets.xcassets/HomeColors`：具 Light／Dark appearance 的既有色票。
- `EorzeaToolkit/Views/Home/HomeFeature.swift`：五個功能與既有識別色的對應。

若整理色票名稱或位置，需保留既有 Light／Dark 色值意圖，不得讓首頁與功能頁各自維護
語意相同的重複顏色。

## 共用視覺語言

### 背景與 surface

- 非媒體頁面使用與首頁相同家族的羊皮紙漸層作為 page background。
- `List` 與 `Form` 保留原生容器語意、捲動、selection 與 accessibility 行為，但隱藏預設
  system grouped background，改用共用 page background。
- List row、form row、detail section 與資訊卡使用共用 surface；需要層次時可使用統一的
  邊框或陰影，不在資料密集 row 加入首頁角飾。
- Sheet 使用相同 page／surface 語言，避免 sheet 內突然回到系統灰白背景。

### 文字

- 一般標題與主要內容使用共用 ink 色。
- 說明、metadata 與次要內容使用共用 muted ink 色。
- 文字繼續使用 Dynamic Type text styles；主題套用不得依賴固定字級才能成立。
- 疊在地圖或圖片上的文字可維持白字、深色遮罩與 shadow，以媒體可讀性優先。

### 強調色與狀態色

- 功能頁的主要 Button、link、selection、picker、toggle 與 navigation tint 使用該功能的
  識別色。
- Gold 也作為全 App 的裝飾邊框色，但裝飾用途不得取代功能識別 tint 或狀態語意。
- destructive、error、warning、success、rarity、gathering type 與 skill category 保留各自
  的語意；顏色是重要差異時，同時保留 icon、文字或形狀等非色彩線索。

### Navigation 與系統元件

- 根 NavigationStack 與所有 push destination 的 toolbar、back button、scroll-edge appearance
  應與主題背景銜接，不出現突兀的系統藍或不透明系統灰底。
- Search、filter、confirmation dialog 與 context menu 保留 SwiftUI 原生互動；只調整原生 API
  可安全控制的背景、surface 與 tint。
- 現有地圖 image overlay 為媒體例外：保留黑／白高對比呈現，外層 navigation 與資訊 surface
  仍套用全域主題。

### 可及性與適應性

- 新增或調整的互動元件維持至少 44 × 44 pt hit area。
- Theme 不使用固定字級覆蓋 Dynamic Type，也不以固定高度裁切文字。
- Light／Dark appearance 都需維持主要文字、次要文字、surface 與 tint 的清楚對比。
- iPhone portrait 與 iPad 上不得因主題 wrapper、背景或 row surface 遮住內容或互動元件。

---

## 驗收

- **AC-1** `[人工]` 從首頁進入五個第一層功能頁時，頁面皆延續同一套羊皮紙背景、墨色文字
  與 surface 語言，不出現未處理的 system grouped 灰底。
- **AC-2** `[人工]` 所有可進入的 detail page 與 sheet 均使用一致的 page、row、card 與 section
  surface。
- **AC-3** `[人工]` Navigation bar、back button、toolbar、搜尋與主要控制項在捲動前後均與頁面
  主題協調，不出現未處理的系統藍。
- **AC-4** `[人工]` 五項功能的主要互動強調色依既有首頁對應顯示：道具搜尋與技能循環為
  Crystal、藏寶圖為 Gold、古武為 Aether Blue、仙人彩為 Crimson。
- **AC-5** `[人工]` 完成、錯誤、警告、稀有度、採集類型與技能分類仍可透過其文字、icon、形狀
  或保留的語意色辨識，未被全域品牌色取代。
- **AC-6** `[人工]` 藏寶圖及採集地圖的圖片 overlay 維持足夠對比，且外層 navigation、背景與
  資訊卡符合全域主題。
- **AC-7** `[人工]` Light Mode 與 Dark Mode 下，首頁及所有功能流程的背景、主要文字、次要文字、
  邊框與互動元件皆清楚可讀。
- **AC-8** `[人工]` iPhone portrait 與 iPad 上，調整後的 background 與 surface 不造成內容裁切、
  遮住互動元件或改變既有 navigation flow。
- **AC-9** `[人工]` Dynamic Type 放大至 Accessibility 文字尺寸時，本次調整的標題、卡片與控制項
  仍可閱讀及操作。
- **AC-10** `[diff]` 共用視覺色彩來自同一組語意 token；功能 view 不新增重複的 hard-coded RGB
  或 UIKit system background。
- **AC-11** `[diff]` 領域／狀態色與地圖媒體色明確保留為例外，不被全域品牌色覆蓋。
- **AC-12** `[diff]` 新增的使用者可見文字全部透過 `Localizable.xcstrings`；若沒有新增文案，
  字串目錄不產生功能性變更。

## 驗證方式

- Build：`xcodebuild build -project EorzeaToolkit.xcodeproj -scheme EorzeaToolkit -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO`
- Tests：`./scripts/run_tests.sh`
- 人工矩陣：五個首頁入口及其子頁／sheet，至少各檢查 iPhone portrait Light／Dark；另以 iPad
  檢查主要列表、detail、sheet 與全螢幕地圖。
- Accessibility：至少以一組 Accessibility Dynamic Type 尺寸檢查主列表、detail 與 editor。
