#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

if ! grep -q '^workspace/$' .gitignore; then
  echo "[fail] .gitignore must contain workspace/"
  exit 1
fi

if ! grep -q '^data/$' .gitignore; then
  echo "[fail] .gitignore must contain data/"
  exit 1
fi

if ! git check-ignore -q workspace; then
  echo "[fail] workspace is not ignored by git"
  exit 1
fi

if ! git check-ignore -q data; then
  echo "[fail] data is not ignored by git"
  exit 1
fi

if git ls-files workspace data | grep -q .; then
  echo "[fail] workspace/data contains tracked files"
  git ls-files workspace data
  exit 1
fi

echo "[ok] gitignore runtime paths are configured correctly"
