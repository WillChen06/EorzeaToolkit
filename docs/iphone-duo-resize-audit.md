# iPhone Duo resize 假設稽核（任務 6）

日期：2026-10-02。基準：`514d48c`（PR #69 合併後）。分支：`fix/duo-resize-assumptions`。

## 結論

沒有發現以裝置型號、全域 screen、orientation 或過期尺寸決定任務 1–5 版面的缺陷；本項只新增規格與稽核文件，沒有 production code、測試、資料或本地化變更。以下是靜態程式證據與既有單元測試結果，**不是新的人工 UI resize 驗證**。

參考 Xcode 27.1 內建 app-resizability skill 的 UIScreen／orientation／idiom 任務、SwiftUI skill 的 view／data flow／navigation 指引，以及 swift-concurrency-pro 的任務生命週期指引。依 roadmap 保留任務 7 的 safe-area／toolbar 深度稽核與任務 8 的實際 UI 回歸。

## 可重現搜尋

在 repository root 執行。範圍為 `EorzeaToolkit` 下 66 個 `.swift`，不含第三方套件、DerivedData、測試 fixtures 或 generated project；沒有 `.m`／`.mm`／`.h` app source。`rg` 零命中會回傳 exit code 1，並非掃描失敗。

```sh
rg --files EorzeaToolkit -g '*.swift' | wc -l
rg --files EorzeaToolkit -g '*.m' -g '*.mm' -g '*.h'
rg -n -i 'UIScreen|mainScreen|UIDevice|userInterfaceIdiom|UI_USER_INTERFACE_IDIOM|UIUserInterfaceIdiom|UITraitCollection|interfaceOrientation|statusBarOrientation|connectedScenes|keyWindow|UIApplication|AppDelegate|SceneDelegate|\.windows\b|is_?pad|isiPad|is_?iphone|is_?phone|deviceIsPad|isiOSAppOnMac|targetEnvironment\(macCatalyst\)|\.portrait\b|\.landscape(Left|Right)?\b|\.phone\b|\.pad\b|\.tv\b|\.carPlay\b|\.mac\b|\.vision\b' EorzeaToolkit -g '*.swift'
rg -n 'window|Window|scene|Scene|orientation|Orientation|SizeClass|\.bounds|\.nativeScale|\.nativeBounds|\.screen' EorzeaToolkit -g '*.swift'
rg -n 'GeometryReader|geometry\.size|geo\.size|horizontalSizeClass|verticalSizeClass|@ScaledMetric|AnyLayout|\.id\(|onChange|onAppear|onGeometryChange|PreferenceKey|lazy var' EorzeaToolkit -g '*.swift'
rg -n '(static|lazy|@State|@AppStorage).*(CGSize|CGRect|width|height|Width|Height|orientation|SizeClass)|\.task\(id:|\.onChange\(of:' EorzeaToolkit -g '*.swift'
rg -n 'resetPresentationState' EorzeaToolkit EorzeaToolkitTests
```

### 搜尋分類與檔案處理清單

- 全域 screen／device／idiom／orientation／global window 與裝置 helper：第三條命令零命中，需修改的 API 檔案清單為空，沒有未處理命中。
- 擴大 window／scene 搜尋只命中 `App/EorzeaToolkitApp.swift:6–7` 的 `Scene`／`WindowGroup`，屬 SwiftUI scene root，不是全域視窗查找。
- Geometry 命中三個 view：`SkillRotationEditorView`、`GatheringNodesSheetView`、`TreasureSpotListView`，全部在 body 內讀取當下局部尺寸；均已檢查，不需修改。
- 沒有 `@State`／`@AppStorage` 的尺寸快取、`lazy var` geometry、`PreferenceKey` 或 `onGeometryChange` 回寫尺寸。`GatheringNodeMapLayout.squareSide(in:)` 是以呼叫參數計算的 static function，不是 static cache。
- `.id`、`.task(id:)`、`onChange`、`onAppear` 命中已逐一分類如下，沒有尺寸／size class 驅動的重設。

## 任務 1–5 決策與狀態證據

以下路徑相對於 `EorzeaToolkit/Views`；行號對應上述基準。

| 任務 | layout 輸入／檔案 | 狀態所有者與 resize 檢查 |
| --- | --- | --- |
| 1 首頁 | `Home/HomeView.swift:5–13`：Dynamic Type、scaled 最小卡片寬度、容器 adaptive grid；`HomeHeroBanner.swift:5–6`：容器內 3:1 aspect ratio。 | `MainTabView.swift:4–5` 持有 market settings／selectedFeature；首頁沒有尺寸快取或尺寸觸發重設。返回首頁是明確使用者操作，非 resize。 |
| 2 列表／詳情 | `FeatureNavigationView.swift:10–38`：單一 NavigationSplitView 由系統收合，不以型號切換兩套 hierarchy。 | ItemSearchView、TreasureMapListView、RelicWeaponListView、BattleJobListView 在功能 root 以 `@State` 持有 VM 與 selection；columnVisibility 是導覽狀態，不是尺寸快取。`.id(selectionID)` 只因選取項目改變而重設 detail。 |
| 3 技能循環 | `SkillRotation/SkillRotationEditorView.swift:75–104`：局部 geometry.size、Dynamic Type、scaled 300pt 傳入 `SkillRotationEditorLayout`；AnyLayout 使用同一組 panels。 | editor root 持有 level／category，功能 root VM 持有 rotation；layout helper 每次以當下輸入計算，不儲存上次尺寸，沒有 layout-mode `.id`。 |
| 4 篩選 | `ItemSearch/ItemSearchView.swift:79–83`、`TreasureMap/TreasureMapListView.swift:117–121`：popover 與系統 compact adaptation；Dynamic Type 調整 picker／adaptive grid。 | presentation flag 在 feature root，query／filter／sort 在 VM；不在 popover/sheet 切換時清除。道具摘要列與 toolbar 開同一 presentation。 |
| 5 地圖 | `TreasureMap/GatheringNodesSheetView.swift:138–182`：局部 geometry.size、scaled 320／240pt、Dynamic Type 傳入 GatheringNodeMapLayout；map square 依分配區域較短邊投影。 | selectedNode 在 sheet parent（第 8 行），AnyLayout 維持同一 map／info 子樹，沒有 resize 清除採集點；投影不快取 mapSize。 |

