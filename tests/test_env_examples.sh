#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

require_key() {
  local file="$1"
  local key="$2"
  if ! grep -q "^${key}=" "${file}"; then
    echo "[fail] ${file} is missing ${key}"
    exit 1
  fi
}

for file in .env.example .env.lmstudio.local.example; do
  if [[ ! -f "${file}" ]]; then
    echo "[fail] missing ${file}"
    exit 1
  fi
done

require_key .env.example AI_PROVIDER
require_key .env.example OPENAI_API_KEY
require_key .env.example ANTHROPIC_API_KEY
require_key .env.example GEMINI_API_KEY
require_key .env.example OPENCLAW_TMPDIR

require_key .env.lmstudio.local.example AI_PROVIDER
require_key .env.lmstudio.local.example OPENAI_API_KEY
require_key .env.lmstudio.local.example OPENAI_BASE_URL
require_key .env.lmstudio.local.example OPENAI_MODEL
require_key .env.lmstudio.local.example OPENAI_CUSTOM_MODEL_ENABLED
require_key .env.lmstudio.local.example OPENCLAW_SYNC_ENV_MODEL
require_key .env.lmstudio.local.example OPENCLAW_TMPDIR

if ! grep -q '^AI_PROVIDER=openai$' .env.lmstudio.local.example; then
  echo "[fail] .env.lmstudio.local.example must keep AI_PROVIDER=openai"
  exit 1
fi

echo "[ok] env examples include mandatory keys"
