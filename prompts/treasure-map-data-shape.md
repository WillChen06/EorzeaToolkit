# 藏寶圖資料改由產生器組好（單一資料檔）

## 目標

藏寶圖頁的地區、點位、地圖圖片與採集點，全部由 `build_data.py` 從已固定版本的上游組好，輸出成畫面需要的形狀。
App 只讀一個資料檔，不在執行時合併多份資料；資料錯誤在產生與驗證時被擋下，而不是在畫面上顯示成「未知地區」。

## 範圍（這個 Phase 只做這些）

- `scripts/data_sources.json` 的繁中 datamining 檔案清單補上 `TreasureHuntRank.csv`、`TreasureSpot.csv`、`Level.csv`。
  `Map.csv`、`PlaceName.csv` 已經在清單裡。
- `scripts/build_treasure_maps.py` 改為產出完整的藏寶圖資料，檔名改為 `treasure_maps.json`，取代 `treasure_maps_final.json`：
  - 每張地圖加上 `zones`：該地圖寶藏點所在的地圖（Map），依 `map_id` 排序。每個地區包含 `map_id`、繁中地名、
    地圖圖片網址、`size_factor`，以及該地區的寶藏點 `spots`。
  - 每個寶藏點包含 `id`（`TreasureSpot` 的 key，例如 `"1.0"`）與地圖座標 `x`、`y`。
  - 每個採集點加上所在地區的繁中名稱、地圖圖片網址與 `size_factor`。
  - 移除頂層的 `zone_names`（名稱已直接放進採集點）。
  - `_meta` 照舊記錄來源與 `unreleased_map_ids`。
- 地名、圖片或 `size_factor` 找不到時，產生器失敗，不輸出 fallback。
- App：
  - 藏寶圖功能只讀 `treasure_maps.json`。
  - model 改為對應新形狀；寶藏點卡片的隊伍人數改讀地圖的人數上限（`max_party_size`）。
  - 移除執行時的合併與查表邏輯，以及只為它存在的 model 與 fallback 文字（`unknownRegion`、`unknownRegionText`）。
- 刪除 `EorzeaToolkit/Resources/Data/treasure_maps_final.json`、`maps.json`、`treasures.json`、`zh-maps.json`
  與 `scripts/build_zh_maps.py`。
- `build_data.py`、`validate_data.py` 等引用檔名的地方改用新檔名；產出檔由八個變成七個。
- `validate_data.py`：加上 AC-1 到 AC-5 的檢查；刪除只針對 `zh-maps.json` 的檢查。
- `BundledDataTests` 與 `TreasureMapProjectionTests` 改用新的資料形狀；刪除只針對已刪檔案的測試。
- `data_revision` 改為 5：遊戲版本沒變，但產出內容改變。
- `AGENTS.md`、`.github/claude-review-guidelines.md` 中的產出檔清單與數量（八個 → 七個），以及「`maps`、`treasures`
  沒有產生器」的說明，改成符合新的狀態。

## 不在這個 Phase

- 藏寶圖功能的 TCA 改寫（`feature/treasure-map-tca`）。本 spec 在它合併進 `main` 之後才實作，
  App 端的改動以那時的 client／catalog 為準。
- 藏寶圖畫面的版面、互動與文案調整。除了隊伍人數改讀地圖的人數上限，畫面顯示的內容不變。
- 採集點的挑選規則（`gathering_nodes` 選哪些點）與 `treasure_map_definitions.json` 的內容。
- 地城判斷：目前沒有任何寶藏點位在地城，不尋找 `dungeon` 旗標的來源，也不在產生器或 App 實作地城排除。
- 遠端資料（`build/remote-data/`）：它只含道具資料，不受影響。
- 繁中服尚未開放的地圖（目前是 G18）的處理方式，維持現狀。

---

## 資料來源

所有資料都來自 `data_sources.json` 已固定的繁中 datamining commit；Teamcraft 只用於採集點，與現在相同。

### 寶藏點的串接

```
TreasureHuntRank   第 N 列 = 一種藏寶圖；ItemName = 藏寶圖道具 id
TreasureSpot       key "N.M" = 第 N 種的第 M 個點；Location → Level id
Level              X、Z = 遊戲內平面座標；Map → Map id
Map                SizeFactor、Offset{X}、Offset{Y}、Id（圖片路徑）、PlaceName
```

- 一張藏寶圖的寶藏點，是 `ItemName` 等於該地圖 `item_id` 的 `TreasureHuntRank` 列底下的所有 `TreasureSpot`。
- `Location` 為 0 的列是佔位（例如 `0.0`），不收。
- `TreasureHuntRank` 有好幾列共用同一個道具（例如第 0、1 列都是 6688）；目前只有其中一列有寶藏點。
- 現有 `treasures.json` 的 26 種道具中，有 9 種不在 17 張地圖裡。新產出只收地圖定義中的地圖，這些點不再出現。

