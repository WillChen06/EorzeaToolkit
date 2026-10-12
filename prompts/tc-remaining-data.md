# 剩餘資料改用繁中 datamining（技能、藏寶圖、地區名）

## 目標

技能循環與藏寶圖的名稱、說明改用繁中服官方資料，並由 `build_data.py` 同一套流程產出。
已產出的配方、採集、釣魚資料中寫死的職業與採集方式名稱，也改成讀官方表。

## 範圍（這個 Phase 只做這些）

- `scripts/data_sources.json` 補上需要的繁中檔案：`Action`、`ActionTransient`、`ClassJob`、`BaseParam`、
  `Map`、`GatheringType`。Teamcraft 的 `nodes.json` 已經在清單裡。
- 新增 `scripts/build_battle_actions.py`，產出 `battle_actions.json`：
  - 職業：21 個戰鬥職業（不含青魔道士），依職業 id 排序。名稱、縮寫讀 `ClassJob`。
  - 職業技能依規則從 `Action` 挑選，依（習得等級, id）排序：
    - 屬於該職業或其基本職業；
    - 該技能的可用職業（`ClassJobCategory`）包含該職業；
    - 玩家技能、非 PvP、非共通技能、有習得等級。
  - 規則挑不到、但遊戲裡確實屬於該職業的技能（目前已知：赤魔道士「光芒四射」），寫在產生器的例外清單，並註明原因。
  - 共通技能（`role_actions`）用同一套規則挑出共通技能。App 目前沒有讀它，但照樣產出。
  - 技能說明依等級產出：技能循環可選的 Lv50／60／70／80／90／100 中，已習得的每個等級各一份，以等級為 key 存放。
    每份由產生器轉成純文字：
    - 條件標記依「該職業、該等級」求值，只留下成立的分支；
    - 顏色等格式標記全部移除。
  - 爆發藥：固定 5 個道具 id（目前最高等級的寶藥）。名稱讀 `Item`，屬性名稱讀 `BaseParam`，各屬性對應的職業依職業的主屬性。
  - 移除 `name_cn`、`description_cn`、`category_names`（App 用自己的本地化文字顯示技能類別）。
- 新增 `scripts/build_treasure_maps.py`，產出 `treasure_maps_final.json`：
  - 地圖定義搬到 `scripts/treasure_map_definitions.json`，由產生器讀取。定義包含 id、道具 id、等級、版本、單人或多人、採集類型、採集區域。
    這些是社群整理的資料，部分採集區域客戶端資料推不出來。內容從現有檔案一次搬過去。
  - 地圖名稱讀 `Item`。繁中資料沒有的地圖（目前是 G18）不收。
  - 地區名稱讀 `PlaceName`，只留繁中，移除 `cn`。
  - 採集點從 Teamcraft `nodes.json` 產出，結果要與現有資料一致（AC-10）。
    如果規則無法重現，改把採集點也放進定義檔。
  - 移除 `name_cn`、`name_en`、`name_ja`、`gathering_type_names`。
- 新增 `scripts/build_zh_maps.py`，產出 `zh-maps.json`：`Map` 表每張地圖對應 `PlaceName` 的繁中名稱。沒有名稱的地圖不收。
- `build_recipes.py`、`build_gathering.py`、`build_fishing.py` 不再寫死名稱：
  - 生產職、採集職、漁師讀 `ClassJob`；
  - 採集方式讀 `GatheringType`；
  - 「釣魚」沒有對應的官方表格，維持寫死。
- `data_revision` 改為 2：遊戲版本沒變，但產出內容改變。
- App 的 model 移除對應的 `cn`、`en`、`ja` 欄位。
- 技能循環編輯頁的技能說明，改為顯示目前選擇等級的那一份。
- 刪除沒有程式使用的 `EorzeaToolkit/Resources/Data/treasure_maps.json`。
- `validate_data.py` 加上 AC-1 到 AC-5 的檢查。`BundledDataTests` 加上三個新產出檔的解碼測試。

## 不在這個 Phase

- `relic_weapons.json`：來源是另一份文件（kdocs），不動。
- `maps.json`、`treasures.json`：沒有中文，不納入流程，也不動。
- 每月自動檢查上游的 GitHub Actions（另一份 spec）。
- 除了「依選擇的等級取說明」以外，App 的顯示邏輯不改。
- 共通技能的 UI、規則新挑出的技能的 UI 調整。

---

## 資料來源

### 繁中 `ClassJob.csv` 的表頭錯位

- 第 29 欄之後的欄位名稱與資料錯一格。例：`ClassJob{Parent}` 整欄是 0，真正的值在下一欄；
  `PrimaryStat` 欄裝的是職業序號，真正的主屬性在下一欄。
