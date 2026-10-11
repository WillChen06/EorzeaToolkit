---
description: 根據 prompts 資料夾裡的 spec 實作功能
argument-hint: <spec 檔名，不含 .md>
---

實作 `prompts/$ARGUMENTS.md`。先閱讀現有的專案結構和相關程式碼，再開始修改。

規則都在 AGENTS.md，這裡不重複：

- 「Specs」：`## 驗收` 是這次實作的契約。逐條實作、不為了過關改條件、不做「不在這個 Phase」的事。
- 「Subagents」：spec 有 `## 驗收` 時，開工前平行跑 `project-explorer` 與 `acceptance-reviewer`
  （planning review），實作驗證完再跑一次 `acceptance-reviewer`（implementation review）。
- 「Commands」：交出前跑過 build、`./scripts/run_tests.sh`、`python3 scripts/validate_data.py`。

最後在 PR 內文逐條回報每個驗收條件的結果，包括沒做到的。
