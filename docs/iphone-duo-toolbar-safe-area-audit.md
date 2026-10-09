# iPhone Duo 工具列與 safe-area 稽核（任務 7）

日期：2026-10-02。基準：`b8a0613`（PR #70 合併後）。分支：`fix/duo-toolbar-safe-area`。

## 結論與邊界

沒有找到具體的 inset 對稱／快取／重複套用或 screen-edge bar 遮擋缺陷。本項只新增規格與稽核文件，不修改 production、tests、資料或本地化。

參考 Xcode app-resizability 的 safe-area task 與 SwiftUI view／navigation 指引。三個 `ignoresSafeArea()` 皆限於 full-bleed 背景，應保留；工具列由系統管理，沒有需要知道直向工具列邊緣的自訂版面，因此不加入 `toolbarVerticalEdge`。若日後有實際需求，須以 iOS 27.1 availability 隔離 API 並保留 iOS 17 fallback，不得用裝置、寬度或方向猜邊緣。

**這是靜態稽核與 build／unit-test 回歸，不是新的人工 UI 驗證。** 直向工具列位於不同邊緣時的可見性、點擊與視覺結果仍待任務 8；本報告不聲稱這些已通過。

## 可重現搜尋

於 repository root 執行；66 個 app-owned Swift，無 `.m`／`.mm`／`.h` app source。排除第三方套件、DerivedData、generated project。`rg` 零命中回傳 1，不代表執行失敗。

```sh
rg --files EorzeaToolkit -g '*.swift' | wc -l
rg --files EorzeaToolkit -g '*.m' -g '*.mm' -g '*.h'
rg -n 'safeArea|SafeArea|edgesIgnoring|topLayoutGuide|bottomLayoutGuide|UIEdgeInsets|contentInset|adjustedContentInset|scrollIndicatorInsets|layoutMargins|viewRespectsSystemMinimumLayoutMargins|keyboardLayoutGuide|keyboardWill|keyboardFrame|UIKeyboard|toolbarVerticalEdge|verticalBarEdge' EorzeaToolkit -g '*.swift'
rg -n '\.toolbar|ToolbarItem|\.sheet|\.popover|fullScreenCover|confirmationDialog|searchable' EorzeaToolkit -g '*.swift'
rg -n '\.overlay|ZStack|\.offset|\.position' EorzeaToolkit -g '*.swift'
rg -n 'padding|\.frame|\.offset|GeometryReader|geometry\.size|geo\.size' EorzeaToolkit/Views -g '*.swift'
```

### API 命中與處理清單

| 檔案／symbol（相對 Views） | 命中 | 判讀與處理 |
| --- | --- | --- |
| `Home/HomeStyle.swift:67–70` appThemedBackground | background gradient 的 ignoresSafeArea | 背景可全幅；modifier 沒有對 content 呼叫 ignoresSafeArea，不改。 |
| `Home/HomeStyle.swift:72–75` appThemedScrollContent | background gradient 的 ignoresSafeArea | 只隱藏系統 scroll 背景並替換背景，未關閉 scroll inset adjustment，不改。 |
| `TreasureMap/GatheringNodesSheetView.swift:122–158` GatheringNodeMapView | Color.black.ignoresSafeArea | 與內容 VStack 分離，只有黑色背景全幅；close row 與 GeometryReader 留在正常內容區，不改。 |

其餘 safe-area 搜尋類別零命中：safeAreaInsets／safeAreaLayoutGuide、top／bottomLayoutGuide、UIEdgeInsets／additionalSafeAreaInsets、contentInset／adjustedContentInset／scrollIndicatorInsets、layoutMargins／system-minimum override、手動 keyboard frame／observer、safeAreaInset／safeAreaPadding／safeAreaBar、toolbarVerticalEdge／verticalBarEdge、edgesIgnoringSafeArea。

因此沒有儲存 inset、使用祖先／全域 window inset、把左 inset 同時套兩邊、依 inset threshold 或 orientation 猜邊緣的程式路徑。三處 GeometryReader（rotation、採集點 map、寶藏點 crop）僅即時使用本地 `size`，不讀 inset，沒有重複扣除或重新 padding。需要修改的 target API 檔案清單為空；三個正當命中都已分類，沒有未處理項目。

`HomeStyle.appThemedScreen:60–65` 只設 foreground、tint 與 navigation-bar background，不改 safe-area propagation。第六項已確認的 launch／scene generation、無 iPad orientation 限制與無 UIRequiresFullScreen 設定維持不變。

## 工具列與 presentation inventory

下列九個 `.toolbar` 使用系統 ToolbarItem placements，沒有手動算 bar 高度或 leading／trailing inset：