### 其他命中的判讀

- `TreasureMap/TreasureSpotListView.swift:115–141`：裁切地圖即時讀取 `geo.size`，5 倍裁切與座標換算是既有內容規則，不是硬體尺寸假設；不修改。
- `FeatureNavigationView.swift:35`：`.id(selectionID)` 的 key 是內容選取，不是寬度或方向。
- `SkillRotation/SkillRotationEditorView.swift:259,263,307`：`rotationEnd` 是捲動 anchor，slot ID 是資料 identity；`onChange(rotation.count)` 只在新增技能後捲動，不在 resize 重設。
- `ItemSearch/ItemDetailView.swift:55–70,79–105`：`.id(ObtainSource...)` 是區段 anchor；market load key 是 item ID 與 scope ID；`.task(id: item.id)` 因內容項目變更重載，不依尺寸。
- `RelicWeapon/RelicWeaponListView.swift:200,253–261`：onAppear 僅在既有職業無效時補選，保留有效選取，並非每次出現都重設。
- 功能 root 的資料載入有 hasLoaded/loadState guard：TreasureMapListView:18、RelicWeaponListView:41、BattleJobListView:18、ItemSearchViewModel.loadItems:249。沒有以尺寸作 task ID 或在 resize 重建 VM 的路徑。
- `ViewModels/TreasureMapViewModel.swift:68` 的 `resetPresentationState()` 只有 `TreasureMapSortFilterTests` 呼叫，沒有 production caller。

### 合理固定值

首頁 720pt 是內容寬度上限、split column 280–400pt 是欄寬偏好、技能 pane scaled 300pt 與地圖 scaled 320／240pt 是內容可讀性門檻；popover 440×600 為 ideal size，非強制視窗大小。圖示尺寸、44pt 點擊區、3:1 hero 比例及地圖投影常數也不是裝置判斷，不為了清除數字而改動。

## 專案前置條件

`project.yml` 是 source of truth，已與 generated project 的 Debug／Release 設定交叉確認；沒有額外 app Info.plist 或 xcconfig 覆寫。

- Launch screen generation 已啟用（第 33 行）。
- Scene manifest generation 已啟用（第 31 行），app 使用 SwiftUI WindowGroup；無需新增 SceneDelegate。
- 只有 iPhone portrait 宣告（第 34 行），未宣告 iPad orientation 限制；未發現 source override。
- 沒有 UIRequiresFullScreen；未修改 orientation／scene／full-screen 設定。
- iOS 17.0／Swift 5.9 維持不變。

## 驗證結果與邊界

2026-10-02 主 agent 執行：

```sh
./scripts/generate_project.sh
xcodebuild clean build -project EorzeaToolkit.xcodeproj -scheme EorzeaToolkit -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath DerivedData -disableAutomaticPackageResolution CODE_SIGNING_ALLOWED=NO
./scripts/run_tests.sh
git diff --check
```

- Project generation 與 clean build 成功。只有工具回報的 AppIntents metadata extraction skipped（未依賴 AppIntents.framework），沒有編譯錯誤。
- 完整測試：iPhone Duo／iOS 27.1，72 passed、0 failed、0 skipped、0 runtime warnings。
- 結果 bundle：`DerivedData/Logs/Test/Test-EorzeaToolkit-2026.10.02_10-26-13-+0800.xcresult`（本機證據，不提交產物）。
- `SkillRotationEditorLayoutTests`：6 項，覆蓋寬度門檻、scaled threshold、Accessibility 回退與局部高度守恆。
- `GatheringNodeMapLayoutTests`：7 項，覆蓋門檻、Accessibility、資訊欄限值、零尺寸、尺寸守恆及投影。
- `SkillRotationPersistenceTests`／`TreasureMapSortFilterTests`／`RelicWeaponProgressPersistenceTests`：保護資料排序、filter 與持久化邏輯；不是 UI resize 測試。
- 沒有新增 production 行為，因此沿用既有測試，不新增 source-text 掃描測試。資料未改，`validate_data.py` 不適用；本地化 catalog 無 diff。
- Home、NavigationSplitView、popover/sheet 的實際連續 resize、捲動位置與視覺正確性，不能由以上單元測試證明。本次未做新的人工 UI 驗證；既有任務 1–5 的人工驗證不等同於任務 8 的回歸完成。

## 驗收對照

- AC-1 PASS：完整掃描與零命中／正當命中分類已記錄。
- AC-2 PASS：五項 layout 輸入、state ownership、cache／reset／identity 證據已列出。
- AC-3 PASS：未發現具體 resize 缺陷，production／tests diff 為空。
- AC-4 PASS：版本、資料與本地化未改；任務 7–8 明確保留，未宣稱新的人工 UI 驗證。
- AC-5 PASS：既有 72 項測試全部通過，直接與間接覆蓋邊界已列出。