- 產生器只讀前段沒有錯位的 `#`、`Name`、`Abbreviation`。
- 基本職業（騎士←劍術士、學者／召喚士←秘術師…）與主屬性，由產生器內的對照表提供。
  挑出的職業在對照表裡找不到時，產生器失敗。
- 其他表也可能有同樣問題，每個用到的欄位都要跟現有資料比對（AC-9、AC-10）。

### 技能

- 現有技能清單是怎麼挑的已經查不到。這次以規則重現，規則跟現有清單有差異時，必須列出來（AC-8）。
- 說明的條件標記中，`PlayerParameter(68)` 是職業 id，`PlayerParameter(72)` 是等級。
  共通技能沒有單一職業，條件以「該技能可用職業中 id 最小的職業」求值。
- 說明裡的格式標記只有 `UIForeground`、`UIGlow`（內容是顏色代碼，整段移除）與 `If`／`Else`。
  條件只有「職業等於」與「等級大於等於」兩種；出現其他標記或條件時，產生器失敗，不默默輸出。
- 632 個職業技能中，有 315 個的說明會隨等級改變。例：騎士「暴亂劍」Lv100 威力 170、連擊中 330；Lv70 為 100、260。
- 現有爆發藥的屬性對應有誤：武僧放在靈巧、毒蛇劍士放在力量。依遊戲主屬性，應為武僧＝力量、毒蛇劍士＝靈巧。

### 藏寶圖

- 地圖 G18（7.3）繁中服尚未開放，繁中 `Item.csv` 沒有這個道具。
- 採集區域：G1–G10、G15 原本由 `nodes.json` + `Map.csv` 推得；G11–G14、G16–G18 是社群驗證的資料，客戶端資料推不出來。

---

## 驗收

- **AC-1** `[自動]` `battle_actions.json`、`treasure_maps_final.json`、`zh-maps.json` 的 `_meta` 來源與 `data_sources.json` 一致 —— `validate_data.py`
- **AC-2** `[自動]` 由流程產出的 8 個資料檔都沒有 `cn` 或 `*_cn` 欄位 —— `validate_data.py`
- **AC-3** `[自動]` 每個等級的技能說明都不含任何 `<…>` 標記 —— `validate_data.py`
- **AC-4** `[自動]` 爆發藥的道具 id 都在 `items.json`，且名稱一致 —— `validate_data.py`
- **AC-5** `[自動]` 藏寶圖每張地圖的道具 id 都在 `items.json`，且名稱一致；採集區域與採集點引用的地區都有名稱 —— `validate_data.py`
- **AC-6** `[自動]` 新的資料檔都能被 App model 解碼 —— `BundledDataTests`（新增三個檔案的測試）
- **AC-7** `[diff]` 職業、技能、爆發藥、屬性、藏寶圖、地區、生產職、採集職、採集方式的名稱都讀自繁中表，產生器沒有寫死名稱。「釣魚」除外。
- **AC-8** `[人工]` 每個職業產出的技能 id 集合與目前的 `battle_actions.json` 相同。不同之處逐一列在 PR 內文，由使用者確認。
- **AC-9** `[人工]` 每個技能的習得等級、類別、射程、範圍、詠唱、復唱、可用次數與目前資料相同，用來確認 `Action` 的欄位沒有錯位。不同之處逐一列在 PR 內文。
- **AC-10** `[人工]` 藏寶圖 G1–G17 的等級、版本、類型、採集類型、採集區域、採集點與目前資料相同；G18 不再出現。
- **AC-11** `[人工]` 抽查 5 個技能，名稱與說明跟繁中服遊戲內 Lv100 顯示的一致。
- **AC-12** `[人工]` App 的技能循環、藏寶圖頁顯示繁中官方名稱；既有的 Rotation 紀錄仍能正確顯示。
- **AC-13** `[人工]` 以同一份 `data_sources.json` 連跑兩次，所有產出檔逐 byte 相同。
- **AC-14** `[diff]` `treasure_maps.json` 已刪除；`relic_weapons.json`、`maps.json`、`treasures.json` 沒有變動。
- **AC-15** `[自動]` 每個職業技能，在 Lv50／60／70／80／90／100 中，從習得等級起的每個等級都有說明，習得等級以下的沒有 —— `validate_data.py`
- **AC-16** `[自動]` App 取技能說明時，回傳所選等級的那一份 —— 新增 unit test
- **AC-17** `[人工]` 技能循環編輯頁切換等級時，說明跟著改變。例：騎士「暴亂劍」Lv100 顯示威力 170、連擊中 330；Lv70 顯示 100、260。
