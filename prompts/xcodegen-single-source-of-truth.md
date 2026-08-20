# XcodeGen 單一 Source of Truth 遷移

---

## 目標

`project.yml` 成為 Xcode 專案唯一的 source of truth：`EorzeaToolkit.xcodeproj` 除了
`Package.resolved`（維持追蹤以鎖定 SwiftPM 相依版本）以外不再被 Repository 追蹤，CI
與本機開發者都在需要時用固定版本的 XcodeGen 現場產生它。新增 Swift／Test 檔案時，貢
獻者（人類或 AI）只需要編輯 `project.yml` 與新增原始檔，不必再產生或提交
`project.pbxproj` 的 diff。

## 範圍（這個 Phase 只做這些）

- 更新 `.gitignore`，讓 `EorzeaToolkit.xcodeproj` 底下除了 `Package.resolved` 以外的
  生成內容（`project.pbxproj`、scheme、`project.xcworkspace` 其餘內容等）都不再被追
  蹤，並將目前已追蹤的這些檔案從 git 索引移除（`git rm --cached`，本機檔案保留）；
  `EorzeaToolkit.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`
  維持追蹤在原路徑。
- 新增一支共用的 project generation script（例如 `scripts/generate_project.sh`），以
  官方 GitHub Release artifact 下載固定版本（2.45.3）的 XcodeGen、驗證 SHA-256、快取
  後執行 `xcodegen generate`；此 script 不得刪除或覆寫 `Package.resolved`。
- 新增可在 macOS Finder 雙擊執行的 `Generate EorzeaToolkit Project.command`，供本機開
  發者一鍵產生專案並用 Xcode 開啟；內部呼叫與 CI 完全相同的共用 script。
- 更新 `.github/workflows/ci.yml`，在任何 `xcodebuild` 指令之前呼叫上述共用 script，
  並評估在 `xcodebuild` 加上 `-disableAutomaticPackageResolution`，讓建置使用
  `Package.resolved` 鎖定的相依版本。
- 更新 `scripts/run_tests.sh`，讓它在獨立執行（不透過 CI 既有流程）時也能自行產生專案。
- 更新 `CLAUDE.md`、`AGENTS.md` 中所有描述「執行 `xcodegen generate` 後 commit
  `project.pbxproj` diff」「byte-stable 是正確重產的證據」的段落，改為「產生的專案除
  `Package.resolved` 外不追蹤、不 commit」的說明。
- 盤點並視需要更新 `docs/openab-developer-workflow.md`、`.codex/agents/acceptance_reviewer.toml`
  中與專案產生流程相關的敘述，使其與新流程一致。
- 記錄「未來升級 XcodeGen 版本必須用獨立 PR、不與功能開發混在一起」這條規則，寫進
  `CLAUDE.md`／`AGENTS.md` 或共用 script 旁的說明，讓後續貢獻者看得到。

## 不在這個 Phase

- 不變更 `project.yml` 本身的 target／package／設定內容。
- 不改動既有已出貨的 spec（例如 `prompts/treasure-map-sort-filter.md`）中提到舊
  `project.pbxproj` 提交流程的段落——那是歷史紀錄，依 `CLAUDE.md`「不回頭補寫既有
  spec」的原則不予修改。
- 不變更 `.github/pull_request_template.md`（目前未提及 `project.pbxproj`，盤點後未發
  現需要配合修改之處；若實作時發現需要更新，屬於超出本 spec 範圍的追加項目，另行確
  認）。
- 不處理 Swift Package 版本鎖定機制的重新設計（見下方風險）；本 Phase 只需要記錄取捨，
  不需要實作額外方案。
- 不變更 CI 對 `Localizable.xcstrings` 的同步檢查邏輯。
- 不引入除了「產生專案」以外的 XcodeGen 相關自動化（例如自動 lint project.yml 的
  schema）。

---

## 現況（調查結果）

