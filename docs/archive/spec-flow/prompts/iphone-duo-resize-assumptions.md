# iPhone Duo 任務 6：裝置判斷與 resize 稽核

## 目標與範圍

依 `iphone-duo-roadmap.md` 第六項，稽核任務 1–5 是否以當下容器空間決定版面，而不是以裝置型號、全域螢幕或方向推測。檢查尺寸快取、view identity 與 resize 相關狀態重設。

掃描 `EorzeaToolkit` 下全部 app-owned Swift 原始碼；排除套件、DerivedData、產生的專案與資源內容。參考 Xcode app-resizability 的 UIScreen、orientation、idiom 規則與 SwiftUI skill，專案 iOS 17／Swift 5.9 限制優先。只有找到具體缺陷才修改程式；否則留下可重現的稽核紀錄。

## 不在此項

- 任務 7 的非對稱 safe area、直向工具列與 toolbarVerticalEdge API 稽核。
- 任務 8 的新 UI／視覺回歸、自動化或人工全流程重跑。
- 導覽重設產品行為、並行架構、資料格式、部署版本或一般程式風格重構。

## 驗收

- AC-1 [diff] 掃描所有 app-owned Swift，記錄全域 screen、device／idiom、orientation、global window／scene 與自訂裝置 helper 的搜尋命令、patterns、命中分類；零命中亦須記錄。
- AC-2 [diff] 稽核報告逐一列出任務 1–5 的 layout 輸入、狀態所有者、尺寸快取及 resize reset／identity 檢查證據。
- AC-3 [diff] 只修正可指出使用者可見 resize 風險的假設；沒有缺陷時 production diff 為空，不新增只斷言 source text 的掃描式測試。
- AC-4 [diff] 維持 iOS 17／Swift 5.9、資料與儲存格式及本地化；不把任務 7–8 列為本次已完成，也不以靜態稽核聲稱實際 resize UI 全部通過。
- AC-5 [自動] 執行既有完整測試，包含 SkillRotationEditorLayoutTests、GatheringNodeMapLayoutTests、SkillRotationPersistenceTests 與 TreasureMapSortFilterTests；紀錄實際結果及自動覆蓋邊界。若找到需要修正的行為，補上相應可自動化測試。

## 交付與驗證

交付 `docs/iphone-duo-resize-audit.md`。主 agent 執行 project generation、clean build、`./scripts/run_tests.sh`、`git diff --check`；沒有資料變更時資料驗證不適用。唯讀 reviewer 核對檢查覆蓋與驗收結果。
