# 遺物武器進度改用 SwiftData 儲存

---

## 目標

`RelicWeaponViewModel` 目前把每個「武器系列＋職業」的完成階段進度，各自編碼成一個 UserDefaults key
（`relicWeaponProgress.<seriesID>.<job>`）。本 Phase 把這部分使用者進度資料改用 SwiftData 儲存，
取代手動 JSON 編碼與逐 key 讀寫，但不改變使用者看到的任何畫面行為。

## 範圍（這個 Phase 只做這些）

- 新增一個 SwiftData `@Model` 型別，儲存「武器系列 ID＋職業縮寫＋已完成階段索引」的進度資料，
  取代 `RelicWeaponViewModel` 現有的 `progressByKey: [String: Set<Int>]` 與 UserDefaults 讀寫邏輯。
- App 啟動時建立並注入 SwiftData `ModelContainer`／`ModelContext`，讓 `RelicWeaponViewModel`
  透過它讀寫進度資料。
- `RelicWeaponViewModel` 對外方法（`isStageCompleted(_:for:job:)`、
  `completedStageCount(for:job:)`、`toggleStage(_:for:job:)`、`loadWeapons()`）的名稱、參數與回傳行為
  維持不變；呼叫端（`RelicWeaponListView` 等 View 檔案）不需要因為底層儲存機制改變而修改呼叫方式。
- 因 App 尚未上架，直接捨棄現有 UserDefaults 內的舊進度資料，不需撰寫任何「UserDefaults → SwiftData」
  的資料搬遷／匯入邏輯。

## 不在這個 Phase

- 不把武器目錄資料（`WeaponSeries`／`WeaponStage`／`WeaponMaterial`／`MaterialQuantity`，來源為
  `relic_weapons.json`）搬進 SwiftData；目錄資料仍維持透過 `LocalDataService.load` 讀取 bundled JSON
  的唯讀方式，不受本 Phase 影響。
- 不新增 iCloud／CloudKit 同步能力。
- 不變更遺物武器相關畫面的 UI、文案、互動流程（`RelicWeaponListView`、`RelicWeaponDetailView` 內的
  既有呈現邏輯不因儲存機制改變而調整）。
- 不處理 `SkillRotation` 的持久化（該功能的 SwiftData 遷移由另一份獨立規格處理）。
- 不修改 `project.yml`、target、依賴或 Scheme。若因新增 App／Test Swift 檔案需要更新
  `project.pbxproj`，一律透過執行 `xcodegen generate` 產生，不得手動編輯。

---

## 資料來源

- `EorzeaToolkit/ViewModels/RelicWeaponViewModel.swift`：現有的 UserDefaults 讀寫實作，包含
  `progressStorageKey(for:job:)`（key 格式 `relicWeaponProgress.<seriesID>.<job>`）、
  `loadProgress(for:)`（在 `loadWeapons()` 內對每個系列的每個 `availableJobs` 逐一嘗試讀取一個
  key）、`saveProgress(_:for:job:)`（每次 `toggleStage` 都立即寫入單一 key）。本 Phase 要替換的就是
  這幾個 private 方法內部的儲存機制，對外的 4 個 public 方法簽名不變。
- `EorzeaToolkit/Models/RelicWeapon.swift`：唯讀目錄資料的型別定義（`RelicWeaponData` /
  `WeaponSeries` / `WeaponStage` / `WeaponMaterial` / `MaterialQuantity`），本 Phase 不變更此檔案。
- `EorzeaToolkit/App/EorzeaToolkitApp.swift`：目前只有 `WindowGroup { MainTabView() }`，未持有任何
  `ModelContainer`。**容易搞錯的地方**：若要在這裡加上 `.modelContainer(for:)`，需注意這是全 App
  唯一的 entry point，變更會影響到所有畫面共用的 environment，不是遺物武器專屬的注入點；本 Phase 只
  新增遺物武器進度需要的 model schema，不引入其他功能尚未要求的 model。
- `EorzeaToolkit/Views/RelicWeapon/RelicWeaponListView.swift:27`：目前以
  `@State private var viewModel = RelicWeaponViewModel()` 建立 ViewModel，建構時未傳入任何
  UserDefaults 以外的依賴。**容易搞錯的地方**：`@State` 的初始值在 View `init` 時就會執行，此時
  `@Environment(\.modelContext)` 尚不可用，因此不能直接在 `RelicWeaponViewModel()` 的建構參數預設值
  裡取得 `modelContext`；需要另外設計「View 出現時把 `modelContext` 交給 ViewModel」的注入方式
  （例如在 `.task` 或 `.onAppear` 內呼叫一個新的方法把 context 交給 ViewModel，再進行
  `loadWeapons()`），且這個注入時機必須早於任何 `toggleStage` 呼叫。