- `project.yml`（repo 根目錄，57 行）已經是 target／package／設定的唯一定義來源；
  `EorzeaToolkit.xcodeproj` 由它產生。問題不在「有沒有 source of truth」，而在「產生
  出來的檔案還被當成第二份 source of truth 提交」。
- `EorzeaToolkit.xcodeproj/project.pbxproj`、`project.xcworkspace/xcshareddata/swiftpm/Package.resolved`、
  `xcshareddata/xcschemes/EorzeaToolkit.xcscheme` 目前都在 `git ls-files` 中，是被追蹤
  的檔案。
- 目前 `.gitignore` 對 Xcode 專案的規則是「先忽略、再刻意取消忽略」的寫法，最終效果是
  `project.xcworkspace` 底下只有 `xcshareddata/swiftpm/Package.resolved` 被追蹤——這個
  例外鏈的寫法與本次決定（`Package.resolved` 繼續追蹤）方向一致，可以沿用、不必整段
  重寫。真正的缺口是：目前的規則完全沒有涵蓋 `EorzeaToolkit.xcodeproj/project.pbxproj`
  與 `EorzeaToolkit.xcodeproj/xcshareddata/xcschemes/EorzeaToolkit.xcscheme`，這兩個檔
  案沒有任何 ignore 規則涵蓋，所以目前被追蹤；需要新增規則把它們排除，同時不能連帶把
  既有的 `Package.resolved` 例外鏈弄壞。
- `.github/workflows/ci.yml` 目前直接對已提交的 `EorzeaToolkit.xcodeproj` 執行
  `xcodebuild -list`、`xcodebuild build`、`./scripts/run_tests.sh`，沒有任何
  `xcodegen generate` 步驟，也沒有固定 XcodeGen 版本的機制（沒有 Mintfile／Brewfile／
  版本鎖定檔）。
- `scripts/run_tests.sh` 直接呼叫 `xcodebuild test -project EorzeaToolkit.xcodeproj ...`，
  同樣假設專案檔已經存在。
- `CLAUDE.md:23-30` 與 `AGENTS.md:69-70` 都指示「改 `project.yml` 後執行
  `xcodegen generate`」，並且 `CLAUDE.md:26-30` 明確教導 reviewer 把「小而精準的
  `project.pbxproj` diff」當成正確重產的證據——這一段落是本次遷移後過時、必須改寫的
  核心指示。
- `.codex/agents/acceptance_reviewer.toml:34, 55` 也提到「透過 project.yml／XcodeGen 變
  更專案結構，不可手動編輯產生的 Xcode 專案」，這個原則本身在遷移後仍然成立，但措辭是
  否隱含「要看 pbxproj diff」需要在實作時逐字檢查後再決定是否改寫。
- `docs/openab-developer-workflow.md`、`docs/home-assets.md`、`.github/pull_request_template.md`
  目前完全沒有提到 `project.pbxproj`／`xcodegen`，盤點未發現這幾份文件有明確衝突之處。
- Repository 沒有任何 Mintfile、`.mise.toml`、Brewfile 或其他工具版本鎖定檔，代表「固
  定版本安裝 XcodeGen」需要從零設計安裝機制。

## 開發者流程（Before / After）

**Before**

1. 開發者或 AI 修改 `project.yml`（新增 target／package／設定）或新增 Swift／Test 檔
   案時，本機執行 `xcodegen generate`。
2. 產生的 `project.pbxproj` diff 與原始碼變更一起提交，PR review 依「diff 是否小而精
   準」判斷是否為正確重產。
3. CI 直接對已提交的 `.xcodeproj` 執行 build／test，不重新產生專案。

**After**

1. 開發者或 AI 只編輯 `project.yml` 與新增原始檔；本機若要用 Xcode 開啟專案，雙擊
   `Generate EorzeaToolkit Project.command`，或直接執行共用 script。
2. PR 內不再出現任何 `EorzeaToolkit.xcodeproj/` 底下的變更；review 不再需要判斷 pbxproj
   diff 是否「乾淨」。
