# Claude Code Guidelines

## Repository Context

EorzeaToolkit is an iOS SwiftUI app.

- Scheme: `EorzeaToolkit`
- Project: `EorzeaToolkit.xcodeproj`
- Minimum iOS version: 17.0
- Swift version: 5.9
- Primary localization: Traditional Chinese

## Build Command

```sh
xcodebuild build -project EorzeaToolkit.xcodeproj -scheme EorzeaToolkit -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO
```

## Development Workflow

- Branch from `main` for features and fixes.
- Do not use a long-lived `develop` branch.
- Keep commits atomic: one logical change per commit.
- Open a PR into `main`.
- Do not merge PRs; final merge is manual.

## Review Rules

- Review for correctness, regressions, maintainability, SwiftUI best practices, localization issues, and security concerns.
- Prefer concise Traditional Chinese feedback.
- Leave inline comments for concrete changed-line issues when useful.
- Always leave a final PR comment, even if no changes are needed.
- If no changes are needed, state that clearly and mention any remaining build/test risk.
- Do not modify files, commit, push, approve, or merge during review.
