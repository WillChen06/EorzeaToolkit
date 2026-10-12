# EorzeaToolkit Agent Instructions

<!-- Shared by every coding agent on this repository (Codex, Claude Code via the @AGENTS.md
     import in CLAUDE.md, and any other AGENTS.md-aware tool). Keep it tool-neutral: tool-specific
     setup belongs in that tool's own files (CLAUDE.md, .claude/, .codex/), and review-only rules
     belong in .github/claude-review-guidelines.md. -->

iOS SwiftUI app for the Traditional Chinese FF14 community. Scheme `EorzeaToolkit`; the Xcode
project `EorzeaToolkit.xcodeproj` is generated. Primary localization is Traditional Chinese
(zh-Hant).

## Project constraints

These override anything a skill or general best practice says.

- **iOS 18.0 deployment target, Swift 5.9 language mode.** The bundled skills are written for
  iOS 26 and Swift 6.2. Do not use syntax or concurrency features unavailable in Swift 5.9
  language mode, and do not raise the target or the language mode as part of other work.
- **APIs newer than iOS 18 are a judgement call, not a ban.** Every use sits behind
  `@available` / `#available`.
  - When a feature cannot exist without the newer OS (for example Foundation Models, which
    needs iOS 26), use the API. On older versions the feature is unavailable and nothing else
    changes.
  - When the change needs separate code paths for newer and older OS versions (for example a
    new UI style or component on iOS 26 alongside the existing one), ask the user before
    implementing it. Do not build both paths on your own.
- **Kingfisher is the only third-party dependency**, used solely by
  `Views/CachedIconImage.swift` for remote icon loading. Do not add another SPM package without
  the user's approval.
- **User-facing text goes through `EorzeaToolkit/Localization/Localizable.xcstrings`.** No
  hard-coded strings in views.
- **Follow the existing patterns** in `Views/`, `ViewModels/`, `Services/`, and `Models/`
  rather than introducing new architecture. Keep UI and localization changes scoped.
- **`EorzeaToolkit/Resources/Data/*.json` is generated** by `scripts/build_*.py`. Change the
  generator, never the output by hand. The generators' inputs (datamining CSV, Teamcraft dumps)
  are not in the repository.
- **`project.yml` is the source of truth** for the Xcode project. Add targets, sources, and
  packages there; never hand-edit or commit the generated project. The only tracked file under
  it is `EorzeaToolkit.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`.

## Commands

- Generate the project: `./scripts/generate_project.sh`, or double-click
  `Generate EorzeaToolkit Project.command`. Needed before `xcodebuild` on a clean clone;
  `scripts/run_tests.sh` and CI run it themselves.
- Build: `xcodebuild build -project EorzeaToolkit.xcodeproj -scheme EorzeaToolkit -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO`
- Unit tests: `./scripts/run_tests.sh`. CI runs it too, so breaking it fails the build.
- UI tests (opt-in, not run by CI): `./scripts/run_ui_tests.sh <SIMULATOR_UDID>`; list UDIDs
  with `xcrun simctl list devices available`.
- Validate data: `python3 scripts/validate_data.py` checks cross-file invariants over
  `EorzeaToolkit/Resources/Data`. Run it after regenerating any data file. Decodability is
  covered separately by `EorzeaToolkitTests/BundledDataTests.swift`.

Rules for running them:

- Run only one Xcode build or test workflow at a time.
- Building rewrites `Localizable.xcstrings` in place, and CI fails on any leftover diff. If you
  added user-facing strings, commit the regenerated catalog. If the diff only *removes* entries,
  it came from a build that did not compile everything: discard it with `git checkout` and
  rebuild from clean rather than committing it.
- If your environment cannot run `xcodebuild` (for example on Linux), say so. Never report a
  build or test as passing unless you ran it; report it as unverified and leave it to CI.
- Upgrade the pinned XcodeGen version and checksum only in a dedicated PR, never together with
  feature work or unrelated changes.

