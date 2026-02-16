#!/usr/bin/env bash
set -euo pipefail

mkdir -p \
  /home/openclaw/.openclaw/storage \
  /home/openclaw/.openclaw/browser-profile \
  /home/openclaw/.openclaw/workspace

chown -R openclaw:openclaw /home/openclaw/.openclaw

exec gosu openclaw "$@"
