# Cleanup Guide

Use these commands when you need to wipe persistent state (agent memory DB and browser profile).

## Stop the sandbox

```bash
docker compose down
```

## Wipe memory and browser data

```bash
rm -rf ./data/storage/* ./data/browser/*
```

## (Optional) Also wipe workspace files

```bash
rm -rf ./workspace/*
```

## Recreate empty folders

```bash
mkdir -p ./data/storage ./data/browser ./workspace
```
