# 技能循環編排改用 SwiftData 儲存

---

## 目標

`SkillRotationViewModel` 目前把使用者編排的所有職業、所有等級的技能循環，序列化成單一一個巢狀字典
（`[String: [String: [PersistedSlot]]]`）存在一個 UserDefaults key
（`SkillRotation.rotationsByJobId.v2`）裡，每次新增、刪除、排序任何一筆技能／藥草都會把全部職業、
全部等級的資料整包重新編碼寫回。本 Phase 把使用者編排的循環資料改用 SwiftData 儲存，讓每筆記錄可以
獨立讀寫，不再需要整包重寫；同時保留對外行為與 View 呼叫方式不變。

## 範圍（這個 Phase 只做這些）

- 新增 SwiftData `@Model` 型別儲存使用者編排的技能循環資料（職業 id、等級、排序、以及該筆是技能還是
  藥草的參照 id），取代 `SkillRotationViewModel` 現有的 `PersistedSlot` + UserDefaults 讀寫邏輯。
- App 啟動時建立並注入 SwiftData `ModelContainer`／`ModelContext`，讓 `SkillRotationViewModel`
  透過它讀寫循環資料（可與遺物武器進度共用同一個 `ModelContainer`，schema 各自新增對應 model）。
- `SkillRotationViewModel` 對外方法（`load()`、`rotation(for:level:)`、`savedLevels(for:)`、
  `addSkill(_:to:level:)`、`addTincture(_:to:level:)`、`removeSlot(id:from:level:)`、
  `clearRotation(for:level:)`、`moveSlot(in:level:fromID:toIndex:)`）的名稱、參數與回傳行為維持不變；
  呼叫端（`BattleJobListView`、`SkillRotationEditorView`）不需要因為底層儲存機制改變而修改呼叫方式。
- 技能／藥草目錄（`BattleJob`／`BattleAction`／`Tincture`／`TinctureStatJob`，來源為
  `battle_actions.json`）仍維持唯讀 bundled JSON；使用者編排的循環資料以 id 參照目錄項目（比照現行
  `PersistedSlot.actionId` / `PersistedSlot.tinctureId` 的作法），不建立指向目錄的 SwiftData
  `@Relationship`。
- 因 App 尚未上架，直接捨棄現有 UserDefaults 內的舊循環資料（含 `.v2` 格式），不需撰寫任何
  「UserDefaults → SwiftData」的資料搬遷／匯入邏輯。

## 不在這個 Phase

- 不把技能／藥草目錄（`BattleJob`／`BattleAction`／`Tincture`）搬進 SwiftData；目錄資料仍透過
  `LocalDataService.load` 讀取 bundled JSON。
- 不新增 iCloud／CloudKit 同步能力。
- 不變更技能循環編輯器的 UI、文案、互動流程（拖曳排序、長按刪除、Category 篩選等既有互動不因儲存
  機制改變而調整）。
- 不處理 `RelicWeapon` 的持久化（該功能的 SwiftData 遷移由另一份獨立規格處理）。
- 不修改 `project.yml`、target、依賴或 Scheme。若因新增 App／Test Swift 檔案需要更新
  `project.pbxproj`，一律透過執行 `xcodegen generate` 產生，不得手動編輯。

---

## 資料來源

- `EorzeaToolkit/ViewModels/SkillRotationViewModel.swift`：現有的 UserDefaults 讀寫實作。
  `PersistedSlot`（第 3-56 行）是目前的磁碟儲存形狀（`id`、`type`、`actionId`、`tinctureId`），
  `persistRotations()`（第 222-240 行）每次呼叫都會把 `rotationsByJobId` 全部內容（所有 job、所有
  level）重新編碼成一個 payload 寫回單一 UserDefaults key——這是本 Phase 要解決的寫入粒度問題。
  `restoreRotations()`（第 184-220 行）在目錄載入後，用 `actionIndex`／`tinctureIndex` 把
  `PersistedSlot` 還原成含完整 `BattleAction`／`Tincture` 物件的 `RotationSlot`；若某筆記錄參照的
  `actionId`／`tinctureId` 在目前目錄裡已不存在，該筆會被 `compactMap` 悄悄捨棄（第 202-213 行）。
  **容易搞錯的地方**：這個「找不到就捨棄」的行為是既有設計（例如目錄資料更新後某技能被移除），本
  Phase 遷移到 SwiftData 後仍要維持相同行為，不是需要修的 bug。
