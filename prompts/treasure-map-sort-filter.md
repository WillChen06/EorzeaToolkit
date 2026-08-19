# 藏寶圖列表排序與篩選

在使用者於本文件簽核前,以下內容視為草稿,不得作為實作依據。

---

## 目標

藏寶圖列表（`TreasureMapListView`）目前固定依資料檔原始順序（G1→G18 遞增）顯示，
使用者無法改變順序，也無法依版本或等級縮小清單範圍。本 Phase 讓使用者可以：

1. 以「等級序號」（grade 後方數字）切換升冪／降冪排序。
2. 依「大版本」與「等級」多選篩選清單，並可一鍵清除。

## 範圍（這個 Phase 只做這些）

- 藏寶圖列表預設依 grade 數字降冪排序（G18→G1），提供獨立控制切換為升冪（G1→G18）。
- 提供獨立的篩選入口，開啟完整 filter sheet：
  - 版本篩選：選項由目前已載入資料的 `expansion` 動態推導、去重、依大版本（整數部分）由小到大
    排序後產生（以目前資料為例為 2.x／3.x／4.x／5.x／6.x／7.x），可多選。
  - 等級篩選：選項由目前已載入資料的 `level` 動態推導、去重、由小到大排序後產生（以目前資料為例為
    40、45、50、55、60、70、80、90、100），可多選。
  - 同一類別內為 OR，不同類別之間為 AND；某類別未選取任何選項時，該類別不限制結果。
  - 篩選入口顯示「已選版本數＋已選等級數」加總的徽章（例如版本選 2 個、等級選 2 個時顯示 `4`）；
    未套用任何篩選時不顯示徽章。
  - 提供「清除全部篩選」，點擊後徽章消失。
- 篩選後清單為空時，顯示專屬空結果畫面（含「清除篩選」按鈕），與現有的「尚未載入資料／載入失敗」空狀態區分。
- 「清除篩選」只清空版本與等級篩選，不影響目前排序方向。
- 排序方向與篩選條件不持久化：離開畫面重新進入、或 App 重新啟動後，一律重置為預設（降冪、未篩選）。

## 不在這個 Phase

- 不使用 `AppStorage`／`UserDefaults`（或其他形式）保存排序或篩選狀態。
- 不新增「依等級區間」（如低等級／高等級）之類的自訂分組篩選；等級篩選僅用原始精確數值。
- 不在版本篩選選項中顯示資料片名稱（如「蒼穹之禁城」），僅顯示大版本代碼（如 `2.x`）。
- 不把版本或等級篩選選項寫死成固定清單；兩者的選項皆一律依已載入資料動態推導。
- 不變更藏寶圖詳情頁（`TreasureMapDetailView`）、採集點 sheet（`GatheringNodesSheetView`）的既有邏輯。
- 不新增依 `type`（solo／party）或其他欄位的篩選維度。
- 不處理搜尋（文字關鍵字查詢）。

---

## 資料來源

- `EorzeaToolkit/Resources/Data/treasure_maps_final.json`：唯一資料來源，經
  `LocalDataService.load("treasure_maps_final")` 解碼為 `TreasureMapFinalData`，目前共 18 筆 `TreasureMap`。
- `TreasureMap.grade`（`EorzeaToolkit/Models/TreasureMap.swift`）：字串 `"G1"`～`"G18"`。
  **容易搞錯的地方**：字串比較不等於數字比較（例如降冪排序時 `"G9"` 與 `"G10"` 用字串比較會得到與數字排序不一致的結果），
  排序與分組邏輯必須先把 grade 轉成 `Int` 再比較。