## Git and pull requests

- Branch from `main` as `feature/<topic>`, `fix/<topic>`, `chore/<topic>`, or `test/<topic>`.
  Do not use a long-lived `develop` branch.
- Keep commits atomic: one logical change per commit.
- Do not push until the user has verified your changes and tells you to push. Then push the
  branch and open a regular pull request into `main`, not a draft: the user has already
  verified it, and a draft would hold back the automated review. Fill in
  `.github/pull_request_template.md`, including `## Spec` and `## Acceptance Criteria`.
- Never push to `main` and never merge. The user does the final review and merges manually.
- CI must be green before the automated review runs; it is skipped on a failing build, so fix
  the build first. Review standards live in `.github/claude-review-guidelines.md` and apply to
  local reviews and the CI review alike.
- Requests relayed through OpenAB (Discord → Codex) also follow
  `docs/openab-developer-workflow.md`.

## Specs

Feature work starts from a spec under `prompts/`, written with the user before any code and
following `prompts/_TEMPLATE.md`.

Writing a spec:

- Write the `## 驗收` section during the spec session, while the desired behaviour is still the
  subject. Written after implementation, it bends toward whatever was built and verification
  collapses into self-assessment.
- Do not backfill `## 驗收` into specs that shipped without it.

Implementing a spec: its `## 驗收` section is the contract.

- Implement every criterion; do not pick and choose.
- `[自動]`: prove it with a unit test or `scripts/validate_data.py`. If the criterion names a
  test, confirm it really asserts the criterion; if it names none, add one.
- `[diff]`: must be evident from the diff alone.
- `[人工]`: needs the running app. Give reproducible steps and the expected result, and leave
  the verdict to the user.
- Do not reshape a criterion to fit what you built. If a criterion is wrong, change the spec
  and explain what changed and why in the PR body.
- Do not build anything the spec defers under 「不在這個 Phase」.
- Report every criterion's outcome in the PR body, including any you could not meet.

## Subagents

Two read-only roles support this work. Each role's instructions live in one shared file that
every tool's agent definition points to:

| Role | Instructions | Codex agent | Claude Code agent |
| --- | --- | --- | --- |
| Explorer | `docs/agents/project-explorer.md` | `project_explorer` | `project-explorer` |
| Acceptance reviewer | `docs/agents/acceptance-reviewer.md` | `acceptance_reviewer` | `acceptance-reviewer` |

When asked to implement a spec that has a `## 驗收` section, use this workflow without waiting
to be asked for subagents:

1. Before editing files, run the explorer and the acceptance reviewer (planning-review mode) in
   parallel. The explorer maps the execution path, data flow, affected files, existing
   patterns, tests, and risks; the reviewer maps each criterion, preserved exactly, to the
   implementation evidence, tests, validation scripts, and manual checks it needs.
2. Wait for both, then fold their results into the implementation plan.
3. Only the primary agent edits files and runs the build, test, and data-validation commands.
4. After implementing and verifying, run the acceptance reviewer again in implementation-review
   mode. Give it the spec path, the diff scope, and every build, test, validation, and
   manual-check result available.
5. Resolve every actionable finding, or explicitly report unmet and unverified criteria, before
   calling the task done.

For other tasks, use the explorer for cross-file features, refactors, complex bugs, or an
unclear execution path. Skip subagents for small, localized changes unless the user asks.

- Subagents stay read-only: no file edits, and no commands that write workspace artifacts.
- Their findings are evidence and recommendations. Architecture, product, and scope decisions
  stay with the primary agent.
- If your tool cannot run subagents, perform both roles yourself as separate passes, following
  the instruction files above.

## Skills

`.agents/skills/` holds `swiftui-pro` and `swift-concurrency-pro`, pinned in
`skills-lock.json`. Codex reads them there; Claude Code reads them through the symlinks in
`.claude/skills/`. They assume newer OS and Swift versions, so the project constraints above
take precedence.