---

## 進度儲存

- 儲存的資料單元為「武器系列 ID＋職業縮寫」→「已完成階段索引集合」，與現行 UserDefaults 版本的資料
  粒度相同（不合併成單一大 blob，不拆得比現行更細）。
- `isStageCompleted(_:for:job:)`：查詢指定系列＋職業＋階段是否已完成；查無任何已儲存記錄時視為未完成
  （回傳 `false`），不得拋出例外或造成畫面崩潰。
- `completedStageCount(for:job:)`：回傳指定系列＋職業已完成的階段數量；查無記錄時回傳 `0`。
- `toggleStage(_:for:job:)`：切換指定階段的完成狀態（已完成→未完成，或未完成→已完成），並立即寫入
  SwiftData（不需要額外的「儲存」動作或延遲批次寫入）。
- 不同「系列＋職業」組合的進度彼此獨立；切換其中一組不得影響其他組合已儲存的資料。
- 已完成的階段索引在不同系列、不同職業之間不互相比對或去重——即使兩個系列剛好都有同一個
  `stageIndex` 數值，也視為完全獨立的記錄。

---

## 技術設計與影響範圍

- `EorzeaToolkit/Models/RelicWeapon.swift` 或新檔案：新增一個 SwiftData `@Model` 型別儲存進度資料，
  建議欄位對應「系列 ID（`String`）、職業縮寫（`String`）、已完成階段索引（`[Int]` 或等效集合）」，
  確切型別與是否拆成多筆記錄／單一記錄由實作決定，只要能滿足上方「進度儲存」的行為即可。
- `EorzeaToolkit/App/EorzeaToolkitApp.swift`：新增 `ModelContainer`（scene 層級的
  `.modelContainer(for:)` 或等效設定），schema 只需包含本 Phase 新增的進度 model。
- `EorzeaToolkit/ViewModels/RelicWeaponViewModel.swift`：移除 `userDefaults` 屬性與
  `loadProgress(for:)` / `saveProgress(_:for:job:)` 內的 UserDefaults 呼叫，改為透過注入的
  `ModelContext` 查詢／寫入／更新進度資料；`progressByKey` 這個記憶體內快取是否保留由實作決定，只要
  4 個對外方法的行為不變。
- `EorzeaToolkit/Views/RelicWeapon/RelicWeaponListView.swift`：新增把 `modelContext` 交給
  `viewModel` 的呼叫（例如透過 `@Environment(\.modelContext)` 取得後在 `.task` 內設定），確保
  `loadWeapons()` 執行前 ViewModel 已經能存取 SwiftData。
- 為避免把新 model 與對應測試全部塞進既有檔案而犧牲可維護性，允許依需要新增獨立的 App／Test Swift
  原始檔。新增檔案後需執行 `xcodegen generate` 更新 `project.pbxproj`，產生的 diff 應僅包含新增檔案
  對應的少數 entries（比照 `CLAUDE.md` 所述 XcodeGen 的穩定性慣例），不得手動編輯
  `project.pbxproj`，也不修改 `project.yml`、target、依賴或 Scheme。

---

## 風險、假設與待確認事項

- App 尚未上架，使用者手上沒有需要保留的既有進度資料，因此本 Phase 明確不做資料遷移；若之後（例如
  已上架後）才要做類似遷移，需要另開規格處理，不可沿用本文件的「直接捨棄」假設。
- SwiftData `ModelContainer` 的注入方式（app 層級 `.modelContainer(for:)` vs. 其他方式）由
  DeveloperBot 依 repo 既有 App 進入點慣例決定；若因此需要調整 `EorzeaToolkitApp.swift` 的既有結構
  （目前僅有 `WindowGroup { MainTabView() }`），應在 PR 中說明調整內容。
- 本文件的驗收條件以「行為」描述；若實作時發現條件與 SwiftData 實際 API 或既有 `@Observable`
  架構衝突，依 repo 慣例應回頭修改本節並在 PR 說明修改原因，而非默默改變行為。

---

## 驗收

**這一節在 Codex 開工前就要寫定。** 若實作中發現某條有誤，應回頭修改本節並在 PR 說明改了什麼、為什麼。

驗證途徑：`[自動]` 有 unit test 可證明；`[diff]` 讀 diff 即可確認；`[人工]` 需在真機／模擬器上操作才能確認
（本文件不宣稱可在目前的 Linux 開發環境執行 Xcode 或 Simulator 驗證，`[人工]` 一律由人於 macOS
以 Xcode／Simulator 執行後確認）。以下 `[自動]` 條件所列的測試名稱是實作時必須建立、或必須明確對應的
測試名稱，不是建議命名；可讓一個測試方法涵蓋一條或多條 AC，但每條 `[自動]` 都必須能對應到一個實際
存在的測試方法。

