#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

PATCH_FILE_BASE="openclaw-patches/0009-telegram-media-delivery-dedupe.patch"

if [[ ! -f "${PATCH_FILE_BASE}" ]]; then
  echo "[fail] missing ${PATCH_FILE_BASE}"
  exit 1
fi

if ! grep -q 'dedupeMediaUrlsForDelivery' "${PATCH_FILE_BASE}"; then
  echo "[fail] delivery dedupe patch must include dedupeMediaUrlsForDelivery"
  exit 1
fi

if ! grep -q 'normalizeMediaUrlForDedupe' "${PATCH_FILE_BASE}"; then
  echo "[fail] delivery dedupe patch must include normalizeMediaUrlForDedupe"
  exit 1
fi

if ! grep -q 'deduplicates same local media across replies (path + file URL)' "${PATCH_FILE_BASE}"; then
  echo "[fail] delivery dedupe patch must include cross-reply dedupe test"
  exit 1
fi

if ! grep -q '__resetDeliveryMediaDedupeForTests' "${PATCH_FILE_BASE}"; then
  echo "[fail] cross-call dedupe patch must expose test reset hook"
  exit 1
fi

if ! grep -q 'does not resend identical media across repeated delivery calls for the same reply target' "${PATCH_FILE_BASE}"; then
  echo "[fail] cross-call dedupe patch must include repeated-delivery regression test"
  exit 1
fi

if ! grep -q 'does not resend identical media across repeated delivery calls when replyTo mode is off' "${PATCH_FILE_BASE}"; then
  echo "[fail] cross-call dedupe patch must include replyTo=off regression test"
  exit 1
fi

echo "[ok] telegram delivery media dedupe patch is present"