3. CI 在 checkout 之後、任何 `xcodebuild` 指令之前，自動安裝固定版本的 XcodeGen 並執
   行 `xcodegen generate`，讓每次 CI run 都用同一份規則現場產生專案。

---

## 技術設計與影響範圍

### 1. 共用 project generation script

新增 `scripts/generate_project.sh`（沿用 repo 現有 `scripts/*.sh` 慣例），行為：

- 若本機快取（見下）內尚未有固定版本、且 checksum 正確的 XcodeGen 執行檔，從官方
  GitHub Release 下載對應版本的 artifact；下載一律用固定 URL 對應固定版本（見第 2
  節），不得用「curl 直接 pipe 進 shell 執行」的安裝方式（例如
  `curl ... | sh`）——下載與驗證、安裝三個步驟要分開，任何一步失敗都要能個別看出是
  下載失敗還是 checksum 不符。
- 下載後立即以寫死在 script／版本檔中的 SHA-256 驗證 artifact，checksum 不符時立即以
  非零 exit code 失敗並印出明確錯誤，不得靜默略過或退回安裝「可取得的版本」。
- 驗證通過後快取到一個 repo 外或 `.gitignore` 排除的本機路徑（例如
  `~/.cache/eorzea-toolkit/xcodegen/<version>/`），下次執行若快取內已有同版本、
  checksum 正確的執行檔就跳過下載，讓重複執行（CI 每次 run、本機多次雙擊）不必每次
  都重新下載。
- 用快取（或剛下載驗證好）的 XcodeGen 執行檔，從 repo 根目錄執行
  `xcodegen generate --spec project.yml`。
- 絕對不刪除、覆寫、或以任何方式觸碰
  `EorzeaToolkit.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`；
  `xcodegen generate` 本身不會動這個檔案，但 script 中任何「清理舊產物」的步驟都必須
  明確排除它。
- 失敗時要有清楚的錯誤訊息並以非零 exit code 結束，讓呼叫端（CI／`run_tests.sh`／
  `.command`）能正確中止。
- CI 步驟與 `Generate EorzeaToolkit Project.command` 都呼叫同一支 script、走同一套下
  載／驗證／快取／生成邏輯，不得各自重複實作或分岔出兩套安裝方式。

### 2. XcodeGen 安裝與版本鎖定方式（已決定）

- 安裝方式：官方 GitHub Release artifact 直接下載，不使用 Homebrew（不安裝
  latest／任何未鎖定版本），不使用 curl pipe shell。
- 第一版固定版本：**XcodeGen 2.45.3**。版本號與對應 artifact 的 SHA-256 checksum 寫
  在 repo 內單一位置（例如 `scripts/generate_project.sh` 開頭的變數，或獨立的
  `scripts/xcodegen.version` 檔案），CI 與 `.command` 都讀這同一個來源，不重複寫。
- 升級規則：未來升級 XcodeGen 版本必須用獨立 PR，只改版本號／checksum 與相關文件，
  不與功能開發或其他改動混在同一個 PR；這條規則要寫進 `CLAUDE.md`／`AGENTS.md`（或
  script 旁的註解），讓後續貢獻者與 AI 都看得到。

### 3. `.gitignore` 與 git 追蹤狀態

沿用現有「先忽略、再取消忽略到 `Package.resolved`」的例外鏈，只新增涵蓋
`project.pbxproj` 與 scheme 檔案的規則，讓整個 `EorzeaToolkit.xcodeproj/` 除了
`Package.resolved` 外都被忽略。建議規則（實作時需用 `git check-ignore` / `git ls-files`
驗證實際效果符合預期，gitignore 的例外鏈對規則順序敏感）：

```
# EorzeaToolkit.xcodeproj is generated by XcodeGen (scripts/generate_project.sh).
# Only Package.resolved is tracked, to keep SwiftPM dependency versions locked.
EorzeaToolkit.xcodeproj/*
!EorzeaToolkit.xcodeproj/project.xcworkspace/
EorzeaToolkit.xcodeproj/project.xcworkspace/*
!EorzeaToolkit.xcodeproj/project.xcworkspace/xcshareddata/
EorzeaToolkit.xcodeproj/project.xcworkspace/xcshareddata/*
!EorzeaToolkit.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/
EorzeaToolkit.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/*
!EorzeaToolkit.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
```

