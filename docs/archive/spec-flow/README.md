# Archived: the `prompts/` spec flow

Until 2026-11-18, feature work in this repository started from a Markdown spec under `prompts/`,
written from `prompts/_TEMPLATE.md` and ending in a `## 驗收` section of criteria tagged
`[自動]`, `[diff]` or `[人工]`. That section was the implementation contract. `/add-feature
<spec>` implemented a spec, and the read-only `acceptance-reviewer` subagent checked the
criteria before and after implementation.

The repository now follows Matt Pocock's engineering skills, with specs and tickets as GitHub
issues (`AGENTS.md`, "Specs and tickets"). This folder keeps the old flow as a backup. It is
not live: agents do not follow the instructions in it.

| File | Was |
| --- | --- |
| `prompts/` | Every spec written under the old flow, and `_TEMPLATE.md`. Code comments and docs that cite a spec point here. |
| `AGENTS.archived.md` | `AGENTS.md` as of the switch, with the "Specs" and "Subagents" sections that defined the flow. |
| `CLAUDE.archived.md` | `CLAUDE.md` as of the switch, with the `/add-feature` note. |
| `add-feature.md` | `.claude/commands/add-feature.md` |
| `agents/acceptance-reviewer.md` | `docs/agents/acceptance-reviewer.md`, the reviewer's instructions |
| `agents/claude-acceptance-reviewer.md` | `.claude/agents/acceptance-reviewer.md` |
| `agents/codex-acceptance_reviewer.toml` | `.codex/agents/acceptance_reviewer.toml` |
| `agents/claude-project-explorer.md` | `.claude/agents/project-explorer.md` before its description dropped the `## 驗收` mention. The explorer itself is still live. |
| `pull_request_template.md` | `.github/pull_request_template.md` |
| `claude-review-guidelines.md` | `.github/claude-review-guidelines.md`, whose "Specs" section reviewed against `## 驗收` |
| `openab-developer-workflow.md` | `docs/openab-developer-workflow.md` |

The instruction files are renamed `*.archived.md` so that neither tool loads them as live
instructions when it reads files in this folder.

## Restoring

Move the files back to the paths in the table (the archived instruction files lose the
`.archived` suffix), move `prompts/` back to the repository root, and change the
`docs/archive/spec-flow/prompts/` paths in code comments and docs back to `prompts/`.
`git log --follow` on any moved file shows its history.
