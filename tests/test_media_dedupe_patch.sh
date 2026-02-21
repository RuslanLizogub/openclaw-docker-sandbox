#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

PATCH_MAIN="openclaw-patches/0003-media-dedupe-and-browser-savedpath.patch"

if [[ ! -f "${PATCH_MAIN}" ]]; then
  echo "[fail] missing ${PATCH_MAIN}"
  exit 1
fi

if ! grep -q 'details.savedPath' "${PATCH_MAIN}"; then
  echo "[fail] 0003 patch must prefer details.savedPath"
  exit 1
fi

if ! grep -q 'emittedMediaUrlsNormalized' "${PATCH_MAIN}"; then
  echo "[fail] 0003 patch must include media dedupe state"
  exit 1
fi

if grep -q 'emittedMediaUrlsNormalized\.clear()' "${PATCH_MAIN}"; then
  echo "[fail] 0003 patch must not add reset-time media dedupe clear"
  exit 1
fi

echo "[ok] media dedupe patches are present"