- 執行 `git rm --cached EorzeaToolkit.xcodeproj/project.pbxproj` 與
  `git rm --cached EorzeaToolkit.xcodeproj/xcshareddata/xcschemes/EorzeaToolkit.xcscheme`
  （保留工作目錄檔案），**不對整個 `EorzeaToolkit.xcodeproj` 目錄做遞迴 `git rm`**，
  因為 `Package.resolved` 必須留在索引中。
- `.gitignore` 修改與上述 `git rm --cached` 放在同一個 PR、同一批相關 commit 內，避免
  CI 在中間狀態下失敗。
- `EorzeaToolkit.xcodeproj/project.xcworkspace/contents.xcworkspacedata` 目前也沒有被
  現有規則涵蓋、但由上面新規則的 `project.xcworkspace/*` 一併忽略；確認這是預期行為
  （它是 XcodeGen 產物，不需要追蹤）。

### 4. CI (`.github/workflows/ci.yml`)

- 在「Checkout」之後、「List project schemes」之前，新增一個步驟呼叫
  `scripts/generate_project.sh`。
- 其餘步驟（`xcodebuild -list`、`Validate bundled data`、`Build`、`Test`、
  `Verify the string catalog is in sync`）維持原順序與邏輯不變。
- `scripts/run_tests.sh` 若已在其內部呼叫 `generate_project.sh`（見下），CI 的
  「Test」步驟不需要重複呼叫；避免同一個 job 內重複產生專案。
- CI 的 `xcodebuild` 應該使用 `Package.resolved` 鎖定的相依版本，不要每次重新解析。
  實作時評估在 `xcodebuild build`／`xcodebuild test` 加上
  `-disableAutomaticPackageResolution`，並確認這個 flag 在專案目前的 Xcode／SwiftPM
  版本下的實際行為（例如：workspace 沒有先執行過 `-resolvePackageDependencies` 時，
  加上這個 flag 是否會導致找不到套件而建置失敗）；若行為不如預期，退而求其次至少要
  確保 `xcodegen generate` 產生的 workspace 之後，`xcodebuild` 不會忽略已存在的
  `Package.resolved` 重新解析出不同版本。

### 5. `scripts/run_tests.sh`

- 在呼叫 `xcodebuild test` 之前，先呼叫 `scripts/generate_project.sh`，讓這支 script
  在 CI 流程之外（例如開發者或 AI 單獨執行 `./scripts/run_tests.sh`）也能獨立運作，不
  依賴「前面有沒有人先跑過 build」。
- 重複產生專案（CI 的「Build」步驟已產生過一次，「Test」步驟又呼叫一次）在效能上的影
  響需要評估；若太慢，改成 CI 只在最前面產生一次、`run_tests.sh` 偵測到專案已存在且
  未被要求重新產生時跳過——實作時二擇一，依實測結果決定，不在本 spec 預先鎖定。

### 6. `Generate EorzeaToolkit Project.command`

- 放在 repo 根目錄，方便 Finder 雙擊執行；需要用 `chmod +x` 設定可執行權限，並確認
  git 記錄的檔案模式為可執行（`100755`）。
- 內容需要先切換到自己所在的目錄（`cd "$(dirname "$0")"`）以避免使用者從別的目錄雙
  擊時相對路徑錯誤，接著呼叫 `scripts/generate_project.sh`，成功後 `open EorzeaToolkit.xcodeproj`。
- 執行失敗時視窗需保持開啟並顯示錯誤（`.command` 在雙擊執行時預設完成即關閉終端機視
  窗，需要加上等待使用者按鍵的收尾，否則錯誤訊息會一閃而過）。

### 7. 文件更新

