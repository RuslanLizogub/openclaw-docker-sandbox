# Active Context

- Keep notes minimal.
- Primary runtime: `docker compose` + `openclaw` service.
- Two config modes are supported:
  - Remote provider API (`.env.example`)
  - Local LM Studio (`.env.lmstudio.local.example`)
- Current focus: stable screenshot flow (post `reset-state`) with browser URL alias compatibility (`url` and `targetUrl`), plus final Telegram delivery-level media dedupe.
- Important operational flow: `reset-state` must remain safe (system should work immediately after reset + up).
- Latest fixed regression: browser calls with `target=node` in single-container mode must fall back to local browser.
- Latest infra hardening: runtime temp files moved to state volume via `OPENCLAW_TMPDIR` to avoid `/tmp` ENOSPC restart loops.
- Latest delivery fix: `delivery.ts` dedupes media across reply blocks (including `path` vs `file://path`) to prevent duplicate screenshots in Telegram.
- Security status:
  - high/critical npm audit findings are closed via `openclaw-patches/0007-dependency-security-overrides.patch`
  - residual low/moderate findings are upstream transitive deps (`hono`, `request`, `ajv`)
- Release hygiene focus: run secret scans + history checks before publish; bot self-messages are not valid Telegram e2e triggers.
