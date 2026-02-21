# Cleanup Guide

Use this when you need a true "zero state" reset (including stale `openclaw.json`).

## Recommended: one command reset

```bash
./scripts/reset-state.sh
```

Non-interactive variant:

```bash
./scripts/reset-state.sh --yes
```

The script:

- stops containers (`docker compose down --volumes --remove-orphans`)
- removes persisted runtime state from:
  - `./data/storage/*`
  - `./data/browser/*`
  - `./workspace/*`

## Manual fallback

```bash
docker compose down --volumes --remove-orphans
rm -rf ./data/storage/* ./data/browser/* ./workspace/*
mkdir -p ./data/storage ./data/browser ./workspace
```