- `TreasureMap.expansion`：字串版本號，目前資料集合為
  `2.1 / 3.0 / 4.0 / 5.0 / 6.0 / 6.3 / 7.0 / 7.3`（共 8 個相異值）。
  **容易搞錯的地方**：`expansion` 是資料片內的細部版本號，不是要顯示給使用者的篩選選項；
  篩選選項要在執行時依目前已載入資料的 `expansion` 動態推導 —— 取整數部分分組成大版本
  （例如 `6.0` 與 `6.3` 都屬於 `6.x`）、去重、由小到大排序，不可把選項清單寫死成固定值。
  以目前資料為例，結果會是 `2.x、3.x、4.x、5.x、6.x、7.x` 六組，但這是資料現況推導出的結果，
  不是規格規定死的清單，未來資料若新增其他版本號，選項應自然涵蓋。
- `TreasureMap.level`：`Int`，目前資料集合為 `40, 45, 50, 55, 60, 70, 80, 90, 100`（共 9 個相異值）。
  **容易搞錯的地方**：等級篩選選項要在執行時依目前已載入資料的 `level` 動態推導 —— 去重、由小到大
  排序，不可把選項清單寫死成固定值。以目前資料為例，結果會是 `40、45、50、55、60、70、80、90、100`，
  但這是資料現況推導出的結果，不是規格規定死的清單；未來資料若新增其他等級（例如 `110`），該等級應
  自動出現在篩選選項中。
- `TreasureMapViewModel.loadMaps()`（`EorzeaToolkit/ViewModels/TreasureMapViewModel.swift`）：
  目前直接把 `finalData.maps` 指派給 `maps`，未排序、未篩選。本 Phase 需要在此基礎上新增排序／篩選的
  衍生狀態與計算後的顯示清單，但不得更動 `loadMaps()` 對資料本身的解析邏輯。

---

## 使用者流程

1. 使用者進入藏寶圖列表，畫面預設顯示依 grade 數字降冪（G18→G1）排序、未套用任何篩選的完整清單。
2. 使用者點擊排序控制，清單切換為升冪（G1→G18）；再次點擊切回降冪。排序控制與篩選入口為兩個獨立元件。
3. 使用者點擊篩選入口，開啟 filter sheet，可分別在「版本」與「等級」區塊多選條件；每次勾選或取消勾選
   都立即套用到背後的藏寶圖清單，不需要另外的「套用」操作。
4. 使用者點擊「完成」關閉 filter sheet（此按鈕僅關閉畫面，不做額外套用動作）；篩選入口顯示
   「已選版本數＋已選等級數」總和的徽章。
5. 若篩選結果為空，畫面顯示「找不到符合篩選條件的藏寶圖」與「清除篩選」按鈕；
   點擊「清除篩選」清空版本與等級篩選、恢復完整清單，但維持使用者目前的排序方向。
6. 使用者也可在 filter sheet 內使用「清除」按鈕（即清除全部篩選）達到同樣效果，此時徽章消失。
7. 使用者離開藏寶圖列表再重新進入，或重新啟動 App，排序與篩選一律重置為步驟 1 的預設狀態。

---

## 排序功能

- 排序依據：`grade` 後方數字（`Int`），不得使用字串比較。
- 預設方向：降冪（G18 在最前、G1 在最後）。
- 使用者可切換為升冪（G1 在最前、G18 在最後），也可切回降冪。
- 排序控制與篩選入口為畫面上兩個獨立、可分別互動的元件（例如各自的工具列按鈕），不可合併成單一控制或選單。
- 排序方向的改變只影響清單顯示順序，不影響目前已套用的篩選條件。

## 篩選功能（Filter Sheet）

- 入口：獨立於排序控制的按鈕／圖示，點擊後以獨立畫面（sheet）呈現，不直接在列表上以行內控制篩選。
- 版本篩選：
  - 選項在執行時依目前已載入資料的 `expansion` 動態推導：取整數部分分組成大版本、去重、由小到大排序；
    不可把選項清單寫死成固定值。以目前資料為例，結果為 `2.x、3.x、4.x、5.x、6.x、7.x`。
  - 只顯示版本代碼，不顯示資料片名稱。
  - 可多選；未勾選任何選項時，版本這一類別不限制清單結果。
