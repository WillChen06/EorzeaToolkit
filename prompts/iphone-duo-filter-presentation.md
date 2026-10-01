# iPhone Duo 任務 4：篩選器自適應呈現

## 目標

道具搜尋與藏寶圖篩選在有足夠空間時以錨定 popover 呈現，compact 空間轉為 sheet，並維持搜尋與篩選狀態。

## 範圍

- 每個功能只有一個篩選 presentation，錨定在始終存在的工具列篩選按鈕。
- 道具摘要列是同一篩選器的第二入口，刻意共用工具列錨點；清除後摘要列可以消失，不影響已開啟的篩選器。
- 使用系統 popover 自適應，水平或垂直 compact 時偏好 sheet，不以裝置型號或手動寬窄分支重建呈現內容。
- popover 提供 440×600pt 理想尺寸，不強制固定尺寸；Form 可捲動，保留系統 safe area 與鍵盤調整。
- 道具 Accessibility 字級採單欄選項與 menu picker，選項完整換行；保留一般字級的 segmented picker。
- 已選篩選直接沿用功能 ViewModel，完成只關閉，不新增 Apply 或草稿邏輯。

## 不在這個 Phase

不改資料、搜尋／篩選演算法、排序或持久化；不改採集點 sheet、首頁、技能循環，以及 roadmap 任務 5–8。

## 參考

沿用 Xcode app-resizability skill 與系統 presentationCompactAdaptation；保持 iOS 17、Swift 5.9、既有本地化與視覺風格。

## 驗收

- **AC-1** `[人工]` regular空間道具與藏寶圖篩選從工具列按鈕錨定popover開啟，道具摘要列也開啟同一篩選器。
- **AC-2** `[人工]` compact空間篩選以sheet呈現，完成可關閉並可再次開啟。
- **AC-3** `[人工]` 開啟篩選期間resize不清除已選條件，完成後結果、徽章與藏寶圖排序保持正確。
- **AC-4** `[人工]` 道具搜尋鍵盤顯示時可開關篩選且保留搜尋文字，內容與完成按鈕可操作。
- **AC-5** `[人工]` 最大Accessibility字級中英文篩選內容可捲到末端，選項文字不截斷且完成/清除可用。
- **AC-6** `[人工]` 道具摘要列開啟後清除所有條件，不會因摘要列消失而非預期關閉篩選。
- **AC-7** `[diff]` 每功能僅一個篩選presentation來源，維持既有VM與篩選邏輯，無resize重設。
- **AC-8** `[diff]` iOS17/Swift5.9、既有本地化/風格，不引入全域screen/裝置型號/方向決策；不改採集點sheet與任務5-8。

驗證執行專案生成、Simulator build 與 scripts/run_tests.sh。現有測試為資料／狀態回歸，不視為 UI 驗證；人工項未驗證時明確列出。
