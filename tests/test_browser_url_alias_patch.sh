#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

PATCH_FILE="openclaw-patches/0008-browser-url-alias-compat.patch"

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

require_line 'diff --git a/src/agents/tools/browser-tool.schema.ts b/src/agents/tools/browser-tool.schema.ts'
require_line '+  url: Type.Optional(Type.String()),'
require_line '+function readTargetUrlOptional(params: Record<string, unknown>): string | undefined {'
require_line '+function readTargetUrlRequired(params: Record<string, unknown>): string {'
require_line '+  const legacyUrl = readStringParam(params, "url");'
require_line '+  it("accepts url alias for open action", async () => {'

echo "[ok] browser url alias patch is present"
