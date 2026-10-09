# iPhone Duo 任務 7：直向工具列與 safe area 稽核

## 範圍

依 roadmap 第七項，檢查 app-owned Swift 的非對稱 safe area、工具列、sheet／popover／full-screen cover、自訂控制與背景。參考 Xcode app-resizability safe-area 指引及 SwiftUI skill；專案 iOS 17／Swift 5.9 限制優先。

只有找到具體的遮擋或 inset 假設才修改程式。沒有缺陷時記錄證據，不為了產生 diff 新增 safe-area modifier 或 toolbarVerticalEdge 分支。

## 不在此項

- 任務 8 的實際 Duo UI／視覺回歸與自動化。
- 一般觸控範圍、accessibility、並行架構或樣式重構；本項自訂控制檢查限於 safe-area 位置與 screen-edge bar 遮擋。
- 調整 orientation、部署版本、scene 設定、資料或本地化。

## 驗收

- AC-1 [diff] 保存 app-owned Swift 的 safe-area、manual inset、keyboard、toolbar、presentation、overlay 與 padding 搜尋命令；每個命中以檔案／symbol 分類，零命中類別亦須記錄。
- AC-2 [diff] 逐項檢查 theme modifiers、工具列、modal presentations 與自訂控制；確認忽略 safe area 的範圍限於 full-bleed 背景，沒有內容層忽略、儲存／推算／重複套用 inset、左右對稱假設或 double padding 的程式證據。
- AC-3 [diff] 僅修具體缺陷，無缺陷時 production diff 為空；只有真正需要得知系統直向工具列邊緣時才引入 toolbarVerticalEdge，且須隔離 iOS 27.1 availability、保留 iOS 17 路徑，不得以寬度或方向推測。
- AC-4 [diff] 維持 iOS 17／Swift 5.9、資料格式與本地化；不以靜態稽核宣稱實際 UI 驗證通過，不將任務 8 列為已完成。
- AC-5 [自動] 專案產生、clean build 與既有完整測試通過；若修正新的可測行為則補上對應測試，無 production 變更時不新增 source-text 掃描測試，並記錄 unit test 無法直接證明 safe-area 視覺結果。

## 交付

`docs/iphone-duo-toolbar-safe-area-audit.md`，包含檢查清單、無需修改的原因、驗證結果與 runtime 驗證邊界。資料未改時 `validate_data.py` 不適用。
