# Claude Code Guidelines

## Repository Context

EorzeaToolkit is an iOS SwiftUI app.

- Scheme: `EorzeaToolkit`
- Project: `EorzeaToolkit.xcodeproj`
- Minimum iOS version: 17.0
- Swift version: 5.9
- Primary localization: Traditional Chinese

## Build and Test Commands

```sh
xcodebuild build -project EorzeaToolkit.xcodeproj -scheme EorzeaToolkit -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO
```

```sh
./scripts/run_tests.sh
```

`EorzeaToolkit.xcodeproj` is generated from `project.yml` by XcodeGen. Add targets, sources,
and packages there and run `xcodegen generate`; never hand-edit the project file.

XcodeGen derives object UUIDs from the objects themselves, so regenerating is byte-stable:
running it twice with nothing changed produces no diff at all, and adding one source file
touches only that file's four entries. A small, surgical `project.pbxproj` diff is what a
correct regeneration looks like — it is not evidence of a hand edit. A diff that rewrites
the whole file means the previous version came from somewhere other than XcodeGen.

## Writing Specs

Feature work starts from a spec under `prompts/`, written with the user before any code.
Follow [prompts/_TEMPLATE.md](prompts/_TEMPLATE.md).

The `## 驗收` section is the part that matters most and the part most easily skipped. Write it
during the spec session, while the desired behaviour is still the subject — not afterwards.
Written later it gets shaped around whatever was built, and the verification it is supposed to
enable collapses back into self-assessment.

Do not backfill the section into specs that shipped without it.

## Development Workflow

- Branch from `main` for features and fixes.
- Do not use a long-lived `develop` branch.
- Keep commits atomic: one logical change per commit.
- Open a PR into `main`.
- Do not merge PRs; final merge is manual.

## Review Rules

See [.github/claude-review-guidelines.md](.github/claude-review-guidelines.md). It is the
single source of truth for review standards and applies to local reviews and the CI review
workflow alike; do not restate its rules here.
