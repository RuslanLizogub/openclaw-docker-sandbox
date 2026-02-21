#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

if [[ "${WITH_RESET_FLOW:-0}" != "1" ]]; then
  echo "[skip] reset-state flow check disabled (set WITH_RESET_FLOW=1)"
  exit 0
fi

echo "[info] running reset-state"
./scripts/reset-state.sh --yes

for dir in data/storage data/browser workspace; do
  if [[ ! -d "${dir}" ]]; then
    echo "[fail] missing ${dir} after reset-state"
    exit 1
  fi
done

echo "[info] starting container after reset-state"
docker compose up -d --build

echo "[info] validating workspace screenshots path is writable in container"
docker compose exec -T openclaw sh -lc '
  set -e
  mkdir -p /home/openclaw/.openclaw/workspace/screenshots
  printf ok > /home/openclaw/.openclaw/workspace/screenshots/.write-test
'

if [[ ! -f workspace/screenshots/.write-test ]]; then
  echo "[fail] host workspace/screenshots/.write-test not found after container write"
  exit 1
fi

echo "[info] validating browser target=node fallback test after reset"
docker compose exec -T openclaw pnpm -s vitest run \
  src/agents/tools/browser-tool.node-fallback.test.ts \
  --testNamePattern "falls back to local browser when target=node but no node is connected"

echo "[ok] reset-state flow passed"