- **AC-1** `[自動]` 呼叫 `toggleStage(_:for:job:)` 把某階段切為完成後，同一系列＋職業＋階段的
  `isStageCompleted(_:for:job:)` 回傳 `true`（測試以 in-memory `ModelContainer` 建立隔離的測試環境）
  —— `RelicWeaponProgressPersistenceTests.testTogglingStageMarksItCompleted`
- **AC-2** `[自動]` 對同一階段再呼叫一次 `toggleStage(_:for:job:)`，`isStageCompleted(_:for:job:)`
  回傳 `false`（切換是反轉行為，不是只會新增記錄）——
  `RelicWeaponProgressPersistenceTests.testTogglingCompletedStageTwiceRevertsToIncomplete`
- **AC-3** `[自動]` 切換系列 A／職業 X 的某階段為完成，不影響系列 B／職業 X 或系列 A／職業 Y 的
  `isStageCompleted` 結果（不同「系列＋職業」組合的進度彼此獨立）——
  `RelicWeaponProgressPersistenceTests.testProgressIsIsolatedPerSeriesAndJobCombination`
- **AC-4** `[自動]` 尚未對某「系列＋職業」組合呼叫過 `toggleStage` 時，`isStageCompleted` 回傳
  `false`、`completedStageCount` 回傳 `0`，不拋出例外 ——
  `RelicWeaponProgressPersistenceTests.testUnsetProgressDefaultsToZeroCompletedStages`
- **AC-5** `[自動]` 對同一「系列＋職業」組合切換多個不同階段為完成後，`completedStageCount` 等於
  目前已完成的階段數量 ——
  `RelicWeaponProgressPersistenceTests.testCompletedStageCountReflectsMultipleCompletedStages`
- **AC-6** `[diff]` `RelicWeaponViewModel.swift` 內不再出現 `UserDefaults` 型別或
  `userDefaults.data(forKey:)` / `userDefaults.set(_:forKey:)` 呼叫。
- **AC-7** `[diff]` `isStageCompleted(_:for:job:)`、`completedStageCount(for:job:)`、
  `toggleStage(_:for:job:)`、`loadWeapons()` 這 4 個方法的名稱與參數簽名與變更前相同；
  `RelicWeaponListView.swift` 及其他呼叫端對這些方法的呼叫方式未變更。
- **AC-8** `[diff]` 本次變更未包含任何讀取舊版 UserDefaults 進度 key（`relicWeaponProgress.` 前綴）
  並寫入 SwiftData 的程式碼。
- **AC-9** `[人工]` 在「發光武器」畫面勾選某階段為完成後，完全重新啟動 App、重新進入同一武器系列與
  職業，該階段仍顯示為已完成。
- **AC-10** `[人工]` 在同一系列切換到不同職業檢視進度時，畫面顯示的完成狀態與進度條會切換為該職業
  自己的進度，不會沿用前一個職業的完成狀態。
- **AC-11** `[人工]` App 首次啟動、尚未對任何系列職業組合勾選過任何階段時，所有系列的進度條顯示
  0% 完成，畫面不出現錯誤訊息或崩潰。
- **AC-12** `[diff]` 若本次實作新增了 App／Test Swift 檔案，`project.pbxproj` 的變更僅包含 XcodeGen
  因新增檔案而產生的必要 file reference、group、target Sources 對應項目；`project.yml`、target、
  依賴與 Scheme 皆未變更，且 `project.pbxproj` 沒有手動編輯痕跡。

---

## 給 DeveloperBot 的實作提示

- `RelicWeaponListView.swift:27` 目前以 `@State private var viewModel = RelicWeaponViewModel()`
  建立 ViewModel，建構時拿不到 `@Environment(\.modelContext)`。建議在 View `body` 內用
  `@Environment(\.modelContext) private var modelContext`取得 context，並在 `.task`（呼叫
  `loadWeapons()` 之前）把它交給 `viewModel`，確保 `loadWeapons()` 執行時 ViewModel 已能存取
  SwiftData；不要嘗試把 `modelContext` 塞進 `@State` 初始值運算式。
- 單元測試建議使用 in-memory 的 `ModelContainer`（`ModelConfiguration(isStoredInMemoryOnly: true)`）
  建立隔離的測試環境，讓 AC-1～AC-5 不依賴實機或模擬器即可驗證。
- `RelicWeaponViewModel` 目前的 4 個對外方法都是同步呼叫（沒有 `async`）；SwiftData 的
  `ModelContext` 操作本身也是同步 API，這個 Phase 不需要引入 `async`/`await` 或改變既有的呼叫方式。
