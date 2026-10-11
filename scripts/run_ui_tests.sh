#!/usr/bin/env bash
# Explicit destination: run once on a compact iPhone, then on the desired Duo state.
# This does not fold/resize a device, erase it, or reset app data.
set -euo pipefail
cd "$(dirname "$0")/.."

if [[ $# -lt 1 ]]; then
  echo "Usage: bash scripts/run_ui_tests.sh SIMULATOR_UDID [xcodebuild options]" >&2
  exit 2
fi
ui_simulator_id="$1"
shift
if [[ ! "$ui_simulator_id" =~ ^[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}$ ]]; then
  echo "Expected an explicit simulator UDID (xcrun simctl list devices available)." >&2
  exit 2
fi

./scripts/generate_project.sh
exec xcodebuild test \
  -project EorzeaToolkit.xcodeproj \
  -scheme EorzeaToolkitUI \
  -configuration Debug \
  -destination "id=${ui_simulator_id}" \
  -derivedDataPath DerivedData \
  -parallel-testing-enabled NO \
  -disableAutomaticPackageResolution \
  CODE_SIGNING_ALLOWED=NO \
  "$@"
