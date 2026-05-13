# Agent Workflow

This is a personal project using a lightweight Git Flow:

- Branch from `main` for each feature or fix.
- Use branch names like `feature/<short-topic>`, `fix/<short-topic>`
- Do not use a long-lived `develop` branch.
- Keep commits atomic: one logical change per commit. Do not combine unrelated features or fixes in one commit.
- Open a pull request into `main`; do not merge directly to `main`.
- Wait for CI and Claude Code review. Claude must comment even when no changes are required.
- A human performs the final review and manually merges the PR.

## Project Commands

- Build: `xcodebuild build -project EorzeaToolkit.xcodeproj -scheme EorzeaToolkit -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO`

## Project Context

- iOS SwiftUI app.
- Minimum deployment target: iOS 17.0.
- Scheme: `EorzeaToolkit`.
- Prefer existing SwiftUI patterns and keep UI/localization changes scoped.