- 等級篩選：
  - 選項在執行時依目前已載入資料的 `level` 動態推導：去重、由小到大排序；不可把選項清單寫死成固定值。
    以目前資料為例，結果為 `40、45、50、55、60、70、80、90、100`。
  - 可多選；未勾選任何選項時，等級這一類別不限制清單結果。
- 篩選組合邏輯：同一類別內為 OR，不同類別之間為 AND。
  例：版本勾選 `6.x、7.x`，等級勾選 `90、100` 時，只顯示「屬於 6.x 或 7.x」且「等級為 90 或 100」的藏寶圖。
- 套用時機：使用者在 filter sheet 內勾選或取消勾選版本／等級選項時，篩選立即套用到背後的藏寶圖清單，
  不需要另外的「套用」按鈕確認 —— 比照既有 `ItemFilterSheet`（`Views/ItemSearch/ItemSearchView.swift`）
  的即時套用行為，不新增與既有設計不同的 Apply 按鈕。
- filter sheet 工具列：只有「清除」（尚未套用任何篩選時停用，比照既有 `viewModel.filter.isActive` 的
  停用條件）與「完成」（僅呼叫 dismiss 關閉畫面，不執行任何套用／確認動作）兩個按鈕。
- 已套用篩選徽章：篩選入口顯示「已選版本數＋已選等級數」加總的徽章數字（例如版本選 2 個、等級選 2 個時
  顯示 `4`）；未套用任何篩選時不顯示徽章。
- 「清除全部篩選」：filter sheet 內提供一鍵清空版本與等級所有已選項目的按鈕（即上述「清除」按鈕），
  點擊後徽章消失。

## 空結果狀態

- 觸發條件：套用篩選後，符合條件的藏寶圖數量為 0（此狀態與「尚未載入資料」「載入失敗」為互斥的不同狀態，
  後兩者沿用現有的 `loadError` / `hasLoadedMaps` 邏輯與既有文案，不在本 Phase 變更）。
- 顯示內容：文字「找不到符合篩選條件的藏寶圖」＋「清除篩選」按鈕。
- 「清除篩選」按鈕行為：清空版本與等級篩選（等同觸發「清除全部篩選」），清單恢復顯示目前已載入的完整
  藏寶圖集合；不影響、不重置目前的排序方向。

---

## 技術設計與影響範圍

- `EorzeaToolkit/Models/TreasureMap.swift`：可能新增 grade 轉數字的衍生邏輯，以及「依已載入資料動態推導
  大版本篩選選項」（依 expansion 整數部分分組、去重、排序）與「依已載入資料動態推導等級篩選選項」
  （去重、排序）的邏輯（純運算屬性或獨立函式，不改變 `TreasureMap` 既有的 `Codable` 對應與 JSON 欄位）。
- `EorzeaToolkit/ViewModels/TreasureMapViewModel.swift`：新增排序方向、已選版本、已選等級的狀態，
  以及依此計算顯示清單的邏輯；`loadMaps()` 本身的資料解析與既有的 `zonesByItemId` / `spotsByKey` 組裝邏輯不變。
- `EorzeaToolkit/Views/TreasureMap/TreasureMapListView.swift`：新增排序控制、篩選入口按鈕、
  filter sheet 呈現、空結果狀態分支；既有的 `NavigationLink` → `TreasureMapDetailView` 與
  `GatheringNodesSheetView` 呼叫路徑不變。
- 新增 filter sheet 畫面：套用／關閉互動需與 `ItemSearchViewModel` / `ItemFilter` 既有的
  `ItemFilterSheet`（即時套用、「清除」＋「完成」兩按鈕、`activeFilterCount` 徽章）一致，
  不要求重用 `ItemFilter` 型別本身。
- `EorzeaToolkit/Localization/L10n.swift` 及對應語系資源：新增排序控制、篩選入口、篩選徽章、
  「找不到符合篩選條件的藏寶圖」、「清除篩選」等文案的 key。
