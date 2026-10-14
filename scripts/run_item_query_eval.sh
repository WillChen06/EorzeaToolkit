#!/usr/bin/env bash
#
# Builds the item query evaluation tool (macOS) and runs it on the evaluation set.
#
# The full run needs macOS 26 or later with Apple Intelligence on and its model downloaded.
# With --check it only validates Tools/ItemQueryEval/cases.json and never calls the model.
# CI does not run this. See prompts/item-query-eval.md.
#
# Usage: ./scripts/run_item_query_eval.sh [--check] [--cases <path>] [--items <path>]

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
