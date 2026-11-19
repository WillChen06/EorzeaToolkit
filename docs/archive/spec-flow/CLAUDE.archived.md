<!-- Claude Code reads CLAUDE.md and, while this file exists, does not load AGENTS.md on its
     own. The import below keeps both tools on the same instructions, including the CI review.
     Put shared rules in AGENTS.md; keep only Claude Code-specific notes here. -->

@AGENTS.md

## Claude Code

- `/add-feature <spec>` implements `prompts/<spec>.md` using the spec and subagent workflow
  above.