- 本 Phase 不修改 `project.yml`、`EorzeaToolkit.xcodeproj`、target、依賴或 Scheme。

---

## 風險、假設與待確認事項

- 排序控制、篩選入口的圖示、確切文案與畫面配置（例如放在 `.toolbar` 的哪個位置）未經使用者逐一確認，
  由 DeveloperBot 依現有畫面（`TreasureMapListView` 既有的 `appThemedScreen` 風格）與 App 既有的
  `RelicWeaponListView` / `ItemSearchView` 慣例決定，若有明顯偏離既有設計系統的情況應在 PR 中說明。
- 本文件的驗收條件以「行為」描述，實作時若發現條件與既有程式架構衝突（例如
  `TreasureMapViewModel` 現有的 `@Observable` 狀態管理方式使某條件難以達成），
  依 repo 慣例應回頭修改本節並在 PR 說明修改原因，而非默默改變行為。

---

## 驗收

**這一節在 Codex 開工前就要寫定。** 若實作中發現某條有誤，應回頭修改本節並在 PR 說明改了什麼、為什麼。

驗證途徑：`[自動]` 有 unit test 可證明；`[diff]` 讀 diff 即可確認；`[人工]` 需在真機／模擬器上操作才能確認
（本文件不宣稱可在目前的 Linux 開發環境執行 Xcode 或 Simulator 驗證，`[人工]` 一律由人於 macOS
以 Xcode／Simulator 執行後確認）。以下 `[自動]` 條件所列的測試名稱是實作時必須建立、或必須明確對應的
測試名稱，不是建議命名；可讓一個測試方法涵蓋一條或多條 AC，但每條 `[自動]` 都必須能對應到一個實際
存在的測試方法。

- **AC-1** `[自動]` 未套用任何篩選、剛進入畫面時，清單依 grade 數字降冪排序，第一筆為 grade `G18`、
  最後一筆為 grade `G1` —— `TreasureMapGradeSortingTests.testDefaultOrderIsDescendingByGradeNumber`
- **AC-2** `[自動]` 排序比較邏輯以 grade 轉換後的 `Int` 數值比較，而非字串比較 —— 以 `G9` 與 `G10` 為例，
  降冪排序時 `G10` 必須排在 `G9` 之前（若用字串比較會得到相反或不一致的結果）——
  `TreasureMapGradeSortingTests.testGradeNumberComparisonRanksG10AboveG9InDescendingOrder`
- **AC-3** `[自動]` 使用者觸發排序方向切換後，清單依 grade 數字升冪排序，第一筆為 `G1`、最後一筆為 `G18`
  —— `TreasureMapGradeSortingTests.testAscendingOrderRanksGradeNumberFromG1ToG18`
- **AC-4** `[diff]` 排序控制與篩選入口為畫面上兩個獨立的可互動元件（各自綁定獨立的 action /
  navigation，不共用同一個按鈕或選單項目）。
- **AC-5** `[人工]` 點擊篩選入口會以獨立畫面（sheet）呈現版本與等級篩選選項，而非在原本清單上直接顯示篩選控制。
- **AC-6** `[自動]` filter sheet 的版本篩選選項由目前已載入資料的 `expansion` 動態推導、依整數部分分組、
  去重、由小到大排序產生；以目前資料為例，結果為 `2.x、3.x、4.x、5.x、6.x、7.x`，且選項清單不是寫死的
  固定值 —— `TreasureMapFilterOptionsTests.testVersionOptionsAreDerivedFromLoadedExpansionsDeduplicatedAndSorted`
- **AC-7** `[自動]` `expansion` 為 `6.0` 與 `6.3` 的藏寶圖，在版本分組邏輯下皆歸類於同一個 `6.x` 選項
  —— `TreasureMapFilterOptionsTests.testExpansionsSharingMajorVersionGroupIntoOneOption`
