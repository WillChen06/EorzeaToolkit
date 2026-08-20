# Claude Code Guidelines

## Repository Context

EorzeaToolkit is an iOS SwiftUI app.

- Scheme: `EorzeaToolkit`
- Project: `EorzeaToolkit.xcodeproj`
- Minimum iOS version: 17.0
- Swift version: 5.9
- Primary localization: Traditional Chinese

## Build and Test Commands

Generate the local Xcode project first. CI and `scripts/run_tests.sh` also run this shared
generator automatically.

```sh
./scripts/generate_project.sh
```

```sh
xcodebuild build -project EorzeaToolkit.xcodeproj -scheme EorzeaToolkit -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO
```

```sh
./scripts/run_tests.sh
```

`project.yml` is the source of truth for `EorzeaToolkit.xcodeproj`. Add targets, sources, and
packages there; never hand-edit the generated project. Generated project contents are ignored
and must not be committed. The only tracked file below the project directory is
`project.xcworkspace/xcshareddata/swiftpm/Package.resolved`, which locks SwiftPM dependencies.
Developers can run the shared generator above or double-click
`Generate EorzeaToolkit Project.command`; CI generates the project after checkout.

Upgrade the pinned XcodeGen version and checksum only in a dedicated PR. Do not combine an
XcodeGen upgrade with feature work or other changes.

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