| 檔案（相對 Views） | 控制與位置 |
| --- | --- |
| `FeatureNavigationView.swift:16` | 返回首頁，topBarLeading。 |
| `Home/HomeFeature.swift:85` | 仙人微彩返回首頁，topBarLeading。 |
| `ItemSearch/ItemSearchView.swift:47` | 篩選按鈕，topBarTrailing。 |
| `ItemSearch/ItemSearchView.swift:247` | 篩選 Form 的清除／完成，cancellationAction／confirmationAction。 |
| `MiniCactpot/MiniCactpotView.swift:50` | 重設，topBarTrailing。 |
| `SkillRotation/SkillRotationEditorView.swift:109` | 清空循環，topBarTrailing。 |
| `TreasureMap/TreasureMapListView.swift:62` | 排序與篩選，topBarTrailing。 |
| `TreasureMap/TreasureMapFilterSheet.swift:37` | 清除／完成，cancellationAction／confirmationAction。 |
| `TreasureMap/GatheringNodesSheetView.swift:34` | 採集點 sheet 關閉，topBarTrailing。 |

四個 modal presentation：

| 來源 | 內容與 safe-area 證據 |
| --- | --- |
| `ItemSearchView.swift:79` popover | ItemFilterSheet 的 NavigationStack + Form；compact adaptation 為 sheet，未讀取 presenting window inset。 |
| `TreasureMapListView.swift:117` popover | TreasureMapFilterSheet 的 NavigationStack + Form；相同系統 adaptation，未手動補 inset。 |
| `TreasureMapListView.swift:71` sheet | GatheringNodesSheetView 的 NavigationStack + ScrollView，medium／large detents，使用自身 presentation 環境。 |
| `GatheringNodesSheetView.swift:43` fullScreenCover | map 關閉鈕位於內容 VStack 獨立 row；內容不忽略 safe area，不以 overlay 浮在地圖／資訊上。 |

另外，MiniCactpot 的 confirmationDialog 與 ItemSearch 的 searchable 使用系統 presentation／keyboard 處理，沒有鍵盤通知或自算避讓。這不等於本項已跑過鍵盤 UI 驗證。

## Overlay／ZStack 完整分類

14 個 view 檔案均已檢查。這些是局部元件 composition，不是需要改成 safeAreaInset 的 screen-edge bar；不把正常 artwork／scrim／badge 當成缺陷。

| 檔案（相對 Views） | 判讀 |
| --- | --- |
| `Home/HomeFeatureCard.swift` | 卡片深度、邊框與圖片邊框；2pt offset 是陰影層。 |
| `Home/HomeHeroBanner.swift` | artwork 與裝飾框，限制在 banner 容器。 |
| `Home/HomeStyle.swift` | 純背景與卡片邊框，忽略安全區的範圍如上表。 |
| `Home/HomeView.swift` | 首頁內容容器的背景框。 |
| `ItemSearch/ItemIconView.swift` | icon placeholder。 |
| `ItemSearch/ItemSearchView.swift` | filter badge、134 行的 1pt separator、194 行的 List 內載入提示；filter summary 本身是 VStack child，會保留高度。 |
| `MiniCactpot/MiniCactpotArrowView.swift` | 箭頭選取樣式。 |
| `MiniCactpot/MiniCactpotCellView.swift` | 棋盤格內容與 stroke。 |
| `RelicWeapon/RelicWeaponListView.swift` | 系列 badge stroke。 |
| `SkillRotation/BattleJobListView.swift` | 職業圖示 stroke／placeholder。 |
| `SkillRotation/SkillRotationEditorView.swift` | divider、chip／icon stroke；RotationSlotView 的刪除鈕是格內控制，不是 screen bar。 |
| `TreasureMap/GatheringNodesSheetView.swift` | divider、全螢幕背景／正常內容層、地圖與座標 marker；marker 位置是媒體投影。 |
| `TreasureMap/TreasureMapListView.swift` | toolbar filter badge、row badge／stroke。 |
| `TreasureMap/TreasureSpotListView.swift` | 卡片 artwork、資訊與 map marker 的刻意媒體疊層；offset 是地圖裁切，不是避讓安全區。 |

擴大搜尋另命中 `SkillRotationViewModel`／`SkillRotationSlotRecord` 的 position 及 `TreasureMapFilter` 的 offset，皆為資料順序／enumeration，非畫面幾何。

### Padding 與常數

已檢查 view 的 padding／frame／offset 周邊：44pt 用於圖示／控制尺寸，`RecipeSection.swift:58` 的 leading 44 是 32pt ingredient icon + 12pt spacing 的分隔線對齊；`ItemSearchView.swift:209` 的 88pt 是 scaled option minimum width。首頁與卡片的 18／20／24／32pt 等為內容 margin，不是 status bar 或 home indicator 的替代值。未發現手動 bar-height offset，故不機械替換為 safeAreaPadding。

#### 逐檔／symbol 覆蓋清單（2026-10-09 補齊）

