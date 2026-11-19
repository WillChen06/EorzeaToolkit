<!-- Claude Code reads CLAUDE.md and, while this file exists, does not load AGENTS.md on its
     own. The import below keeps both tools on the same instructions, including the CI review.
     Put shared rules in AGENTS.md; keep only Claude Code-specific notes here. -->

@AGENTS.md

## Agent skills

### Issue tracker

Issues and specs live in GitHub Issues for WillChen06/EorzeaToolkit, via `gh`. See `docs/agents/issue-tracker.md`.

### Triage labels

Default vocabulary: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: root `GLOSSARY.md` + `docs/adr/`. See `docs/agents/domain.md`.