- `EorzeaToolkit/Models/BattleAction.swift`：`SkillRotationLevel`（`Int` enum，rawValue 為
  50/60/70/80/90/100）、`RotationSlot`（`id: UUID`、`item: RotationItem`）、`RotationItem`
  （`.action(BattleAction)` 或 `.tincture(Tincture)` 的 enum，本身即為目錄物件的容器）。本 Phase 不
  變更此檔案的目錄型別定義。
- `EorzeaToolkit/App/EorzeaToolkitApp.swift`：目前只有 `WindowGroup { MainTabView() }`，未持有任何
  `ModelContainer`。若 [[relic-weapon-progress-swiftdata]] 規格已先合併，本 Phase 應延伸同一個
  `ModelContainer`／schema，新增本 Phase 的 model，而不是另外建立第二個 container。
- `EorzeaToolkit/Views/SkillRotation/BattleJobListView.swift:4`：以
  `@State private var viewModel = SkillRotationViewModel()` 建立 ViewModel，建構時未傳入任何
  UserDefaults 以外的依賴。**容易搞錯的地方**：與遺物武器相同，`@State` 初始值執行時
  `@Environment(\.modelContext)` 尚不可用，需要另外設計「View 出現時把 `modelContext` 交給
  ViewModel」的注入方式，且注入時機必須早於 `.task { viewModel.load() }`（第 70 行）。
- `EorzeaToolkit/Views/SkillRotation/SkillRotationEditorView.swift`：呼叫
  `addSkill`／`addTincture`／`removeSlot`／`clearRotation`／`moveSlot` 等 ViewModel 方法觸發編輯
  （例如第 117、133、137、165、169、335、352 行），這些呼叫點在本 Phase 不需要修改，因為對外方法
  簽名不變。

---

## 循環資料儲存

- 儲存的資料單元至少要能還原「職業 id＋等級＋順序＋每個 slot 是技能還是藥草＋參照的目錄 id」，與
  現行 `PersistedSlot` 的資訊量相同，不得遺失任何欄位。
- `addSkill(_:to:level:)` / `addTincture(_:to:level:)`：把一筆新 slot 加到指定職業＋等級的編排
  「尾端」，並立即寫入 SwiftData（不需要額外的「儲存」動作）。
- `removeSlot(id:from:level:)`：移除指定 slot 後立即寫入 SwiftData；若移除後該職業＋等級的編排變
  空，`savedLevels(for:)` 不再回傳該等級（比照現行 `removeEmptyRotation` 行為）。
- `clearRotation(for:level:)`：清空指定職業＋等級的所有 slot，行為與「逐一移除所有 slot」等價，
  清空後 `savedLevels(for:)` 不再回傳該等級。
- `moveSlot(in:level:fromID:toIndex:)`：改變指定職業＋等級內 slot 的排列順序，並立即寫入
  SwiftData；重新讀取後順序需與最後一次寫入的順序一致。
- 同一職業不同等級的編排彼此獨立；不同職業之間的編排也彼此獨立——變更其中一組不得影響其他組合
  已儲存的資料。
- 同一技能／藥草在同一個編排中可以重複出現多次（例如同一個技能在循環中出現兩次），每次出現各自是
  獨立的 slot，移除或搬移其中一個不影響其他重複出現的 slot。
- 還原編排時，若某筆記錄參照的技能／藥草 id 在目前已載入的目錄資料中找不到，該筆記錄被略過、不出現
  在 `rotation(for:level:)` 的結果中，且不得造成崩潰或錯誤畫面（沿用現行 `restoreRotations` 對缺失
  參照的處理方式）。

---

## 技術設計與影響範圍

- `EorzeaToolkit/Models/BattleAction.swift` 或新檔案：新增 SwiftData `@Model` 型別儲存使用者編排的
  slot 資料，建議欄位對應「職業 id（`Int`）、等級（`Int` 或 `SkillRotationLevel.RawValue`）、slot
  在該編排中的順序、slot 種類（技能／藥草）、參照的 `actionId`／`tinctureId`、slot 自身的
  `UUID`」。確切是拆成多筆記錄（每個 slot 一筆）或其他儲存粒度由實作決定，只要能滿足上方「循環資料
  儲存」的行為即可；不得回退成「整個 `rotationsByJobId` 編碼成一個 blob 存一筆記錄」的作法，否則會
  重現本 Phase 要解決的整包重寫問題。
- `EorzeaToolkit/App/EorzeaToolkitApp.swift`：新增或延伸 `ModelContainer`，schema 納入本 Phase
  新增的 model。
