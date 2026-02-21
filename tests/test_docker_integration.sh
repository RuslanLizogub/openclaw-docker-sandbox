#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

if ! docker compose ps --services --filter status=running | grep -q '^openclaw$'; then
  echo "[skip] openclaw container is not running"
  exit 0
fi

echo "[info] validating runtime source in container"
docker compose exec -T openclaw sh -lc '
  cd /app
  if grep -n "emittedMediaUrlsNormalized.clear();" src/agents/pi-embedded-subscribe.ts >/dev/null; then
    echo "[fail] runtime source still clears media dedupe set"
    exit 1
  fi
  echo "[ok] runtime source keeps media dedupe set across assistant chunks"
'

echo "[info] running targeted media unit tests in container"
docker compose exec -T openclaw pnpm -s vitest run src/agents/pi-embedded-subscribe.handlers.tools.media.test.ts
docker compose exec -T openclaw pnpm -s vitest run src/agents/tools/browser-tool.node-fallback.test.ts
docker compose exec -T openclaw pnpm -s vitest run src/telegram/bot/delivery.test.ts

echo "[info] running dependency audit (high/critical gate)"
docker compose exec -T openclaw pnpm audit --prod --audit-level high

echo "[ok] docker integration checks passed"
