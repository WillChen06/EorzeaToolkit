#!/usr/bin/env bash

set -uo pipefail

cd "$(dirname "$0")" || exit 1

./scripts/generate_project.sh
status=$?
if [[ "$status" -ne 0 ]]; then
  echo
  echo "Project generation failed. Review the error above."
  if [[ -t 0 ]]; then
    read -r -p "Press Return to close this window..." _
  fi
  exit "$status"
fi

open EorzeaToolkit.xcodeproj
status=$?
if [[ "$status" -ne 0 ]]; then
  echo
  echo "The project was generated, but Xcode could not be opened."
  if [[ -t 0 ]]; then
    read -r -p "Press Return to close this window..." _
  fi
  exit "$status"
fi