- `CLAUDE.md`：改寫第 23–30 行，移除「commit 重新產生的 pbxproj diff」「byte-stable
  是正確重產證據」的敘述，改為說明專案除 `Package.resolved` 外已不追蹤、如何本機產
  生、CI 如何自動產生，並補上「升級 XcodeGen 版本需要獨立 PR」的規則。同時
  檢查「Build and Test Commands」段落（第 13–21 行）——目前直接列出
  `xcodebuild build ...`，在乾淨 clone 上會因為專案不存在而失敗，需要補充「先產生專
  案」的前置說明或指向共用 script。
- `AGENTS.md`：改寫第 69–70 行對應敘述；同時檢查「Project Commands」段落中 Build 指
  令是否也需要同樣的前置說明。
- `.codex/agents/acceptance_reviewer.toml`：第 34、55 行提到的「透過 project.yml／
  XcodeGen 變更、不可手動編輯產生的專案」原則本身不變；實作時需逐字檢查這兩行是否隱
  含「檢查 pbxproj diff」的措辭，若有則一併改寫，若沒有則不需要動。
- `docs/openab-developer-workflow.md`：檢查是否有描述「取得專案／開啟 Xcode」的 on-
  boarding 步驟；若有，需要補上雙擊 `.command` 或執行共用 script 的說明。
- `prompts/treasure-map-sort-filter.md`：不修改（歷史 spec）。
- `.github/pull_request_template.md`：盤點後未發現需要修改之處，不在本 Phase 變更；
  若實作時發現 Commit Hygiene checklist 隱含假設要 commit 專案檔，回報但不擅自變更
  範圍。

### 影響範圍總覽

| 檔案 | 變更類型 |
| --- | --- |
| `.gitignore` | 修改：新增涵蓋 `project.pbxproj`／scheme 的規則，`Package.resolved` 例外鏈沿用並保留 |
| `EorzeaToolkit.xcodeproj/project.pbxproj` | 從 git 索引移除（`git rm --cached`），工作目錄保留 |
| `EorzeaToolkit.xcodeproj/xcshareddata/xcschemes/EorzeaToolkit.xcscheme` | 從 git 索引移除（`git rm --cached`），工作目錄保留 |
| `EorzeaToolkit.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved` | **維持追蹤，不變** |
| `scripts/generate_project.sh` | 新增：下載／驗證 checksum／快取／生成，CI 與 `.command` 共用 |
| `Generate EorzeaToolkit Project.command` | 新增，可執行權限 |
| `.github/workflows/ci.yml` | 修改：新增產生專案步驟，評估 `-disableAutomaticPackageResolution` |
| `scripts/run_tests.sh` | 修改：呼叫共用 script |
| `CLAUDE.md` | 修改：移除舊 pbxproj commit 指示 |
| `AGENTS.md` | 修改：同上 |
| `.codex/agents/acceptance_reviewer.toml` | 視逐字檢查結果決定是否修改 |
| `docs/openab-developer-workflow.md` | 視內容決定是否補充 |

---

## 風險、假設與待確認事項

以下三項已由使用者決定，不再是開放問題：安裝方式（GitHub Release artifact + SHA-256
+ 快取，不用 Homebrew／不用 curl pipe shell）、第一版固定版本（XcodeGen 2.45.3，未來
升級須用獨立 PR）、`Package.resolved` 繼續追蹤在原路徑。以下是仍需要在實作時處理的風
險與假設：

- **【假設】GitHub Release artifact 的下載網址與該版本的官方 SHA-256 需要在實作時查
  證後寫入 repo**：本 spec 不代替 DeveloperBot 去外部網站查證 XcodeGen 2.45.3 release
  的實際下載網址與 checksum；這兩個值必須是從官方 release 頁面/資產取得的真實值，不
  可臆造。
- **【假設】快取路徑選在 repo 外（例如 `~/.cache/...`）**：需要確認 CI runner
  （`macos-15`，GitHub-hosted）每次 job 是預設乾淨環境，即使加了快取邏輯，CI 上大機
  率每次仍是重新下載；快取主要效益在本機重複雙擊 `.command` 時。若之後想讓 CI 也吃到
  快取，需要另外設定 GitHub Actions cache（不在本 Phase 範圍內，先用最簡單的「每次
  run 重新下載＋驗證」滿足 CI 需求）。
