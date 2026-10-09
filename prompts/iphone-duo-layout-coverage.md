# iPhone Duo 第八項：版面回歸驗證

## 目標

提供可重跑的 UI 操作與截圖證據，避免前七項調整日後退化；明確區分自動斷言、視覺判讀與真正的執行中折疊驗證。

## 範圍

- 獨立 UI test target、scheme、指定 simulator 的 runner，不改既有 unit test 入口。
- 使用正式首頁與 bundled 藏寶圖資料，測試中英語系、一般／最大 Accessibility 字級。
- 僅新增穩定 accessibility identifiers；不修改產品版面與資料行為。
- 建立含窄／寬、live fold、編輯狀態、鍵盤、sheet、safe area 的人工回歸矩陣。

## 不在這個 Phase

- 不新增第三方 snapshot framework、不宣稱像素基準比對。
- 不以旋轉、冷啟動或 iPad 替代 Duo live fold 證據。
- 不清除模擬器、不卸載 app、不重設 SwiftData、不寫入技能循環／武器進度。
- 不將 UI tests 加入現有 unit CI；本機獨立執行，PR 附實際結果。

## 資料與方法

- 正式 `treasure_maps_final` 等 bundled data；固定 G1 `timeworn_leather_map`、版本 2、Lv40。
- 不依賴遠端圖片或行情服務。
- 依 Apple app-resizability 指引，尺寸切換驗證以當下容器與狀態為準；前六、七項靜態稽核不能代替 UI 執行證據。
- 本 spec 的 `[自動]` 包含 XCUITest（補充通用範本的 unit/data test 定義）。

## 驗收

- **AC-1** `[diff]` UI 測試有獨立執行入口，既有 app scheme 與 unit runner 的測試範圍不變。
- **AC-2** `[自動]` zh-Hant 與 en 的一般字級首頁，五張卡皆可捲動找到並操作。
- **AC-3** `[自動]` zh-Hant 與 en 的最大 Accessibility 字級首頁，五張卡皆可捲動找到並操作；第一張卡高度大於同語系一般字級的高度。
- **AC-4** `[自動]` 兩語系、兩字級的藏寶圖篩選選取版本 2 與 Lv40 後，關閉重開仍顯示這兩項已選取。
- **AC-5** `[自動]` 篩選後可進入 G1 詳情；compact 返回列表後篩選仍保留，wide 在 sidebar／detail 中篩選仍保留。
- **AC-6** `[自動]` UI 流程保留含語系、字級、畫面尺寸、步驟名稱的 runtime screenshot 附件；截圖不作為像素正確性斷言。
- **AC-7** `[diff]` 新增測試只操作 view-local 篩選，不重設或改寫使用者持久資料；產品修改限非本地化 identifiers，不改 iOS 17、Swift 5.9、本地化與既有行為。
- **AC-8** `[人工]` zh-Hant／en × 一般／最大 AX 的窄、寬畫面，首頁圖左文右，文字無截斷重疊；篩選與詳情控制可操作。
- **AC-9** `[人工]` Duo 執行中窄→寬→窄切換保留搜尋、篩選、選取詳情與循環編輯狀態，新增技能時編輯區塊不隨內容意外上下／左右跳動。
- **AC-10** `[人工]` Duo 左／右側工具列與不對稱 safe area 下，鍵盤、sheet、popover、採集點地圖資訊及關閉控制不被遮住，皆可操作。
- **AC-11** `[自動]` 專案 build 與既有 unit tests 通過。

## 結果規則

在 `docs/iphone-duo-layout-coverage.md` 逐項記錄 PASS／FAIL／UNVERIFIED、實際 destination 與結果檔。
自動化環境阻礙必須保留失敗或未驗證紀錄，不得 skip 後視為 PASS。
未實際執行的人工列維持 UNVERIFIED；不沿用前七項的人工確認作本階段結果。