重新執行上述最後一條完整命令得到 **24 個檔案、177 個命中行**（包含 GeometryReader 與 geometry.size；以此完整 pattern 為準）。下表列出每個命中行及所屬 symbol／用途；相同 symbol 內的同類 modifier 合併說明。所有項目均為元件內容配置、局部幾何或 Preview 留白，**沒有一項用來手動補償系統 inset**，所以維持不修改。這項結論僅限本次 safe-area 稽核，不等於對所有固定尺寸的 accessibility 保證。

| 檔案（相對 Views） | 完整命中行 | symbol／用途 |
| --- | --- | --- |
| `Home/HomeFeatureCard.swift` | 8, 9, 14, 23, 38, 40, 41, 46, 47 | `HomeFeatureCard.body`／內容與 artwork：卡片內距、填滿欄寬、最小高度、圖片尺寸；2pt offset 為深度背景。 |
| `Home/HomeHeroBanner.swift` | 18 | `HomeHeroBanner.body`：內層裝飾框縮排 6pt。 |
| `Home/HomeView.swift` | 23, 24, 25, 33, 34, 36, 37, 49, 54 | `HomeView.body`／`header`／`heroBanner`：內容與背景框 margin、720pt 可讀性上限、標題置中及 banner 填滿。 |
| `ItemSearch/GatheringSection.swift` | 140, 173, 174, 222, 288, 289 | `GatheringNodeCard`／`FishingSpotCard`：列間距；`GatheringTraitBadge`／`FishingConditionBadge`：徽章內距。 |
| `ItemSearch/ItemDetailView.swift` | 38, 39 | `ItemDetailView.body`：道具標題區填滿與垂直留白。 |
| `ItemSearch/ItemIconView.swift` | 11, 14 | `ItemIconView.body`：依傳入 size 設定圖示框與比例內距。 |
| `ItemSearch/ItemSearchView.swift` | 63, 69, 71, 72, 75, 81, 93, 95, 127, 128, 129, 136, 187, 198, 314, 324, 383, 395, 461, 526, 535, 557, 599 | `filterButton`：圖示、徽章、控制框與 popover ideal size；`loadedContent`／`filterBar`／`searchContent`：容器填滿、摘要 margin、分隔線、載入更多置中與 spinner；`ItemFilterSheet.generalFilterSections`／`advancedFilterSections`、`rarityButton`／`jobButton`／`equipSlotButton`：選項間距及圖示／控制大小；`ItemSearchRow.body`：列間距。 |
| `ItemSearch/MarketPriceSection.swift` | 124, 157, 232, 254 | `MarketPriceSummaryView.body`：摘要列內距；`MarketListingsSection.body`：展開鈕置中；`MarketTransactionRow.body`：品質欄 24pt 與交易列間距。 |
| `ItemSearch/RecipeSection.swift` | 58, 63, 86, 87, 122, 137 | `RecipeCard.body`／`header`：分隔線對齊與徽章內距；`RecipeIngredientRow.body`／`rowContent`：列間距與 32pt 圖示。 |
| `ItemSearch/ShopPurchaseSection.swift` | 19 | `ShopPurchaseSection.body`：商店資訊 section 內垂直留白。 |
| `MiniCactpot/MiniCactpotArrowView.swift` | 11 | `MiniCactpotArrowView.body`：30pt 箭頭控制框。 |
| `MiniCactpot/MiniCactpotBoardView.swift` | 19, 20, 21, 60, 83 | `MiniCactpotBoardView.body`／`boardSlot`：棋盤寬度上限、置中、列 margin、格子填滿；`#Preview`：展示內距。 |
| `MiniCactpot/MiniCactpotCellView.swift` | 42 | `#Preview`：展示內距；不是 runtime 系統邊距補償。 |
| `MiniCactpot/MiniCactpotPayoutTableView.swift` | 17, 28, 32 | `MiniCactpotPayoutTableView.body`：表格文字靠尾端對齊與列間距。 |
| `MiniCactpot/MiniCactpotResultView.swift` | 17 | `MiniCactpotResultView.body`：結果列垂直間距。 |
| `MiniCactpot/MiniCactpotView.swift` | 36 | `MiniCactpotView.body`：棋盤進度文字在 section 內置中。 |
| `RelicWeapon/RelicWeaponDetailView.swift` | 13, 23, 43, 44, 48, 92, 129, 139 | `RelicWeaponStageDisclosureView.body`：展開內容留白、完成控制與等級徽章；`RelicWeaponStageDetailView.body`：材料區缩排；`RelicWeaponMaterialRow.body`：資訊控制尺寸與備註縮排。 |
| `RelicWeapon/RelicWeaponListView.swift` | 107, 109, 122, 144, 145, 233 | `RelicWeaponSeriesRow.body`／`seriesBadge`／`latestBadge`：列填滿、列間距、56pt badge 與徽章 margin；`RelicWeaponSeriesView.trackingSummarySection`：進度摘要留白。 |
| `SkillRotation/BattleJobListView.swift` | 41, 64, 65, 70 | `BattleJobListView.sidebar`：職業圖示、等級徽章內距與列表列間距。 |
| `SkillRotation/SkillRotationEditorView.swift` | 75, 77, 88, 91, 101, 103, 153, 154, 215, 216, 241, 247, 250, 257, 258, 261, 310, 322, 323, 336, 373, 389, 392, 393, 424, 459, 460, 467, 468, 506, 524, 525, 532, 533 | `SkillRotationEditorView.body`：局部 GeometryReader 分配兩區與 divider；`tinctureGrid`／`filterChip`／`rotationPanel`／`rotationGrid`：標題、選項、捲動 anchor、技能格與區域內距；`SkillGridIcon`／`RotationSlotView`：圖示與格內刪除控制；`SkillDetailCard`／`TinctureDetailCard` 的 body／tag：卡片可讀寬度、圖示及徽章內距。 |
| `TreasureMap/GatheringNodesSheetView.swift` | 29, 39, 68, 78, 79, 98, 101, 102, 130, 136, 138, 140, 151, 153, 157, 162, 163, 179, 181, 197, 198, 215, 223, 235 | `GatheringNodesSheetView.body`／`jobSection`／`nodeRow`：sheet 內容內距、控制框與列徽章；`GatheringNodeMapView.body`／`mapViewport`：關閉列、局部 GeometryReader、map/info 分配及方形置中；`informationPanel`／`markerOverlay`／`fallbackMarker`：資訊內距與媒體標記尺寸。 |
| `TreasureMap/TreasureMapFilterSheet.swift` | 70 | `TreasureMapFilterSheet.optionButton`：選項最小高度 44pt。 |
| `TreasureMap/TreasureMapListView.swift` | 100, 106, 108, 109, 113, 119, 148, 150, 163, 185, 187, 201, 202 | `TreasureMapListView.filterButton`：圖示／徽章／控制框與 popover ideal size；`TreasureMapRow.body`／`gradeBadge`／`metadataRow`／`metadataBadge`：列填滿、徽章與採集控制尺寸、局部 margin。 |
| `TreasureMap/TreasureSpotListView.swift` | 20, 49, 50, 74, 90, 100, 101, 115, 116, 129, 130, 145 | `TreasureSpotListView.body`：列表內容內距；`TreasureSpotCard.body`：artwork 與資訊內距、圖示；`CroppedMapView.body`：局部尺寸、裁切 offset 及 marker 尺寸。 |

