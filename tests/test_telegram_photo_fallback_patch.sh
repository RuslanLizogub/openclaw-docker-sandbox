#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

PATCH_FILE="openclaw-patches/0004-telegram-photo-fallback.patch"

if [[ ! -f "${PATCH_FILE}" ]]; then
  echo "[fail] missing ${PATCH_FILE}"
  exit 1
fi

if ! grep -q 'PHOTO_INVALID_DIMENSIONS' "${PATCH_FILE}"; then
  echo "[fail] telegram photo fallback patch must handle PHOTO_INVALID_DIMENSIONS"
  exit 1
fi

if ! grep -q 'sendDocument' "${PATCH_FILE}"; then
  echo "[fail] telegram photo fallback patch must retry via sendDocument"
  exit 1
fi

echo "[ok] telegram photo fallback patch is present"
