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
- **Kingfisher and The Composable Architecture are the only third-party dependencies.**
  Kingfisher is used solely by `Views/CachedIconImage.swift` for remote icon loading. TCA is
  being trialled on the relic weapon, treasure map and skill rotation features (`Features/`); other features
  keep their `ViewModels/` pattern unless the user decides otherwise. Do not add another SPM package
  without the user's approval.
- **User-facing text goes through `EorzeaToolkit/Localization/Localizable.xcstrings`.** No
  hard-coded strings in views.
- **Follow the existing patterns** in `Views/`, `ViewModels/`, `Services/`, and `Models/`
  rather than introducing new architecture. Keep UI and localization changes scoped.
- **`EorzeaToolkit/Resources/Data/*.json` is generated data; never edit it by hand.**
  `items`, `recipes`, `item_shop`, `gathering`, `fishing`, `battle_actions` and
  `treasure_maps` come from `scripts/build_data.py`, which reads the
  upstream commits pinned in `scripts/data_sources.json` (the Traditional Chinese datamining and
  Teamcraft) and the curated treasure map definitions in `scripts/treasure_map_definitions.json`.
  Change a generator, its inputs or the pins, then regenerate. `relic_weapons` has no
  generator in the repository.
- **`project.yml` is the source of truth** for the Xcode project. Add targets, sources, and
  packages there; never hand-edit or commit the generated project. The only tracked file under
  it is `EorzeaToolkit.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`.

## Commands

- Generate the project: `./scripts/generate_project.sh`, or double-click
  `Generate EorzeaToolkit Project.command`. Needed before `xcodebuild` on a clean clone;
  `scripts/run_tests.sh` and CI run it themselves.
- Build: `xcodebuild build -quiet -project EorzeaToolkit.xcodeproj -scheme EorzeaToolkit -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath DerivedData -skipMacroValidation CODE_SIGNING_ALLOWED=NO`
  `-skipMacroValidation` lets TCA's macros run without first trusting them in Xcode.
  `-quiet` leaves only warnings and errors; drop it when you need the full build log.
- Unit tests: `./scripts/run_tests.sh`. CI runs it too, so breaking it fails the build.
  Locally it prints only errors, failing tests and the result, and writes the full output to
  `build/logs/run_tests.log`; read that file when the summary is not enough. CI, or
  `RUN_TESTS_VERBOSE=1`, streams the full output instead.
- UI tests (opt-in, not run by CI): `./scripts/run_ui_tests.sh <SIMULATOR_UDID>`; list UDIDs
  with `xcrun simctl list devices available`.
- Regenerate data: `python3 scripts/build_data.py` downloads the pinned upstream files, rewrites
  the seven generated data files and the remote copy in `build/remote-data/` (upload to the
  Cloudflare Worker is manual), then runs `validate_data.py`. The same pins produce the same
  bytes. It needs Python 3.9+ and network access to `raw.githubusercontent.com`, nothing else.
  When generator output changes for the same game version, bump `data_revision`.
- Validate data: `python3 scripts/validate_data.py` checks cross-file invariants over
  `EorzeaToolkit/Resources/Data`. Run it after regenerating any data file. Decodability is
  covered separately by `EorzeaToolkitTests/BundledDataTests.swift`.