## 驗證結果

2026-10-02 執行：

```sh
./scripts/generate_project.sh
xcodebuild clean build -project EorzeaToolkit.xcodeproj -scheme EorzeaToolkit -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath DerivedData -disableAutomaticPackageResolution CODE_SIGNING_ALLOWED=NO
./scripts/run_tests.sh
git diff --check
```

- Project generation 與 clean build 成功。AppIntents metadata extraction skipped 是無 AppIntents.framework dependency 的工具 warning，不是編譯失敗。
- iPhone Duo／iOS 27.1：72 passed、0 failed、0 skipped、0 runtime warnings。
- 本機結果：`DerivedData/Logs/Test/Test-EorzeaToolkit-2026.10.02_21-36-29-+0800.xcresult`，不提交產物。
- catalog 無 diff，資料未改，`validate_data.py` 不適用。沒有新 production 行為，所以沿用既有測試，不新增 source-text 掃描式測試。
- 既有 rotation／map layout tests 證明本地尺寸計算，不直接測試系統 safe area 或直向工具列；72 項通過不能取代 UI 證據。

## 驗收對照與後續

- AC-1 PASS：原報告的 padding 逐檔證據不足；2026-10-09 已補齊完整 24 檔／177 命中行與 symbol 分類。唯讀 reviewer 重新執行完整搜尋並逐檔核對，檔名、每個行號及用途全部吻合，原 finding 已解決。
- AC-2 PASS：theme、九處 toolbar、四處 modal、自訂關閉列與局部 overlay 均有靜態證據，無具體 inset 缺陷。
- AC-3 PASS：production diff 為空；無 toolbarVerticalEdge 實際需求，不引入無用 availability 分支。
- AC-4 PASS：iOS 17／Swift 5.9、資料、本地化不變；未宣稱 runtime UI 通過。
- AC-5 PASS：generate／clean build／完整測試成功；自動驗證邊界明列。

任務 8 仍需驗證：Duo 直向 bar 位於 leading／trailing 的工具列可見性與點擊、popover／medium-large sheet 與鍵盤下的捲動操作、全螢幕 map 關閉鍵及資訊是否被遮擋。一般 hit-area／accessibility 重構不在本項完成聲明內。