- **【假設】`-disableAutomaticPackageResolution` 在目前 Xcode／SwiftPM 版本下對這個
  專案的實際效果如預期**：技術設計第 4 節已列出需要在實作時實測確認的行為；若加上這
  個 flag 導致建置失敗，需要退回不加 flag、只靠「workspace 內已有 Package.resolved」
  這件事本身讓 SwiftPM 傾向沿用鎖定版本，並在 PR 中說明改採哪個方案。
- **【假設】`scripts/run_tests.sh` 可以獨立於 CI 的「Build」步驟重新產生一次專案而不
  造成明顯效能問題**：重複執行 `generate_project.sh` 在有快取的情況下應該很快（跳過
  下載，只重跑 `xcodegen generate`），但仍需要在實作時確認耗時可接受；若太慢，改成
  `run_tests.sh` 偵測到專案已存在且未被要求重新產生時跳過。
- **【假設】`.codex/agents/acceptance_reviewer.toml` 目前的措辭不需要大改**：判斷依
  據不完整（只看到兩行摘要，未讀取上下文完整語意），實作時需要重新確認是否隱含「檢查
  pbxproj diff」的措辭。

---

## 驗收

- **AC-1** `[diff]` `git ls-files` 的輸出中不再包含
  `EorzeaToolkit.xcodeproj/project.pbxproj` 或
  `EorzeaToolkit.xcodeproj/xcshareddata/xcschemes/EorzeaToolkit.xcscheme`。
- **AC-2** `[diff]` `git ls-files` 的輸出中仍包含
  `EorzeaToolkit.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`。
- **AC-3** `[diff]` `.gitignore` 對 `EorzeaToolkit.xcodeproj/` 的規則，只對
  `Package.resolved` 及其必要的父目錄設定例外，其餘內容（`project.pbxproj`、scheme、
  `project.xcworkspace` 其他內容等）都被忽略。
- **AC-4** `[diff]` `scripts/generate_project.sh`（或同等共用 script）內，XcodeGen 版
  本固定為 `2.45.3`，version／checksum 只定義在單一位置。
- **AC-5** `[diff]` 共用 script 下載 XcodeGen artifact 後、執行安裝或使用前，會用寫死
  的 SHA-256 驗證檔案完整性；且 script 中沒有 `curl ... | sh`／`curl ... | bash` 這種
  下載直接 pipe 執行的寫法，也沒有呼叫 `brew install xcodegen`。
- **AC-6** `[人工]` 刻意把本機快取或下載內容替換成錯誤的 artifact（模擬 checksum 不
  符），執行共用 script 會立即以非零 exit code 失敗並印出清楚錯誤，不會略過驗證繼續
  執行 `xcodegen generate`。
- **AC-7** `[diff]` `.github/workflows/ci.yml` 在所有 `xcodebuild` 指令之前，都有一個
  呼叫共用 project generation script 的步驟；`scripts/run_tests.sh` 在呼叫
  `xcodebuild test` 之前也會呼叫同一支 script（不是另外重寫一套安裝邏輯）。
- **AC-8** `[人工]` 在本機把 `EorzeaToolkit.xcodeproj/project.pbxproj` 與 scheme 檔刪
  除（保留 `Package.resolved`）後，直接執行 `./scripts/run_tests.sh`，能自行重新產生
  專案並成功建置、測試，不需要先手動跑任何指令。
- **AC-9** `[人工]` 在乾淨 clone（`project.pbxproj`／scheme 未被追蹤、`Package.resolved`
  存在）上對 `Generate EorzeaToolkit Project.command` 雙擊執行，會產生專案並自動以
  Xcode 開啟，且該次產生不會刪除或改變已存在的 `Package.resolved` 內容。
