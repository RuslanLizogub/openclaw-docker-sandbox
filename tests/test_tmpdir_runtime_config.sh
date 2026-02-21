#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

require_line() {
  local file="$1"
  local expected="$2"
  if ! grep -Fq "${expected}" "${file}"; then
    echo "[fail] ${file} missing: ${expected}"
    exit 1
  fi
}

require_line docker-compose.yml 'OPENCLAW_TMPDIR: ${OPENCLAW_TMPDIR:-/home/openclaw/.openclaw/tmp}'
require_line docker-compose.yml 'TMPDIR: ${OPENCLAW_TMPDIR:-/home/openclaw/.openclaw/tmp}'
require_line docker-entrypoint.sh 'TMP_DIR="${OPENCLAW_TMPDIR:-${TMPDIR:-${STATE_DIR}/tmp}}"'
require_line docker-entrypoint.sh 'export TMPDIR="${TMP_DIR}"'

echo "[ok] tmpdir runtime config is present"
