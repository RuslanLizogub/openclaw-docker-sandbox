#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

echo "[run] test_gitignore.sh"
./tests/test_gitignore.sh

echo "[run] test_env_examples.sh"
./tests/test_env_examples.sh

echo "[run] test_tmpdir_runtime_config.sh"
./tests/test_tmpdir_runtime_config.sh

echo "[run] test_entrypoint_socket_safe_chown.sh"
./tests/test_entrypoint_socket_safe_chown.sh

echo "[run] test_dependency_security_patch.sh"
./tests/test_dependency_security_patch.sh

echo "[run] test_browser_url_alias_patch.sh"
./tests/test_browser_url_alias_patch.sh

echo "[run] test_media_dedupe_patch.sh"
./tests/test_media_dedupe_patch.sh

echo "[run] test_telegram_photo_fallback_patch.sh"
./tests/test_telegram_photo_fallback_patch.sh

echo "[run] test_telegram_media_delivery_dedupe_patch.sh"
./tests/test_telegram_media_delivery_dedupe_patch.sh

echo "[run] test_reset_state_flow.sh"
./tests/test_reset_state_flow.sh

if [[ "${WITH_DOCKER:-0}" == "1" ]]; then
  echo "[run] test_docker_integration.sh"
  ./tests/test_docker_integration.sh
else
  echo "[skip] Docker integration checks (set WITH_DOCKER=1 to enable)"
fi

echo "[ok] all selected checks passed"
