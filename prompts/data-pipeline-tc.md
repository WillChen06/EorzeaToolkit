# 資料來源改用繁中 datamining（Phase 1：可重現的資料流程）

## 目標

道具、配方、商店、採集、釣魚資料全部改用繁中服官方資料，並且用一個指令從鎖定版本的來源重新產出。
不再依賴本機手動準備的輸入檔，也不再做簡轉繁。

## 範圍（這個 Phase 只做這些）

- 新增 `scripts/data_sources.json`，以 commit SHA 鎖定兩個上游：
  - `thewakingsands/ffxiv-datamining-tc`（同時記錄該 commit 對應的遊戲版本字串）
  - `ffxiv-teamcraft/ffxiv-teamcraft`
- 新增抓檔腳本：依鎖定的 commit 只下載需要的檔案，放進 gitignore 的快取資料夾。不整包 clone，不用 submodule。
- 新增 `scripts/build_items.py`，產出 `items.json`，包含 Phase 2b 的物品分類、職業分類、裝備部位對照表。
- `build_recipes.py`、`build_item_shop.py`、`build_gathering.py`、`build_fishing.py` 改吃繁中來源：
  - 一律以 CSV 第二列的欄位名稱定位欄位，不用固定 index。
  - 移除 OpenCC。
- 新增 `scripts/build_data.py` 作為單一入口：抓來源 → 跑全部產生器 → 跑 `validate_data.py`。
- 每個產出檔的 `_meta` 記錄來源 repo、commit 與遊戲版本。
- 同一次 build 另外產出遠端用的道具檔與 `manifest.json`，放在 gitignore 的輸出資料夾。遠端道具檔的內容與內建 `items.json` 相同。
- `items.json` 的道具、物品分類、職業分類都移除 `name_cn`；App 對應的 model 與搜尋只用 `name_tw`。
- App 載入道具資料時比較版本，舊資料不得蓋過內建資料：
  - 快取版本不比內建新時，使用內建。
  - 遠端 manifest 版本不比目前使用中的資料（內建，或比內建新的快取）新時，不下載。
- 更新 `AGENTS.md`：Commands 加上 `build_data.py`，刪掉「產生器的輸入不在 repo」的說明。
  `.github/claude-review-guidelines.md` 的同一段說明一併更新。

## 不在這個 Phase

- 每月自動檢查上游並開 PR 的 GitHub Actions：Phase 2，另寫 spec。
- 把遠端檔案上傳到 Cloudflare Worker：維持手動。這個 Phase 只負責產出檔案。
- `relic_weapons.json`、`battle_actions.json`、`maps.json`、`treasure_maps.json`、`treasure_maps_final.json`、`treasures.json`、`zh-maps.json`：不動。
- 把道具說明（Description）放進 `items.json`：留給描述搜尋的 Phase。
- 繁中資料沒有的道具，用其他語系補名稱。

---

## 資料來源

### thewakingsands/ffxiv-datamining-tc

- 用到的檔案：`Item`、`ItemUICategory`、`ClassJobCategory`、`EquipSlotCategory`、`Recipe`、
  `RecipeLevelTable`、`GilShopItem`、`PlaceName`（皆為 `.csv`，位於 repo 根目錄）。
- 三列表頭：第一列是 key，第二列是欄位名，第三列是型別，資料從第四列開始。id 0 是空白列。
- commit 訊息就是客戶端版本（例：`ver 2026.09.14.0000.0000`），大約每月更新一次。
- 有些欄位名稱是空白（例：`Recipe` 第 4 欄），無法用名稱定位。產生器不得依賴這類欄位。
- `ClassJobCategory` 的職業縮寫就是欄位名稱（`ADV`、`GLA`…）。職業清單由值為 `True` 的欄位組成。
- `EquipSlotCategory` 沒有名稱欄位，部位名稱由各欄位的值推導：
  - 產生器只維護「欄位 → 部位名稱」的對照（`MainHand` → 主手…，`FingerL`／`FingerR` 都是戒指）。
  - 值為 `1` 的欄位是裝備的部位，值為 `-1` 的欄位是被占用的部位。
  - 名稱為「裝備部位（無法裝備被占用部位）」，例：13 → 主手（無法裝備副手）。
  - `equip_slots` 只收有道具使用的部位。出現對照表沒有的欄位時，產生器失敗。