- `EorzeaToolkit/ViewModels/SkillRotationViewModel.swift`：移除 `defaults`／`storageKey`／
  `PersistedSlot`／`loadPersistedRotations`／`persistRotations` 這條 UserDefaults 路徑，改為透過
  注入的 `ModelContext` 查詢／寫入／更新／刪除循環資料；`restoreRotations()` 內「用 `actionIndex`／
  `tinctureIndex` 把參照 id 還原成完整目錄物件、找不到就捨棄」的邏輯需要保留（目錄本身不進
  SwiftData，仍需要這一層還原）。
- `EorzeaToolkit/Views/SkillRotation/BattleJobListView.swift`：新增把 `modelContext` 交給
  `viewModel` 的呼叫（例如透過 `@Environment(\.modelContext)` 取得後在 `.task` 內、呼叫
  `viewModel.load()` 之前設定）。
- 為避免把新 model 與對應測試全部塞進既有檔案而犧牲可維護性，允許依需要新增獨立的 App／Test Swift
  原始檔。新增檔案後需執行 `xcodegen generate` 更新 `project.pbxproj`，產生的 diff 應僅包含新增檔案
  對應的少數 entries，不得手動編輯 `project.pbxproj`，也不修改 `project.yml`、target、依賴或
  Scheme。

---

## 風險、假設與待確認事項

- App 尚未上架，使用者手上沒有需要保留的既有編排資料，因此本 Phase 明確不做資料遷移（含現行的
  `.v2` 格式）；若之後才要做類似遷移，需要另開規格處理。
- 若 [[relic-weapon-progress-swiftdata]] 與本規格由不同 PR 分別實作，兩者對 `ModelContainer` 的
  建立方式需要相容（例如先合併的一方負責建立 container，後合併的一方延伸 schema），避免出現兩個
  獨立 `ModelContainer` 互相覆蓋的情況；實際合併順序與整合方式由 DeveloperBot 依當下 `main` 狀態
  決定，若造成額外調整應在 PR 中說明。
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

- **AC-1** `[自動]` 呼叫 `addSkill(_:to:level:)` 新增一筆技能後，同一職業＋等級的
  `rotation(for:level:)` 包含該筆技能，且能透過 SwiftData 查詢取得對應記錄（測試以 in-memory
  `ModelContainer` 建立隔離的測試環境）——
  `SkillRotationPersistenceTests.testAddingSkillPersistsAndAppearsInRotation`
- **AC-2** `[自動]` 呼叫 `addTincture(_:to:level:)` 新增一筆藥草後，同一職業＋等級的
  `rotation(for:level:)` 包含該筆藥草 ——
  `SkillRotationPersistenceTests.testAddingTincturePersistsAndAppearsInRotation`
- **AC-3** `[自動]` 呼叫 `removeSlot(id:from:level:)` 移除某筆 slot 後，`rotation(for:level:)`
  不再包含該筆，SwiftData 中對應記錄同步移除 ——
  `SkillRotationPersistenceTests.testRemovingSlotDeletesPersistedRecord`
- **AC-4** `[自動]` 呼叫 `moveSlot(in:level:fromID:toIndex:)` 重新排序後，`rotation(for:level:)`
  回傳的順序反映新順序；以新的 `SkillRotationViewModel` 實例重新讀取同一份 SwiftData 資料，順序
  仍與最後一次寫入的順序一致 ——
  `SkillRotationPersistenceTests.testMovingSlotPersistsNewOrderAcrossReload`
- **AC-5** `[自動]` 呼叫 `clearRotation(for:level:)` 清空後，`savedLevels(for:)` 不再包含該等級
  ——
  `SkillRotationPersistenceTests.testClearingRotationRemovesLevelFromSavedLevels`
- **AC-6** `[自動]` 對某職業「等級 50」執行 `clearRotation`，不影響同一職業「等級 60」已儲存的
  `rotation(for:level:)` 內容 ——
  `SkillRotationPersistenceTests.testClearingOneLevelDoesNotAffectAnotherLevelOfSameJob`
- **AC-7** `[自動]` 對職業 A 新增／移除／排序 slot，不影響職業 B 已儲存的 `rotation(for:level:)`
  內容 ——
  `SkillRotationPersistenceTests.testEditingOneJobDoesNotAffectAnotherJob`
- **AC-8** `[自動]` 新增技能與藥草、排序後，以新的 `SkillRotationViewModel` 實例重新讀取同一份
  SwiftData 資料並呼叫 `load()`，`rotation(for:level:)` 回傳的每筆 slot 內容（技能／藥草種類、
  對應的 `BattleAction`／`Tincture` 完整資料）與寫入前一致 ——
  `SkillRotationPersistenceTests.testReloadingRestoresFullRotationContent`