- **AC-8** `[自動]` filter sheet 的等級篩選選項由目前已載入資料的 `level` 動態推導、去重、由小到大排序
  產生；以目前資料為例，結果為 `40、45、50、55、60、70、80、90、100`，不含任何區間或分組選項，且選項
  清單不是寫死的固定值 —— 測試需使用包含額外等級（例如 `110`）的 fixture，證明該等級會自動出現在
  篩選選項中 ——
  `TreasureMapFilterOptionsTests.testLevelOptionsAreDerivedFromLoadedDataAndIncludeLevelsNotInCurrentFixture`
- **AC-9** `[自動]` 版本篩選勾選多個選項（例如 `6.x` 與 `7.x`）時，清單顯示符合其中任一已勾選版本的藏寶圖（OR）
  —— `TreasureMapFilteringTests.testSelectingMultipleVersionsMatchesAnyOfThem`
- **AC-10** `[自動]` 等級篩選勾選多個選項（例如 `90` 與 `100`）時，清單顯示符合其中任一已勾選等級的藏寶圖（OR）
  —— `TreasureMapFilteringTests.testSelectingMultipleLevelsMatchesAnyOfThem`
- **AC-11** `[自動]` 同時設定版本篩選（`6.x、7.x`）與等級篩選（`90、100`）時，清單只顯示同時符合
  「屬於 6.x 或 7.x」且「等級為 90 或 100」兩個條件的藏寶圖（AND）——
  `TreasureMapFilteringTests.testVersionAndLevelFiltersCombineWithLogicalAnd`
- **AC-12** `[自動]` 版本篩選未勾選任何選項時，清單不因版本條件而縮小範圍（等同該類別不限制結果）
  —— `TreasureMapFilteringTests.testEmptyVersionSelectionDoesNotRestrictResults`
- **AC-13** `[自動]` 等級篩選未勾選任何選項時，清單不因等級條件而縮小範圍（等同該類別不限制結果）
  —— `TreasureMapFilteringTests.testEmptyLevelSelectionDoesNotRestrictResults`
- **AC-14** `[自動]` 篩選徽章的數字等於「已選版本數＋已選等級數」的加總；版本選 2 個、等級選 2 個時，
  數字為 `4` —— `TreasureMapViewModelFilterTests.testFilterBadgeCountEqualsSelectedVersionsPlusSelectedLevels`
- **AC-15** `[人工]` 實機畫面上：未套用任何篩選時不顯示徽章；套用篩選後徽章顯示對應數字；
  點擊「清除全部篩選」後徽章消失。
- **AC-16** `[自動]` 使用者切換版本或等級篩選選項後，即使 filter sheet 尚未關閉，藏寶圖清單已依新選擇更新，
  不需要額外呼叫「套用」動作 ——
  `TreasureMapViewModelFilterTests.testTogglingFilterSelectionUpdatesDisplayedListWithoutSeparateApplyAction`
- **AC-17** `[diff]` filter sheet 的工具列僅包含「清除」（停用條件比照既有 `viewModel.filter.isActive` 的
  寫法）與「完成」（呼叫 `dismiss()`，不呼叫任何套用／確認方法）兩個按鈕，未新增其他 Apply／確認用途的按鈕。
- **AC-18** `[自動]` 點擊 filter sheet 內「清除」（清除全部篩選）後，版本與等級的已選項目全部清空，
  清單恢復為未篩選的完整清單 —— `TreasureMapViewModelFilterTests.testClearAllFiltersEmptiesSelectionsAndRestoresFullList`
- **AC-19** `[人工]` 篩選後清單結果為 0 筆時，畫面顯示文字「找不到符合篩選條件的藏寶圖」與「清除篩選」按鈕，
  且不顯示既有的「尚未載入資料」（`emptyTitle`/`emptyDescription`）或「載入失敗」文案。
