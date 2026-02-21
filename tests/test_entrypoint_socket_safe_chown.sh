#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

if ! grep -q 'find "${STATE_DIR}" -xdev ! -type s -exec chown openclaw:openclaw {} +' docker-entrypoint.sh; then
  echo "[fail] docker-entrypoint.sh must skip socket files when applying chown"
  exit 1
fi

echo "[ok] docker-entrypoint chown is socket-safe"
