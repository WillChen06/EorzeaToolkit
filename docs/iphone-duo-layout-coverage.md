# Duo 版面回歸驗證

Spec：`prompts/iphone-duo-layout-coverage.md`。基準：main `956a98f`（PR #71），分支 `test/duo-layout-coverage`。

## 重跑自動測試

```sh
xcrun simctl list devices available
bash scripts/run_ui_tests.sh <SIMULATOR_UDID> -resultBundlePath /private/tmp/duo-ui-unique-name.xcresult
./scripts/run_tests.sh
```

- UI runner 要求明確 UDID，不會選另一台裝置來冒充 Duo；結果路徑必須尚不存在。
- Xcode 選 `EorzeaToolkitUI` scheme、目標 simulator，按 Test 也可執行。
- 主 scheme `EorzeaToolkit` 仍只跑 unit tests。UI suite 不在既有 CI 中，PR 必須附本機結果。
- 四個 UI cases：zh-Hant／en × large／AX5。AX case 先量測一般字級第一張卡高度，再重啟以最大 Accessibility 字級量測，斷言高度增加。**重啟不等於 live resize／fold**。
- 測試以正式首頁開始，只改記憶體內藏寶圖篩選；不清空資料、不測寫入持久狀態的循環／武器動作。
- G1、版本 2、Lv40 為 bundled fixture；詳情停在地區列表，不等待遠端圖片。
- 每個 case 的 `.xcresult` 包含語系、字級、實際畫面 pt 尺寸、步驟的 screenshot 附件，裝置／runtime 由 result bundle destination 記錄。附件可以在 Xcode Report Navigator 開啟。
- 成功截圖不代表像素正確；下列人工判讀不可省略。自動斷言驗證的是元素可找到／可操作、字級確實放大、篩選選取值與目的頁。

## 回歸基準紀錄（commit a622da1）

日期：2026-10-09。Xcode 27.1 beta。

| 項目 | Destination／證據 | 結果 |
| --- | --- | --- |
| App build／啟動 | iPhone Duo 27.1，XcodeBuildMCP build & run | PASS（實作前基準，不代替最終 build） |
| 一般 iPhone UI suite | iPhone 18 Pro 27.0，`23EB5EF3-2834-453A-B0B2-73B30FAC2ADD`；`/private/tmp/duo-ui-phone-20261009-reviewed.xcresult` | PASS，4/4，402×874pt；含五卡目的頁／compact 模式斷言 |
| Duo UI suite | iPhone Duo 27.1，`FDA2AA75-215C-4CF1-831A-F9F2D1EB70E1`；`/private/tmp/duo-ui-duo-20261009-reviewed-r3.xcresult` | PASS，4/4，固定展開 951×669pt；含五卡目的頁／wide 模式斷言，不含 live fold |
| 最終 clean build | `/private/tmp/duo-layout-reviewed-build-20261009.log` | PASS |
| 既有 unit suite | `DerivedData/Logs/Test/Test-EorzeaToolkit-2026.10.09_20-53-47-+0800.xcresult`，iPhone Duo 27.1；`/private/tmp/duo-layout-reviewed-unit-20261009.log` | PASS，72/72 |

UI 最終命令：

```sh
bash scripts/run_ui_tests.sh FDA2AA75-215C-4CF1-831A-F9F2D1EB70E1 -collect-test-diagnostics never -resultBundlePath /private/tmp/duo-ui-duo-20261009-reviewed-r3.xcresult
bash scripts/run_ui_tests.sh 23EB5EF3-2834-453A-B0B2-73B30FAC2ADD -collect-test-diagnostics never -resultBundlePath /private/tmp/duo-ui-phone-20261009-reviewed.xcresult
xcodebuild clean build -project EorzeaToolkit.xcodeproj -scheme EorzeaToolkit -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath DerivedData -disableAutomaticPackageResolution CODE_SIGNING_ALLOWED=NO
./scripts/run_tests.sh
```

兩個 destination 共 8/8 通過，無 skipped tests。`bash -n scripts/run_ui_tests.sh` 通過；缺少 UDID／非 UUID 的參數均以 exit 2 拒絕，未進入生成與建置。
`git diff --check` 通過；最終 build／test 未留下本地化 catalog diff。未更動或重新生成 bundled data，`validate_data.py` 本階段不適用。
最終一般 iPhone 截圖 60 張位於 `/private/tmp/duo-ui-phone-reviewed-attachments/`，Duo 60 張位於 `/private/tmp/duo-ui-duo-reviewed-r3-attachments/`，共 120 張（每 case 15 張）；另外每 case 保存首頁 accessibility hierarchy。
這些本機結果與附件不提交 Git，`/private/tmp` 可能被系統清理，需保留時自行複製 result bundle；上述命令可重建證據。