- **AC-20** `[自動]` 點擊空結果畫面上的「清除篩選」按鈕後，版本與等級篩選皆清空，清單恢復顯示目前已載入的
  完整藏寶圖集合（測試以 fixture 的實際筆數驗證，不假設固定為 18 筆）——
  `TreasureMapViewModelFilterTests.testClearingFiltersFromEmptyResultStateRestoresFullyLoadedMapSet`
- **AC-21** `[自動]` 執行上述「清除篩選」（無論由空結果畫面或 filter sheet 觸發）不改變使用者目前的排序方向
  （若清除前為升冪，清除後仍為升冪）——
  `TreasureMapViewModelFilterTests.testClearingFiltersPreservesCurrentSortDirection`
- **AC-22** `[人工]` 使用者變更排序方向與／或篩選條件後，離開藏寶圖列表畫面（返回上一頁）再重新進入，
  排序重置為預設降冪、版本與等級篩選皆清空。
- **AC-23** `[人工]` App 完全重新啟動後進入藏寶圖列表畫面，排序與篩選皆為預設狀態（降冪、未篩選），
  不受前一次 session 選擇影響。
- **AC-24** `[diff]` 本次新增的排序／篩選狀態管理，程式碼中未使用 `AppStorage` 或 `UserDefaults`
  儲存排序方向或篩選條件。

---

## 給 DeveloperBot 的實作提示

- 排序／篩選狀態（排序方向、已選版本大版本、已選等級）可放在 `TreasureMapViewModel` 內以
  `@Observable` 屬性管理，但不能假設 SwiftUI 一定會在使用者離開畫面再返回時重新建立
  `TreasureMapListView` 或其 `@State` 持有的 `TreasureMapViewModel`（例如外層若以 `TabView` 或
  已存活的 `NavigationStack` 保留畫面實例，`@State` 的初始值就不會重新套用）。要讓 AC-22
  「離開再進入即重置」成立，需要有明確的重置動作（例如畫面每次出現時透過 `.onAppear` 或 `.task`
  主動重置排序與篩選狀態），不能只依賴型別的預設初始值。
- grade 轉數字、「依已載入資料動態推導大版本篩選選項」（依 expansion 整數部分分組、去重、排序，
  不得寫死清單）、以及「依已載入資料動態推導等級篩選選項」（去重、排序，不得寫死清單），建議各自
  實作為單一、可獨立單元測試的純函式或計算屬性，方便 AC-2 / AC-6 / AC-7 / AC-8 直接針對它們寫
  unit test，不需要透過完整 View 或 ViewModel 流程間接驗證。
- 篩選 OR／AND 組合（AC-9～AC-13）建議實作成一個可獨立測試的純函式（輸入：完整 `[TreasureMap]` ＋
  已選版本集合 ＋ 已選等級集合；輸出：篩選後的 `[TreasureMap]`），避免耦合在 View 的渲染邏輯裡。
- filter sheet 的套用與關閉行為需比照既有 `ItemFilterSheet`（`Views/ItemSearch/ItemSearchView.swift`）：
  勾選／取消勾選即時套用到背後清單（不透過「暫存後按 Apply 才生效」的機制），工具列僅「清除」
  （停用條件比照 `viewModel.filter.isActive` 的既有寫法）與「完成」（純 `dismiss()`，不呼叫任何套用方法）
  兩個按鈕；已套用篩選徽章可參考 `activeFilterCount` 的呈現方式，但版本／等級篩選的資料形狀不同
  （大版本分組 vs. 原始數值），不需要重用 `ItemFilter` 型別本身。
- AC-18（filter sheet 內清除全部篩選）與 AC-20（從空結果畫面清除篩選）建議共用同一個「清除全部篩選」的
  方法，確保兩個入口行為一致，也讓 AC-21（清除後保留排序方向）不需要在兩處分別實作。
- 新增的使用者可見文字（排序控制、篩選入口、篩選摘要、空結果文案、清除篩選按鈕）需依 repo 慣例
  走 `L10n` + 在地化字串資源，不要在 View 內硬編字串（可用 `[diff]` 檢查）。
