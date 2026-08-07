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
and packages there and run `xcodegen generate`; never hand-edit the project file. Regenerating
rewrites every object UUID, so expect a large but semantically empty diff.

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
