#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

PATCH_FILE="openclaw-patches/0007-dependency-security-overrides.patch"

if [[ ! -f "${PATCH_FILE}" ]]; then
  echo "[fail] missing ${PATCH_FILE}"
  exit 1
fi

require_line() {
  local expected="$1"
  if ! grep -Fq "${expected}" "${PATCH_FILE}"; then
    echo "[fail] ${PATCH_FILE} missing: ${expected}"
    exit 1
  fi
}

require_line 'diff --git a/package.json b/package.json'
require_line 'diff --git a/pnpm-lock.yaml b/pnpm-lock.yaml'
require_line '+      "fast-xml-parser": "5.3.6",'
require_line '+      "tar": "7.5.9",'
require_line '+      "minimatch": "10.2.1"'

echo "[ok] dependency security override patch is present"