- **AC-9** `[自動]` 若已儲存的某筆記錄所參照的 `actionId`／`tinctureId` 在目前載入的目錄資料中不
  存在，`load()` 還原後該筆記錄不出現在 `rotation(for:level:)` 結果中，且不拋出例外 ——
  `SkillRotationPersistenceTests.testRestoringSkipsRecordsReferencingMissingCatalogEntries`
- **AC-10** `[自動]` 同一技能在同一職業＋等級編排中新增兩次後，`rotation(for:level:)` 回傳兩筆各自
  獨立的 slot（各自有不同 `id`）；移除其中一筆不影響另一筆仍存在於結果中 ——
  `SkillRotationPersistenceTests.testDuplicateSkillEntriesAreIndependentSlots`
- **AC-11** `[diff]` `SkillRotationViewModel.swift` 內不再出現 `UserDefaults` 型別、
  `defaults.data(forKey:)` / `defaults.set(_:forKey:)` 呼叫，也不再有 `storageKey` 常數或
  `PersistedSlot` 這個 UserDefaults 專用的編碼型別。
- **AC-12** `[diff]` `load()`、`rotation(for:level:)`、`savedLevels(for:)`、
  `addSkill(_:to:level:)`、`addTincture(_:to:level:)`、`removeSlot(id:from:level:)`、
  `clearRotation(for:level:)`、`moveSlot(in:level:fromID:toIndex:)` 這 8 個方法的名稱與參數簽名
  與變更前相同；`BattleJobListView.swift`、`SkillRotationEditorView.swift` 對這些方法的呼叫方式
  未變更。
- **AC-13** `[diff]` 本次變更未包含任何讀取舊版 UserDefaults key（`SkillRotation.rotationsByJobId`
  前綴，含 `.v2`）並寫入 SwiftData 的程式碼。
- **AC-14** `[人工]` 在技能循環編輯器新增技能與藥草、拖曳排序、刪除後，完全重新啟動 App、重新進入
  同一職業同一等級的編輯畫面，先前的編排內容與順序仍然存在。
- **AC-15** `[人工]` 同一職業切換不同等級（50/60/70/80/90/100）時，各等級顯示各自獨立編排的內容，
  不會混用其他等級的技能／藥草或順序。
- **AC-16** `[人工]` 清空某職業某等級的所有技能後，職業列表上該職業列（`BattleJobListView`）不再
  顯示該等級的「已儲存等級」標籤。
- **AC-17** `[diff]` 若本次實作新增了 App／Test Swift 檔案，`project.pbxproj` 的變更僅包含 XcodeGen
  因新增檔案而產生的必要 file reference、group、target Sources 對應項目；`project.yml`、target、
  依賴與 Scheme 皆未變更，且 `project.pbxproj` 沒有手動編輯痕跡。

---

## 給 DeveloperBot 的實作提示

- `BattleJobListView.swift:4` 目前以 `@State private var viewModel = SkillRotationViewModel()`
  建立 ViewModel，建構時拿不到 `@Environment(\.modelContext)`。建議在 View `body` 內用
  `@Environment(\.modelContext) private var modelContext` 取得 context，並在 `.task`（呼叫
  `viewModel.load()` 之前）把它交給 `viewModel`；不要嘗試把 `modelContext` 塞進 `@State` 初始值
  運算式。
- 單元測試建議使用 in-memory 的 `ModelContainer`
  （`ModelConfiguration(isStoredInMemoryOnly: true)`）建立隔離的測試環境，讓 AC-1～AC-10 不依賴
  實機或模擬器即可驗證；AC-4／AC-8 需要「以新的 `SkillRotationViewModel` 實例重新讀取同一份
  container」來驗證資料確實落地，而不是只驗證記憶體內的 `rotationsByJobId` 狀態。
- `persistRotations()` 目前每次編輯都整包重寫全部 job／level 的作法是本 Phase 要解決的問題；改成
  SwiftData 後應該讓 `addSkill`／`removeSlot`／`moveSlot` 等方法只新增、刪除、更新受影響的那幾筆
  記錄，不需要在每次編輯時重新走訪全部職業與等級（這點沒有對應的自動化 AC，因為是否重寫全部資料
  屬於效能面的實作細節，但仍是本 Phase 的核心動機，請在設計 model 時留意，不要用「整個
  `rotationsByJobId` 編碼成一個 blob 存一筆記錄」的方式繞過去）。
- `restoreRotations()` 現有「用 `actionIndex`／`tinctureIndex` 查表還原、查不到就 `compactMap`
  捨棄」的邏輯可以整段沿用，只是輸入來源從 `pendingPersistedRotations`（解碼自 UserDefaults）換成
  從 `ModelContext` 查詢出來的記錄。