- **AC-10** `[diff]` `Generate EorzeaToolkit Project.command` 在 git 中的檔案模式為可
  執行（`100755`），且內部呼叫的是與 CI 相同的共用 script，不是另外複製一份安裝邏輯。
- **AC-11** `[人工]` 一個全新的 PR（在本機刪除已忽略的 xcodeproj 產物後、依更新後的
  `CLAUDE.md`/`AGENTS.md` 指示新增一個 Swift 檔案並更新 `project.yml`）產生的 diff 中，
  不包含 `project.pbxproj` 或 scheme 的變更；若該次新增套件相依性導致
  `Package.resolved` 版本變動，`Package.resolved` 的 diff 會正常出現、可被檢視並提交。
- **AC-12** `[diff]` `CLAUDE.md` 與 `AGENTS.md` 中，原本教導「commit 重新產生的
  `project.pbxproj` diff」「byte-stable 是正確重產證據」的段落已被移除或改寫為「除
  `Package.resolved` 外，產生的專案不追蹤、不 commit」的說明，並包含「XcodeGen 版本升
  級須用獨立 PR」的規則。
- **AC-13** `[人工]` 一個實際的 PR 在 GitHub Actions 上完整跑過本次修改後的
  `ci.yml`，從 checkout 到最後一個步驟全部通過，且該次 checkout 對應的 commit 已完成
  AC-1／AC-2（`project.pbxproj`／scheme 未被追蹤、`Package.resolved` 仍在）。

---

## 給 DeveloperBot 的實作提示

- 開工前先去 XcodeGen 官方 GitHub Release 頁面查證 2.45.3 對應 artifact 的真實下載網
  址與官方 SHA-256，寫進 repo；不要臆造或沿用其他版本的 checksum。
- `.gitignore` 只新增針對 `project.pbxproj` 與 scheme 檔案的忽略規則，**不要動到**現
  有讓 `Package.resolved` 保持追蹤的例外鏈；改完用 `git check-ignore -v` 或
  `git status` 實測，確認 `Package.resolved` 仍會被追蹤、其餘產物都被忽略。
- `git rm --cached` 只對 `project.pbxproj` 與 scheme 檔案執行，不要對整個
  `EorzeaToolkit.xcodeproj` 目錄遞迴執行，否則會連 `Package.resolved` 一起移除索引。
- `.gitignore` 修改、上述 `git rm --cached`、CI 新增產生步驟三者需要放在同一個 PR 內
  完成，避免中間狀態下 CI 找不到專案檔而失敗。
- `scripts/generate_project.sh` 是 CI 步驟、`run_tests.sh`、`.command` 三處共用的唯一
  入口，版本號與 checksum 只能在這一個地方（或它讀取的單一版本檔）定義；不要在三個
  地方各自寫一次。script 內任何清理/覆寫步驟都必須明確跳過 `Package.resolved`。
- 下載邏輯要能清楚分辨三種失敗：網路下載失敗、checksum 不符、`xcodegen generate` 本
  身失敗；三種都要有不同的錯誤訊息，方便除錯。不得用 `curl | sh` 這類寫法。
- `.command` 檔案要考慮「不是從 repo 根目錄雙擊」與「下載/驗證/產生失敗」等情境下，
  終端機視窗要保留可讀的錯誤訊息，不能一閃而過。
- 修改 `CLAUDE.md`/`AGENTS.md` 時，記得一併檢查「Build and Test Commands」/
  「Project Commands」段落中直接寫 `xcodebuild build ...` 的地方，在新流程下是否需要
  補一句「先產生專案」或直接指向共用 script；同時加入「升級 XcodeGen 版本需要獨立
  PR」的規則說明。
- `.codex/agents/acceptance_reviewer.toml` 與 `docs/openab-developer-workflow.md` 需
  要實作時重新讀取完整上下文再決定是否修改，本 spec 的盤點只到摘要程度。
- 依 `CLAUDE.md` 對 `## 驗收` 的規定：若實作中發現某條 AC 本身有誤，直接修改本節並在
  PR 說明改了什麼、為什麼，不要默默做成別的樣子。
