# OpenAB Developer Workflow

開發請求由 Discord 傳送至 OpenAB，再由 OpenAB 交給 Codex 執行。Codex 會先確認工作目錄狀態，依需求修改、驗證並回報結果。

- 每項變更必須從 `main` 建立獨立的 `feature/` 或 `fix/` branch。
- 若需提出 Pull Request，必須建立為 Draft PR。
- 禁止直接修改或 push 至 `main`。
- Xcode build 與測試由 GitHub Actions 執行。
- 最終是否 merge 由使用者審查後決定，Codex 不得自行 merge。