- Evaluate item query parsing: `./scripts/run_item_query_eval.sh` builds the macOS
  `ItemQueryEval` tool and asks the on-device Foundation Models model about every sentence in
  `Tools/ItemQueryEval/cases.json`. It needs macOS 26 or later with Apple Intelligence on and
  its model downloaded; `--check` validates the evaluation set without calling the model. CI
  does not run it. Record each run in `docs/foundation-models-eval.md`, and run it again when a
  major OS release changes the model.
  - `--holdout` runs the user's held-out set, `Tools/ItemQueryEval/holdout.json`, instead. It
    skips the evaluation set's composition check and allows expected keywords the sentence does
    not contain (a player's nickname for an item). The run is judged by usage and whole
    sentences (`docs/archive/spec-flow/prompts/item-description-search.md`).
  - The user writes the held-out set's sentences and expected results. An agent may only put
    what the user wrote into the file's format, and must not change the matching rules or the
    model's instructions because of it before its first run.
  - When the user wants more sentences, a subagent that has not read the repository proposes
    candidates from the user's own sentences, and the user picks them and confirms their
    expected results. Their ids start with `holdout-g`.
  - `holdout-1.json` and `holdout-2.json` are the first and second runs' sets. The matching
    rules were adjusted to them, so they are regression sets (`ItemQueryHoldoutRegressionTests`),
    not held-out ones. A new held-out set goes in `holdout.json`, and its candidates are never
    modelled on the regression sets: the second set was proposed without any example sentences,
    and the user picked them.

Rules for running them:

- Run only one Xcode build or test workflow at a time.
- Building rewrites `Localizable.xcstrings` in place, and CI fails on any leftover diff. The
  build adds strings it finds in the source, deletes untranslated strings it no longer finds,
  and marks translated ones stale. Commit the regenerated catalog with the source change that
  caused it.
- Before committing a diff that removes catalog entries, check that each removed string is
  gone from the source. If one still appears, the build did not compile every file: discard the
  diff with `git checkout` and rebuild from clean.
- A key the code only reaches through a key built at runtime (for example
  `NSLocalizedString(key, comment:)`) is never extracted. Mark it `"extractionState" : "manual"`
  in the catalog, or builds will mark it stale.
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
  `.github/pull_request_template.md` in the shape of the `/pr` skill, including `## Spec`
  (the issues it closes) and `## Acceptance Criteria`.
- Never push to `main` and never merge. The user does the final review and merges manually.
- CI must be green before the automated review runs; it is skipped on a failing build, so fix
  the build first. Review standards live in `.github/claude-review-guidelines.md` and apply to
  local reviews and the CI review alike.
- Requests relayed through OpenAB (Discord → Codex) also follow
  `docs/openab-developer-workflow.md`.

## Specs and tickets

Work follows Matt Pocock's engineering skills (the `mattpocock-skills` Claude Code plugin) and
is tracked in GitHub Issues. `docs/agents/issue-tracker.md`, `docs/agents/triage-labels.md` and
`docs/agents/domain.md` configure them.

- **Spec**: a GitHub issue written with `/to-spec` after the problem has been discussed (or
  grilled with `/grill-with-docs`). It has Problem Statement, Solution, User Stories,
  Implementation Decisions, Testing Decisions, Out of Scope and Further Notes, and is labelled
  `ready-for-agent`.
- **Tickets**: `/to-tickets` breaks a spec into tracer-bullet sub-issues, each with acceptance
  criteria and its blocking edges. Bugs and requests enter through `/triage`.
- **Implementing**: `/implement` builds a ticket (or a small spec) with `/tdd` at the agreed
  seams; `/implement-spec` works a whole spec's ticket graph on one integration branch. Both
  close with `/code-review`, whose Standards axis reads this file and
  `.github/claude-review-guidelines.md` and whose Spec axis reads the originating issue.
- Do not build what the spec lists under Out of Scope. If a requirement turns out wrong, edit the
  issue and say what changed and why in the PR body.
- Domain vocabulary and decisions go in `GLOSSARY.md` and `docs/adr/`, created by
  `/domain-modeling` when a term or decision is first settled.
- This file overrides the skills' defaults. In particular `/implement-spec` does not open a
  draft PR or push (see Git and pull requests), tests run through `./scripts/run_tests.sh`, and
  Xcode builds and tests run one at a time even when implementer subagents work in parallel.
- Tools without the plugin (Codex through OpenAB) follow the same steps by hand: read the spec
  and ticket issues with `gh`, build test-first, and review the diff against the issue.

Specs written before this flow, with their `## 驗收` contracts, are archived in
`docs/archive/spec-flow/prompts/`; code comments and docs that cite them point there. The
previous workflow is described in `docs/archive/spec-flow/README.md`. Do not add new specs there.

## Subagents

The read-only explorer maps execution paths, data flow, affected files, existing patterns,
tests and risks. Its instructions live in `docs/agents/project-explorer.md`, which both tools'
agent definitions (`project_explorer` for Codex, `project-explorer` for Claude Code) point to.
Use it for cross-file features, refactors, complex bugs, an unclear execution path, or as the
exploration subagent of `/implement-spec`. Skip it for small, localized changes unless the user
asks.

- The explorer stays read-only: no file edits, and no commands that write workspace artifacts.
- Implementer subagents started by `/implement-spec` edit only in their own worktrees.
- Subagent findings are evidence and recommendations. Architecture, product, and scope
  decisions stay with the primary agent.

## Skills

`.agents/skills/` holds `swiftui-pro` and `swift-concurrency-pro`, pinned in
`skills-lock.json`. Codex reads them there; Claude Code reads them through the symlinks in
`.claude/skills/`. They assume newer OS and Swift versions, so the project constraints above
take precedence.
