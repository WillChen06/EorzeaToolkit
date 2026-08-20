#!/usr/bin/env bash
# XcodeGen upgrades must be made in a dedicated PR, separate from feature work.

set -euo pipefail

readonly XCODEGEN_VERSION="2.45.3"
readonly XCODEGEN_ARCHIVE_SHA256="0c90f4d28ca57335f9fa78cf5bf6dabfe20a232036dabe36de2eef79cb7c0878"
readonly XCODEGEN_ARCHIVE_URL="https://github.com/yonaskolb/XcodeGen/releases/download/${XCODEGEN_VERSION}/xcodegen.zip"

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cache_root="${EORZEA_XCODEGEN_CACHE_DIR:-${HOME}/.cache/eorzea-toolkit/xcodegen}"
version_cache="${cache_root}/${XCODEGEN_VERSION}"
archive_path="${version_cache}/xcodegen.zip"
xcodegen_path="${version_cache}/xcodegen/bin/xcodegen"

sha256() {
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  elif command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  else
    echo "error: neither shasum nor sha256sum is available for SHA-256 verification." >&2
    return 1
  fi
}

verify_archive() {
  local actual_checksum
  actual_checksum="$(sha256 "$archive_path")" || return 1
  if [[ "$actual_checksum" != "$XCODEGEN_ARCHIVE_SHA256" ]]; then
    echo "error: XcodeGen ${XCODEGEN_VERSION} checksum mismatch." >&2
    echo "error: expected ${XCODEGEN_ARCHIVE_SHA256}, got ${actual_checksum}." >&2
    echo "error: remove the corrupt cache file and retry: ${archive_path}" >&2
    return 1
  fi
}

mkdir -p "$version_cache"

if [[ ! -f "$archive_path" ]]; then
  temporary_archive="$(mktemp "${TMPDIR:-/tmp}/eorzea-xcodegen.XXXXXX")"
  trap 'rm -f "$temporary_archive"' EXIT

  echo "Downloading XcodeGen ${XCODEGEN_VERSION}..."
  if ! curl --fail --location --show-error --silent \
    "$XCODEGEN_ARCHIVE_URL" --output "$temporary_archive"; then
    echo "error: failed to download XcodeGen ${XCODEGEN_VERSION}." >&2
    exit 1
  fi

  temporary_checksum="$(sha256 "$temporary_archive")" || exit 1
  if [[ "$temporary_checksum" != "$XCODEGEN_ARCHIVE_SHA256" ]]; then
    echo "error: downloaded XcodeGen ${XCODEGEN_VERSION} checksum mismatch." >&2
    echo "error: expected ${XCODEGEN_ARCHIVE_SHA256}, got ${temporary_checksum}." >&2
    exit 1
  fi

  mv "$temporary_archive" "$archive_path"
  trap - EXIT
fi

verify_archive || exit 1

# Re-extract from the verified artifact before every use so a modified cached executable
# is never trusted. XcodeGen does not remove or modify the tracked Package.resolved file.
if ! unzip -oq "$archive_path" -d "$version_cache"; then
  echo "error: failed to extract XcodeGen ${XCODEGEN_VERSION}." >&2
  exit 1
fi

if [[ ! -x "$xcodegen_path" ]]; then
  echo "error: verified XcodeGen archive did not contain an executable binary." >&2
  exit 1
fi

echo "Generating EorzeaToolkit.xcodeproj with XcodeGen ${XCODEGEN_VERSION}..."
cd "$repo_root"
if ! "$xcodegen_path" generate --spec project.yml; then
  echo "error: XcodeGen failed to generate EorzeaToolkit.xcodeproj." >&2
  exit 1
fi
