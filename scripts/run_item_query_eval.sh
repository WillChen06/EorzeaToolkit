#!/usr/bin/env bash
#
# Builds the item query evaluation tool (macOS) and runs it on the evaluation set,
# Tools/ItemQueryEval/cases.json.
#
# The full run needs macOS 26 or later with Apple Intelligence on and its model downloaded.
# With --check it only validates the set and never calls the model.
# With --holdout it runs the user's held-out set, Tools/ItemQueryEval/holdout.json, instead:
# the evaluation set's composition is not checked, and the run is judged by usage and whole
# sentences. See prompts/item-description-search.md.
# CI does not run this. See prompts/item-query-eval.md.
#
# Usage: ./scripts/run_item_query_eval.sh [--check] [--holdout] [--cases <path>] [--items <path>]

set -euo pipefail

cd "$(dirname "$0")/.."

./scripts/generate_project.sh

xcodebuild build \
  -project EorzeaToolkit.xcodeproj \
  -scheme ItemQueryEval \
  -configuration Debug \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath DerivedData \
  -disableAutomaticPackageResolution \
  -quiet \
  CODE_SIGNING_ALLOWED=NO

exec DerivedData/Build/Products/Debug/ItemQueryEval --root "$PWD" "$@"
