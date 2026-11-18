---
description: Implement a feature from a spec in the prompts folder
argument-hint: <spec file name, without .md>
---

Implement `prompts/$ARGUMENTS.md`. Read the existing project structure and the relevant code
before making changes.

The rules live in AGENTS.md and are not repeated here:

- "Specs": `## 驗收` is the contract for this implementation. Implement every criterion, do not
  change a criterion to make it pass, and do not build anything listed under 「不在這個 Phase」.
- "Subagents": when the spec has a `## 驗收` section, run `project-explorer` and
  `acceptance-reviewer` (planning review) in parallel before starting, and run
  `acceptance-reviewer` again (implementation review) after implementing and verifying.
- "Commands": before handing off, run the build, `./scripts/run_tests.sh`, and
  `python3 scripts/validate_data.py`.

Finally, report every acceptance criterion's outcome in the PR body, including any you did not
meet.
