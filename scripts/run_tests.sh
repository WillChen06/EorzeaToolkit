#!/usr/bin/env bash
#
# Runs the unit tests on an available iPhone simulator.
#
# A `name=iPhone 16` destination implicitly means `OS=latest`, which fails outright whenever
# the newest installed runtime carries no such device — that is the normal state of both a
# developer Mac and a GitHub runner shortly after an Xcode bump. Resolving a udid up front
# keeps the command working across both without pinning a device or an OS version.

set -euo pipefail

cd "$(dirname "$0")/.."

./scripts/generate_project.sh

udid="$(xcrun simctl list devices available --json | python3 -c '
import json, sys

def runtime_key(identifier):
    version = identifier.rsplit(".", 1)[-1].split("-")[1:]
    return tuple(int(part) for part in version)

devices = json.load(sys.stdin)["devices"]
candidates = [
    (runtime_key(runtime), device["udid"])
    for runtime, entries in devices.items()
    if "SimRuntime.iOS-" in runtime
    for device in entries
    if device.get("isAvailable") and device["name"].startswith("iPhone")
]

if not candidates:
    sys.exit("No available iPhone simulator found. Install an iOS runtime via Xcode.")

print(max(candidates)[1])
')"

echo "Testing on simulator ${udid}"

xcodebuild_args=(
  test
  -project EorzeaToolkit.xcodeproj
  -scheme EorzeaToolkit
  -configuration Debug
  -destination "id=${udid}"
  -derivedDataPath DerivedData
  -disableAutomaticPackageResolution
  # TCA's macros would otherwise need trusting in Xcode first, which CI cannot do.
  -skipMacroValidation
  CODE_SIGNING_ALLOWED=NO
  "$@"
)

# CI keeps the full output in the job log. Set RUN_TESTS_VERBOSE=1 to stream it locally too.
if [[ -n "${CI:-}" || -n "${RUN_TESTS_VERBOSE:-}" ]]; then
  exec xcodebuild "${xcodebuild_args[@]}"
fi

# Locally the full output, thousands of lines, goes to a file and only errors, failing tests and
# the result are printed. Coding agents read everything a command prints, so this keeps a test
# run from filling their context; the log is there when the summary is not enough.
log_path="build/logs/run_tests.log"
mkdir -p "$(dirname "$log_path")"
echo "Writing the full xcodebuild output to ${log_path}"

status=0
xcodebuild "${xcodebuild_args[@]}" >"$log_path" 2>&1 || status=$?

summary="$(awk '
  /^Failing tests:$/ { listing = 1; print; next }
  listing && (NF == 0 || /^\*\* /) { listing = 0 }
  listing { print; next }
  /: (fatal )?error: / || /^xcodebuild: error/ || /[Tt]est [Cc]ase .* failed/ {
    if (seen[$0]++) next
    if (shown < 40) { print; shown++ } else { hidden++ }
    next
  }
  /^[[:space:]]*Executed [0-9]+ tests?, with / { executed = $0 }
  /^\*\* [A-Z ]+ \*\*$/ { result = $0 }
  END {
    if (hidden) printf "... %d more error lines in the log\n", hidden
    if (executed) print executed
    if (result) print result
  }
' "$log_path")"

if [[ -n "$summary" ]]; then
  echo "$summary"
fi

# Nothing recognisable in a failed run (a crash, a destination problem): show the end of the log.
if [[ "$status" -ne 0 && -z "$summary" ]]; then
  tail -n 30 "$log_path"
fi

echo "Full log: ${log_path}"
exit "$status"
