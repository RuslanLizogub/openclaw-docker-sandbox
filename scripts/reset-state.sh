#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

usage() {
  cat <<'USAGE'
Usage: ./scripts/reset-state.sh [--yes]

Stops docker compose services and wipes persistent runtime state:
  - ./data/storage/*
  - ./data/browser/*
  - ./workspace/*

Pass --yes to skip the confirmation prompt.
USAGE
}

skip_confirm=false
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  usage
  exit 0
fi
if [[ "${1:-}" == "--yes" ]]; then
  skip_confirm=true
fi

if [[ "${skip_confirm}" != "true" ]]; then
  echo "This will stop services and delete local runtime data (storage/browser/workspace)."
  read -r -p "Continue? [y/N] " answer
  if [[ ! "${answer}" =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
  fi
fi

docker compose down --volumes --remove-orphans

for dir in data/storage data/browser workspace; do
  mkdir -p "${dir}"
  find "${dir}" -mindepth 1 -maxdepth 1 -exec rm -rf -- {} +
done

echo "Reset complete. State directories are now clean."
