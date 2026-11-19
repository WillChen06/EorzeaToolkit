# OpenAB Developer Workflow

開發請求由 Discord 傳送至 OpenAB，再由 OpenAB 交給 Codex 執行。Codex 會先確認工作目錄狀態，依需求修改、驗證並回報結果。

共通規則以 `AGENTS.md` 為準：branch 命名、經使用者驗證後才 push 並開一般 PR（不開 Draft）、禁止 push 至 `main` 與自行 merge、spec／ticket 流程與 subagent。這裡只記 OpenAB 環境特有的部分。

- Codex 沒有 `mattpocock-skills` plugin。spec 與 ticket 是 GitHub issue，用 `gh issue view` 讀取，照 `AGENTS.md`「Specs and tickets」手動走同樣的步驟。
- Xcode build 與測試由 GitHub Actions 執行。OpenAB 環境若無法執行 `xcodebuild`，依 `AGENTS.md` 回報為未驗證，不得宣稱通過。
