# Claude Review Guidelines

Single source of truth for how pull requests are reviewed in this repository.
`.github/workflows/claude-code-review.yml` owns the mechanics — review scope, CI result,
and the reviewed-commit marker — and defers everything below to this file.

## Project constraints

The **Project constraints** section of `AGENTS.md` defines them for every agent; it is loaded
through `CLAUDE.md`, so read it directly if it is not already in your context. They override
anything the skills say. In a review they mean:

- **iOS 18.0 / Swift 5.9.** Never suggest syntax or concurrency features unavailable in Swift
  5.9 language mode, and never propose raising the target as part of a review.
- **APIs newer than iOS 18.** Using one without an availability check is a finding. Using one
  is fine when the feature cannot exist without it. A change that adds separate code paths for
  newer and older OS versions needs the user's approval first: unless the spec calls for it,
  flag it as a decision for the user. Never suggest adopting a newer API that would need such
  a second path.
- **Kingfisher.** Do not suggest adding another SPM package, and do not flag existing
  Kingfisher usage.
- **Localization.** A hard-coded user-facing string in a view is a finding. The catalog is
  rewritten by every build, so a diff on it is expected when a PR adds or removes strings. A
  removed entry is a finding only if its string still appears in the source: that is the
  residue of a build that did not compile every file. A key the code only reaches through a
  key built at runtime must be marked `manual`; left as extracted, builds mark it stale.
- **Existing patterns.** Structural proposals belong in an issue, not a review.
- **Generated data.** If a data file and its generator disagree, say so; do not propose
  hand-editing the generated output. The seven generated files listed in `AGENTS.md` are
  reproducible from the upstream commits pinned in `scripts/data_sources.json` (plus
  `scripts/treasure_map_definitions.json`) with `python3 scripts/build_data.py`,
  but CI does not run it, since it needs the network. What CI checks is
  `scripts/validate_data.py` for cross-file invariants and source pins, and
  `EorzeaToolkitTests/BundledDataTests.swift` for decodability — a data change that needs a
  new invariant belongs in one of those, not in a review comment.

## Specs

Feature work in this repository starts from a spec written as a GitHub issue, broken into
ticket sub-issues that carry the acceptance criteria (`AGENTS.md`, "Specs and tickets"). The PR
body names them in a `## Spec` section (`Closes #<ticket>`, `Part of #<spec>`); read the body
with `gh pr view <PR NUMBER>` and then each issue with `gh issue view <N> --comments`. Do this
even in incremental mode, since issues never appear in a diff.

When a spec or ticket is named, judge the diff against it as well as on its own merits, and
check two things the code alone cannot show:

- **Gaps**: behaviour the spec or tickets require that the PR does not implement.
- **Overreach**: behaviour the PR implements that the spec's Out of Scope section explicitly
  defers.

Conformance is judged against the whole PR, so use `gh pr diff <PR NUMBER>` for it even in
incremental mode, and report gaps and overreach in the summary comment rather than as inline
comments when there is no changed line to anchor them to. The no-duplicate rule still applies:
never raise a gap a previous review already raised.

When the PR body says `none`, names no issue, or names one that does not exist, review the
diff on its own merits and say so in one line. Never block on a missing spec.

A requirement changed after the spec was written is a deliberate decision and must be
explained in the PR body: report it when the explanation is missing, or when the code and the
amended issue disagree.

### Acceptance criteria

Each ticket lists its acceptance criteria as checkboxes, and the PR body carries the author's
own line per criterion. Work through them one by one rather than forming an overall
impression, and cross-check the body: a criterion the author reported as met but the diff does
not support, or one a ticket lists and the body omits, is a finding. A criterion that needs the
app running cannot be verified here; never state or imply you verified one. A criterion the
author reports as **not** met was disclosed, so say it is outstanding and leave the judgement
to the human reviewer.

Report per-criterion status in the summary comment, keeping it to one line each.

Specs written before this flow are archived in `docs/archive/spec-flow/prompts/` and are
requirements documentation, not code: never report style, structure, or wording findings on
them.

## Skills

Consult a skill only when the changed lines call for it:

| Diff touches | Read |
| --- | --- |
| SwiftUI views, modifiers, animation, navigation, data flow | `.agents/skills/swiftui-pro/SKILL.md` |
| `async`/`await`, `Task`, `actor`, `@MainActor`, `Sendable`, async streams | `.agents/skills/swift-concurrency-pro/SKILL.md` |
| JSON data, Python generators, workflows, docs, archived specs | neither |

Each `SKILL.md` lists reference files under its `references/` directory. Load only the ones
the diff actually needs — there are over 1,600 lines in total, and reading them all burns the
review budget without improving the result. Ignore the nested `.agents/skills/*/skills/**`
copies; they are packaging artefacts of an older version.

## What counts as a finding

Report genuine problems only: correctness and regressions, data handling, localization gaps,
SwiftUI misuse with a concrete cost, security issues, and the spec gaps and overreach
described above. Do not nitpick, do not invent issues, and do not restate what the diff
already makes obvious.

Rank by severity and lead with what would actually break.

## Output

- Concise, actionable Traditional Chinese.
- Leave an inline comment on the most relevant changed line for concrete issues.
- Always leave a final PR comment, even when nothing needs fixing — say so explicitly and
  mention any residual build or test risk.
- Never modify files, create commits, push branches, approve, or merge.