### 自動化限制

本次 MCP 能取得 Duo 首頁 semantic snapshot，但點藏寶圖後仍停在首頁，不能算成功導航。
`simctl io ... enumerate` 顯示多個螢幕；本次 display 1 截圖為黑畫面，display 3 才是展開的 app。
改用 XCUITest 可操作 Duo；必須以 `app.windows.firstMatch` 截圖及以局部 scroll container 比較 frame。
`XCUIApplication.frame` 在此 runtime 回報 669×951，而實際 window／scroll view 為 951×669；直接對 app 截圖會得到黑畫面。
這是測試端取值／擷取來源問題，沒有在產品加入裝置型號特例。

### 開發中測試修正與視覺發現

- 首輪 `/private/tmp/duo-ui-phone-smoke-20261009.xcresult` 在 G1 detail 斷言失敗。UI hierarchy 證明整列中心的 tap 點中了內嵌「採集點」按鈕、開啟採集點 sheet；改用獨立 grade identifier 點 G1，未修改產品導覽。第二輪四 cases 通過。
- Duo 首輪 `/private/tmp/duo-ui-duo-20261009.xcresult` 四 cases 因比較錯誤的 global app frame 失敗；第二輪 `/private/tmp/duo-ui-duo-20261009-r2.xcresult` 已能導航與選版本，但完整 swipe 跨過 Lv40 後對離屏元素詢問 hittability，runtime 回報 invalid activation point。修正為局部容器尺寸與短距離、可反向的拖曳，離屏時不做 hit-test；未放寬選取／導航斷言。
- Duo 首輪在 failure 後的可選 `simctl diagnose` 收集停留超過兩分鐘，僅終止該診斷子程序讓結果封存；測試失敗紀錄、截圖仍保留。後續本機命令加入 `-collect-test-diagnostics never`，不影響測試斷言與自訂附件，runner 本身未強制這個選項。
- 一般 iPhone 第二輪有 40 個命名 PNG 附件（每 case 10 個），匯出至 `/private/tmp/duo-ui-phone-r2-attachments/`，`manifest.json` 對應步驟與原檔名。
- **視覺問題 V1：**英文 AX5 的篩選 sheet，inline navigation title 顯示 `Filter Tr…`。Clear All Filters／Done 皆完整且自動操作成功，選項可捲動。證據：`en-AX5-filter-reopened-402x874`，匯出檔 `5D3931BB-8838-4D8A-BCC3-0E1160A657CA.png`。這是本次回歸檢查發現的既有視覺限制，並非 identifiers 改動造成；本階段不改 toolbar 設計。AC-8 的「無截斷」不能標 PASS，需使用者決定是否接受系統 inline title 省略，或另修標題／toolbar 佈局。
- 已判讀英文一般首頁與 AX5 技能循環卡：圖左文右、文字完整換行；此抽樣不代表整份人工矩陣已完成。
- Duo 第三輪同樣保留 40 張 PNG（`/private/tmp/duo-ui-duo-r3-attachments/`）；抽樣確認繁中一般 G1 的 sidebar／detail 並存。英文 AX5 popover 也有 V1（`en-AX5-filter-reopened-951x669`，檔 `25BB57D4-E9E9-4394-AC5E-977386528213.png`），沒有因操作通過而忽略省略標題。
- 第一輪 acceptance review 找出兩個斷言缺口：四張卡只有 hittability、未啟動目的頁；詳情測試依 Home 是否可點來接受任一導覽模式，未強制 wide sidebar。已補上五卡逐一 tap／專屬目的頁 Home identifier／回首頁，以及按 window 寬度固定 compact／wide 期待的斷言（wide 強制 sidebar 控制可操作且 G1 detail 存在）。列表入口只讀取既有 SwiftData，不進編輯或追蹤操作；沒有改驗收條件。補強後已在兩個 destination 重跑，8/8 PASS，關閉這兩個自動驗收缺口。
- 補強第一輪 `/private/tmp/duo-ui-duo-20261009-reviewed.xcresult` 四 cases 皆通過五卡導覽與 sidebar 控制可操作斷言，但在 detail List 的 `frame.minX` 比較失敗；`reviewed-r2` 改比較 G1 navigation bar 後也同樣失敗。兩者 accessibility container 皆從 window 的 x=0 起算，不代表右側內容範圍。移除不可靠的幾何比較，保留固定寬度模式、G1 detail／導覽標題、sidebar Home／filter 可操作與重開後篩選值斷言；左右位置由 AC-8 視覺驗收。唯讀複審確認此修正符合 AC-5，未接受 compact 代替 wide。
- 補強後 Duo `reviewed-r3` 4/4 PASS，每 case 15 張命名 PNG，共 60 張，匯出至 `/private/tmp/duo-ui-duo-reviewed-r3-attachments/`。抽樣繁中一般 G1 確認 sidebar/detail 並存（`F95BC29F-AC37-4863-996D-8E182134A70F.png`）；英文 AX5 篩選標題仍有 V1（`38450363-5A06-4652-8CD8-968CC76D8BB3.png`）。
- 補強後一般 iPhone `reviewed` 4/4 PASS；英文 AX5 的最終篩選截圖為 `/private/tmp/duo-ui-phone-reviewed-attachments/39F3F79F-2ABF-4C97-B553-9BD269356C31.png`。V1 與人工矩陣不因自動測試成功而改為 PASS。

