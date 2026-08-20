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

exec xcodebuild test \
  -project EorzeaToolkit.xcodeproj \
  -scheme EorzeaToolkit \
  -configuration Debug \
  -destination "id=${udid}" \
  -derivedDataPath DerivedData \
  -disableAutomaticPackageResolution \
  CODE_SIGNING_ALLOWED=NO \
  "$@"
