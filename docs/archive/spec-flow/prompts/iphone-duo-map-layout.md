# iPhone Duo 任務 5：地圖與資訊並排

## 範圍

只調整 `GatheringNodeMapView` 採集點全螢幕地圖；維持既有選取、fullScreenCover、關閉與座標語意。不修改寶藏點裁切卡片。

## 版面契約

- 使用本地 safe-area 內容尺寸；關閉按鈕獨立佔據頂端一列，最小點擊區 44 × 44。只有背景忽略 safe area。
- 同一組地圖與資訊子樹透過 AnyLayout 切換方向，資訊（標題、類型、座標）始終可捲動。
- 相對 body 字級縮放的最小地圖寬度為 320pt、資訊寬度為 240pt；非 Accessibility 且內容寬度至少兩者相加再加 16pt 間距時並排。
- 並排時資訊寬度為 `(width - 16) × 0.35`，限制在 scaled 最小資訊寬度至其 4/3；地圖取得剩餘寬度。
- 上下時間距為 `min(16, height)`，扣除間距後地圖高度為 `min(width, remainingHeight × 0.65)`，資訊取得剩餘高度。所有尺寸非負且不超過容器。
- 地圖在其區域內以較短邊形成正方形並置中、裁切；標記以該正方形尺寸投影。
- 保留 `(coordinate - 1) × sizeFactor / 100 / 41 × mapSize` 公式；缺少 sizeFactor 時為 100，不 clamp 座標。

## 驗收

- AC-1 [人工] 寬畫面地圖在左、資訊在右；窄畫面及 Accessibility 字級上下排列。
- AC-2 [人工] resize 保留同一採集點、地圖與座標，標記維持對應位置。
- AC-3 [人工] 關閉控制始終可用且不遮擋內容，關閉後返回原採集點列表。
- AC-4 [人工] 矮視窗與繁中／英文 Accessibility 長名稱下，資訊可捲動且地圖不溢出。
- AC-5 [自動] 版面測試涵蓋預設及縮放後臨界寬度、Accessibility 回退、資訊寬度上下限、上下排列寬度與高度限制、零尺寸及尺寸守恆。
- AC-6 [自動] 座標投影測試涵蓋 sizeFactor 100／200、預設 100 及不同 mapSize，維持既有公式。
- AC-7 [diff] 不修改 ViewModel、資料、儲存格式、寶藏點裁切卡片或任務 6–8；維持 iOS 17／Swift 5.9、既有本地化，只有背景忽略 safe area，不引入全域 screen、裝置型號或方向判斷。

## 驗證

執行專案產生、build、`./scripts/run_tests.sh` 與 diff 檢查。沒有資料變更，不需資料驗證。AC-1 至 AC-4 由人工在 Duo 寬／窄／矮視窗、繁中／英文及最大 Accessibility 字級驗證。