## V1 標題修正（2026-10-10，a622da1 之後）

使用者先要求 commit、不 push，再修正標題截斷。回歸基準已提交為 `a622da1`；以下修正獨立提交。2026-10-10 使用者後續授權 push 並建立非草稿 PR；此授權不等同完整人工矩陣通過。
依 spec 的使用者授權例外，將完整標題移到 Form 第一列，使用動態字級、垂直自動增高與 header accessibility trait；沒有更改翻譯、Clear／Done 動作或篩選資料流，也沒有新增裝置寬度特例。
這遵循 app-resizability 的局部容器原則及 SwiftUI Form／Dynamic Type 模式；文字允許換行，不縮小 AX 字級。

- Clean build：`/private/tmp/duo-title-build-20261010.log`，PASS。
- iPhone 18 Pro 27.0、402×874pt：`/private/tmp/duo-title-phone-20261010.xcresult`，4/4 PASS。
- 一般 iPhone 附件：`/private/tmp/duo-title-phone-attachments-20261010/`；每 case 17 PNG，共 68 張。
- 已逐張判讀一般 iPhone 的中英 × large／AX5 × 首次／重開，共 8 張 `filter-title-*`：標題完整、無省略或工具列重疊。英文 AX5 換成三行，保留實際字級。
- iPhone Duo 27.1、951×669pt：`/private/tmp/duo-title-duo-20261010.xcresult`，4/4 PASS；附件 `/private/tmp/duo-title-duo-attachments-20261010/`，共 68 PNG。
- 單元測試：`/private/tmp/duo-title-unit-20261010.log`，72/72 PASS；result：`DerivedData/Logs/Test/Test-EorzeaToolkit-2026.10.10_10-46-29-+0800.xcresult`。
- Duo 的另 8 張 `filter-title-*` 也已逐張判讀，標題完整、無省略或工具列重疊。V1 在這 16 張首次／重開畫面中已修復；兩台完整流程 8/8 PASS、無 skip，共 136 張 PNG。
- `git diff --check` 通過；無 localization catalog／data diff。修正前額外出現的 catalog 僅自動擷取刪除／stale metadata，已先備份至 `/private/tmp/duo-title-preexisting-Localizable-20261009.xcstrings` 再依 repo 規則還原，clean build 未留下額外變動。

英文 AX5 代表證據：一般 iPhone `97AD12DB-F3A2-4AD2-B98C-4A954C471D3E.png`；Duo `582DBED5-5E05-4F34-8D4D-34A0BE7E6897.png`，各位於上述附件目錄。完整首次／重開對照由各目錄的 `manifest.json` 查 `filter-title-opened`／`filter-title-reopened`。

重跑：沿用 UI runner，分別指定兩台 UDID 與新的 `-resultBundlePath`（本輪 `duo-title-phone-20261010.xcresult`／`duo-title-duo-20261010.xcresult`），保留 `-collect-test-diagnostics never`；其餘 build／unit 指令不變。

首次／重開標題的 label 斷言只驗證本地化內容，不能代替視覺判讀。即使 V1 修正通過，AC-8 其他畫面與 AC-9／10 的人工矩陣仍不能直接標 PASS。

## 人工矩陣（完整矩陣尚未人工確認）