- id 0 代表「無」：無物品分類、不限職業、非裝備。對照表不收 id 0。
- `items.json` 只收 `Name` 不為空的道具。

### ffxiv-teamcraft

- `libs/data/src/lib/json/nodes.json`、`fishing-spots.json`、`fish-parameter.json`。
- 這三個檔以國際服為準，會出現繁中資料沒有的道具 id。沿用現行做法，記進 `_meta.unresolved_item_ids`。

### 容易搞錯的地方

- 繁中服版本落後國際服，所以道具數量會變少：繁中 `Item.csv` 有名稱的道具是 45,853 筆，現在內建 49,311 筆。這是預期結果，不是 bug。
- 同一個上游 commit 重新產出時，檔案內容必須逐 byte 相同。不要寫入產出時間、不要依賴 dict 或檔案系統的順序。

## 版本與遠端資料

- `items.json` 的 `_meta.version` 與 `manifest.json` 的 `version` 相同。
- version 格式為 `<遊戲版本>-r<修訂號>`，例：`2026.09.14.0000.0000-r1`，依遊戲版本、再依修訂號排序。
- 修訂號記在 `data_sources.json`。遊戲版本不變、但產生器邏輯改變而輸出不同時，手動加一。
  產出不得依賴既有輸出檔或執行次數，否則同一份來源連跑兩次的結果會不同（AC-13）。
- 無法解析的版本一律視為比內建舊，例如目前遠端的 `2026-05-17-v2`。
- `manifest.json` 沿用現行欄位：`version`、`itemsURL`、`items.sha256`、`items.byteSize`。

---

## 驗收

- **AC-1** `[diff]` `scripts/data_sources.json` 以 commit SHA 鎖定兩個上游，不使用 branch 名稱。
- **AC-2** `[自動]` 每個由流程產出的資料檔，`_meta` 記錄的來源 commit 與 `data_sources.json` 一致 —— `validate_data.py`
- **AC-3** `[自動]` `items.json` 每筆道具都有非空的 `name_tw`，且沒有 `name_cn` —— `validate_data.py`
- **AC-4** `[自動]` `items.json` 中每個道具引用的非 0 分類、職業分類、裝備部位 id，都存在於對應的對照表 —— `validate_data.py`
- **AC-5** `[自動]` 既有的 `validate_data.py` 檢查全部通過（計數、unresolved 清單、`resolvable` 旗標）。
- **AC-6** `[自動]` 新的資料檔都能被 App model 解碼 —— `BundledDataTests`
- **AC-7** `[diff]` 產生器只用 Python 標準函式庫，不再 import `opencc`。
- **AC-8** `[diff]` 產生器以欄位名稱讀 CSV。需要的欄位不存在時，以非 0 結束並指出缺少的欄位名。
- **AC-9** `[自動]` 快取版本比內建舊或無法解析時，載入內建資料 —— 新增 unit test
- **AC-10** `[自動]` 快取版本比內建新時，載入快取 —— 新增 unit test
- **AC-11** `[自動]` 遠端 manifest 版本不比內建新時，不下載遠端道具檔 —— 新增 unit test
- **AC-12** `[人工]` 在沒有任何手動準備輸入的乾淨 clone 上執行 `python3 scripts/build_data.py`，可以跑完並重新產出 `items`、`recipes`、`item_shop`、`gathering`、`fishing` 五個檔案。
- **AC-13** `[人工]` 以同一份 `data_sources.json` 連跑兩次，五個資料檔與遠端輸出逐 byte 相同。
- **AC-14** `[人工]` 遠端輸出的道具檔與內建 `items.json` 內容相同，`manifest.json` 的 `sha256` 和 `byteSize` 與該檔相符。
- **AC-15** `[人工]` 刪除 App 後在離線狀態第一次開啟，道具搜尋的分類、職業、部位 filter 都能篩出結果。
- **AC-16** `[人工]` 抽查 5 個道具，搜尋結果與 detail page 的名稱和繁中服遊戲內一致。
- **AC-17** `[diff]` 「不在這個 Phase」列出的資料檔沒有變動。
