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