每列需記錄：日期、Xcode／runtime、裝置、語系／字級、起始狀態、錄影或截圖路徑、觀察結果。
至少以 zh-Hant、en，各自一般與最大 Accessibility 字級重跑；Duo 應在**同一次 app 執行**中由窄→寬→窄，另驗左右系統工具列位置。
前七項的使用者確認不沿用為本表 PASS。測試失敗時記下具體畫面，不只填「沒問題」。

| ID／AC | 起始狀態與操作 | 預期 | 本次結果 |
| --- | --- | --- | --- |
| M1／AC-8 | Home；窄、寬與 AX，依序捲動檢查五張卡及 Hero | 卡片始終圖左文右、文字完整換行，Hero 比例不變、無溢出；五功能可開啟 | UNVERIFIED |
| M2／AC-9 | 道具列表輸入查詢、選一項；窄→寬→窄並返回列表 | 查詢、篩選與選取詳情不重置；列表／詳情可往返 | UNVERIFIED |
| M3／AC-8/9/10 | 藏寶圖選版本 2 + Lv40、開 G1；折疊切換，再重開篩選 | G1 詳情與篩選值保留；窄 sheet／寬 popover 錨定合適、Done/Clear 可操作 | V1 標題截斷已修復並判讀；live fold／完整矩陣 UNVERIFIED |
| M4／AC-9 | 記下目前技能循環槽與序列，選 level/category，新增技能、排序、切槽，再窄→寬→窄 | 選取與編輯內容保留；新增時編輯區不意外上下／左右跳動；驗完手動恢復測試內容 | UNVERIFIED |
| M5／AC-10 | 道具搜尋鍵盤開啟→開篩選→收合／展開→捲動→關閉 | 鍵盤與 sheet/popover 不遮住需要操作的控制；關閉後搜尋保留 | UNVERIFIED |
| M6／AC-8/10 | 藏寶圖採集點 sheet 開地圖→展開／收合→關閉地圖 | 地圖與資訊依空間並排／上下；標記對齊原座標；close 可點並返回原 sheet | UNVERIFIED |
| M7／AC-10 | 系統工具列分別位於左、右；在列表、篩選、map 重複開關；含 AX | 不對稱 safe area 下文字、toolbar、sheet、自訂 close 不被遮住；背景可延伸但內容不越界 | UNVERIFIED |
| M8／AC-8/9 | 發光武器列表選取詳情、仙人微彩輸入局面；各自窄→寬→窄，回首頁 | 詳情／局面未因 resize 重置，返回入口可操作 | UNVERIFIED |

## 驗收對照

| AC | 證據 | 結果 |
| --- | --- | --- |
| AC-1 | project.yml 專用 scheme；run_ui_tests.sh；主 unit scheme／runner 不變 | PASS |
| AC-2 | DuoLayoutFlowTests 的 Default cases，兩個 destination | PASS |
| AC-3 | Accessibility cases 的高度與目的頁斷言，兩個 destination | PASS |
| AC-4 | 四 cases × 兩個 destination 的 filter reopened 斷言 | PASS |
| AC-5 | 窄版 G1 push/back、Duo 固定寬版 sidebar/detail、filter 保留斷言 | PASS |
| AC-6 | V1 修正後兩份 result bundle 共 136 張命名 screenshot | PASS（擷取證據，不是像素比對） |
| AC-7 | 原 identifiers 限制加使用者授權的 V1 標題呈現例外；無持久寫入／翻譯變更 | PASS（依 spec 明示補充） |
| AC-8 | M1、M3、M6、M8＋截圖判讀；V1 的 16 張標題畫面通過 | UNVERIFIED（V1 已修復，其餘完整矩陣待驗） |
| AC-9 | M2、M3、M4、M8 live resize | UNVERIFIED |
| AC-10 | M3、M5、M6、M7 | UNVERIFIED |
| AC-11 | 最終 clean build、72/72 unit tests | PASS |

回歸基準的唯讀 acceptance review 為 8 PASS、1 FAIL、2 UNVERIFIED。V1 修正後的最終唯讀複審無新增 actionable findings，確認 V1 修復；驗收為 8 PASS、0 FAIL、3 UNVERIFIED。AC-8～10 完整人工矩陣仍阻止第八項整體驗收完成。

參考：[XcodeGen ProjectSpec](https://github.com/yonaskolb/XcodeGen/blob/master/Docs/ProjectSpec.md)（UI target／scheme 配置）；本機 Xcode app-resizability skill（容器尺寸與執行中狀態驗證）。