### 座標

- `Level` 的平面座標是 `X` 與 `Z`，不是 `Y`。現有 `treasures.json` 的 `rawCoords` 把 Y、Z 對調存放，容易搞反。
- 地圖座標：`41 / (SizeFactor / 100) × ((原始座標 + Offset) × SizeFactor / 100 + 1024) / 2048 + 1`。
  - 例：`1.0` → Level 4512071（X = 364.934、Z = 60.0566、Map 4，SizeFactor 100、Offset 0）→ (28.8, 22.7)，
    與現有 `treasures.json` 相同。
- 現有座標最多到小數第二位。四捨五入的規則要能重現現有數值（AC-6）；重現不了時，把差異列在 PR 內文。
- 目前用到的地圖 `SizeFactor` 有 95 與 100 兩種，Offset 都是 0；公式仍要套用 Offset。

### 地圖圖片與地名

- 圖片網址由 `Map.Id` 組成：`"f1f1/00"` → `https://xivapi.com/m/f1f1/f1f1.00.jpg`，與現有 `maps.json` 相同。
- 寶藏點地區的地名：`Map.PlaceName` 的繁中名稱，與現在的 `zh-maps.json` 同一個來源。
- 採集點地區的地名：採集點 `zone_id`（PlaceName id）的繁中名稱，與現在的 `zone_names` 同一個來源。

### 檔名

- `treasure_maps.json` 這個檔名曾經用過：`tc-remaining-data` 刪掉了當時沒有程式使用的同名舊檔。新檔與它無關。

### 隊伍人數

- 現有每個寶藏點的 `partySize`，都等於所屬地圖的 `max_party_size`（單人圖 1、多人圖 8），所以點位不再各自存放。

---

## 驗收

- **AC-1** `[自動]` 每張地圖的每個地區都有非空的地名、圖片網址，且 `size_factor` 大於 0 —— `validate_data.py`
- **AC-2** `[自動]` 每張地圖的地區依 `map_id` 遞增排列，且同一張地圖內沒有重複的 `map_id` —— `validate_data.py`
- **AC-3** `[自動]` 每個寶藏點的 `id` 在整個檔案內唯一 —— `validate_data.py`
- **AC-4** `[自動]` 每個地區至少有一個寶藏點 —— `validate_data.py`
- **AC-5** `[自動]` 每個採集點都有非空的地名、圖片網址，且 `size_factor` 大於 0 —— `validate_data.py`
- **AC-6** `[人工]` G1–G17 每張地圖的寶藏點集合（`id`、所在 Map、`x`、`y`）與目前 `treasures.json` 中同道具的點相同。
  以一次性的比對結果列在 PR 內文，不同之處逐一列出。
- **AC-7** `[人工]` 每個用到的地圖，圖片網址與 `size_factor` 和目前 `maps.json` 相同；不同之處逐一列在 PR 內文。
- **AC-8** `[人工]` 每個寶藏點地區的地名與目前 `zh-maps.json` 相同；每個採集點的地名與目前 `zone_names` 相同。
  不同之處逐一列在 PR 內文。
- **AC-9** `[自動]` `treasure_maps.json` 能被 App model 解碼 —— `BundledDataTests`
- **AC-10** `[自動]` 寶藏點卡片的地圖位置會依 `size_factor` 縮放 —— `TreasureMapProjectionTests`（改用新資料）
- **AC-11** `[diff]` `treasure_maps_final.json`、`maps.json`、`treasures.json`、`zh-maps.json`、`build_zh_maps.py` 已刪除，
  程式與腳本中沒有任何地方讀取它們。
- **AC-12** `[diff]` App 的藏寶圖功能只讀取 `treasure_maps.json` 一個資料檔。
- **AC-13** `[diff]` `data_revision` 為 5。
- **AC-14** `[人工]` 以同一份 `data_sources.json` 連跑兩次 `build_data.py`，所有產出檔逐 byte 相同。
- **AC-15** `[人工]` 抽查 G1、G8、G17：詳細頁列出的地區名稱與點數，和改動前的 App 相同。
- **AC-16** `[人工]` 抽查 G1、G8、G17：寶藏點卡片的座標、地圖裁切位置與改動前相同；隊伍人數單人圖顯示 1、多人圖顯示 8。
- **AC-17** `[人工]` 抽查 G6 的採集點：清單的地區名稱、點開後的地圖與標記位置，與改動前相同。
