# iPhone Duo 調整任務

依序進行；每項從當時最新的 `main` 建立獨立分支、提出 PR，交由人工合併後再開始下一項。
維持 iOS 17.0、Swift 5.9 與現有本地化／視覺風格。

| 順序 | 任務 | 預定分支 | 範圍 |
| --- | --- | --- | --- |
| 1 | 首頁自適應欄數與 Hero 比例 | `feature/duo-adaptive-home` | 依容器寬度排成 1–3 欄；大字體使用單欄並允許完整換行；Hero 保持既有 3:1 比例，圖片不溢出邊框。 |
| 2 | 寬畫面列表／詳情導覽 | `feature/duo-list-detail` | 逐功能導入可收合的列表／詳情，保留選取項目、搜尋條件與導覽狀態。 |
| 3 | 技能循環雙區版面 | `feature/duo-rotation-layout` | 寬畫面左右排列循環與技能選擇；窄畫面上下排列；保留編輯與排序狀態。 |
| 4 | 篩選器自適應呈現 | `feature/duo-filter-presentation` | 評估 regular width 的錨定 popover，以及 compact width 的 sheet；驗證鍵盤與大字體。 |
| 5 | 地圖與資訊並排 | `feature/duo-map-layout` | 寬畫面並排地圖和資訊，窄畫面保持上下排列；確認座標標記及關閉控制。 |
| 6 | 裝置判斷與 resize 稽核 | `fix/duo-resize-assumptions` | 檢查上述功能是否以容器尺寸、size class 決策，避免以 iPhone／iPad 型號推測空間；無缺陷時記錄檢查結果。 |
| 7 | 直向工具列與 safe area 稽核 | `fix/duo-toolbar-safe-area` | 檢查左右不對稱 safe area、sheet 和自訂控制；僅有實際需要時以 availability 保護 iOS 27.1 的 toolbarVerticalEdge，無缺陷時記錄結果。 |
| 8 | Duo 版面回歸驗證 | `test/duo-layout-coverage` | 補上適當的 UI／視覺驗證，涵蓋窄／寬、折疊切換、大字體、sheet 與導覽狀態。 |

## 任務 1 的設計與驗證

- 網格使用 SwiftUI adaptive columns，最小卡片寬度隨 Dynamic Type 縮放；Accessibility 字級改為單欄。
- 卡片先嘗試圖文並排，文字空間不足時改為圖上文下，避免英文單字被圖示擠壓。
- 首頁內容最大寬度 720pt 並置中，避免展開畫面卡片過寬或欄數過多。
- Hero 使用現有 `HomeArtworkAsset.heroAspectRatio`，在最終容器邊界裁切圖片。
- 保留首頁五個功能的順序與導覽目的地；不變更 orientation、scene 或部署版本。
- 檢查窄手機、一般手機、Duo 展開畫面、大字體與英文文字，並執行專案建置及 `scripts/run_tests.sh`。

參考：Xcode 27.1 內建 `app-resizability` skill；重點是依當下容器空間與 safe area 佈局。僅宣告 iPhone portrait 並不代表 Duo 無法展開，須以實際執行結果判斷。
