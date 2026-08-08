# Agent Workflow

This is a personal project using a lightweight Git Flow:

- Branch from `main` for each feature or fix.
- Use branch names like `feature/<short-topic>`, `fix/<short-topic>`
- Do not use a long-lived `develop` branch.
- Keep commits atomic: one logical change per commit. Do not combine unrelated features or fixes in one commit.
- Open a pull request into `main`; do not merge directly to `main`.
- Implement against the spec's `## 驗收` section when it has one — see `prompts/_TEMPLATE.md`.
  Each criterion is part of the contract: implement all of them, cover the `[自動]` ones with
  tests, and report every criterion's outcome in the PR body, including any you could not meet.
  Do not reshape a criterion to fit what you built; correct it and say so in the PR.
- Wait for CI. The Claude review only starts once the build is green, and is skipped entirely
  when it is not; fix the build first. Claude must comment even when no changes are required.
  Review standards live in `.github/claude-review-guidelines.md`.
- A human performs the final review and manually merges the PR.

## Subagent Workflow

The primary agent owns all implementation decisions, file edits, builds, tests, and final
responses. Subagents are read-only investigators and reviewers.

### Spec-driven tasks

When the user asks to implement a specification file that contains a `## 驗收` section, the
primary agent must use the following workflow without requiring the user to request subagents
explicitly:

1. Before editing files, spawn `project_explorer` and `acceptance_reviewer` in parallel.
2. Ask `project_explorer` to map the execution path, data flow, affected files, existing
   implementation patterns, tests, and risks.
3. Ask `acceptance_reviewer` to work in planning-review mode, preserve every acceptance
   criterion exactly, and map each criterion to required implementation evidence, automated
   tests, validation scripts, and manual checks.
4. Wait for both subagents to finish.
5. Have the primary agent integrate both results into the implementation plan.
6. Have only the primary agent modify files and run the documented build, test, and
   data-validation commands.
7. After implementation and verification, spawn `acceptance_reviewer` again in
   implementation-review mode.
8. Provide the reviewer with the specification path, diff scope, and all available build,
   test, validation, and manual-verification results.
9. Resolve all actionable findings or explicitly report any unmet or unverified acceptance
   criteria before declaring the task complete.

### Non-spec tasks

- Use `project_explorer` for cross-file features, refactors, complex bugs, or tasks whose
  execution path is unclear.
- Do not use subagents for small changes with an obvious and localized scope unless the user
  explicitly requests them.

### Coordination rules

- Keep `project_explorer` and `acceptance_reviewer` read-only.
- Subagents must not edit files or run commands that generate workspace artifacts.
- Run only one Xcode build or test workflow at a time.
- Treat subagent findings as evidence and recommendations. Architecture, product, and scope
  decisions remain with the primary agent.

## Project Commands

- Build: `xcodebuild build -project EorzeaToolkit.xcodeproj -scheme EorzeaToolkit -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO`
- Test: `./scripts/run_tests.sh` — CI runs this too, so a change that breaks it fails the build.
- Validate data: `python3 scripts/validate_data.py` — cross-file invariants over
  `EorzeaToolkit/Resources/Data`. Run it after regenerating any data file. Whether a file still
  decodes is covered separately by `EorzeaToolkitTests/BundledDataTests.swift`.
- `EorzeaToolkit.xcodeproj` is generated from `project.yml` by XcodeGen. Add targets, sources,
  and packages there and run `xcodegen generate`; never hand-edit the project file.
- Building rewrites `EorzeaToolkit/Localization/Localizable.xcstrings` in place, and CI fails on
  any leftover diff. If you added user-facing strings, commit the regenerated catalog. If the
  diff only *removes* entries, it came from a build that did not compile everything — discard it
  with `git checkout` and rebuild from clean rather than committing it.

## Project Context

- iOS SwiftUI app.
- Minimum deployment target: iOS 17.0.
- Scheme: `EorzeaToolkit`.
- Prefer existing SwiftUI patterns and keep UI/localization changes scoped.
