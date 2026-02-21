# Active Context

- Keep notes minimal.
- Primary runtime: `docker compose` + `openclaw` service.
- Two config modes are supported:
  - Remote provider API (`.env.example`)
  - Local LM Studio (`.env.lmstudio.local.example`)
- Current focus: stable screenshot flow (post `reset-state`) with browser URL alias compatibility (`url` and `targetUrl`) and no Telegram screenshot duplicates.
- Important operational flow: `reset-state` must remain safe (system should work immediately after reset + up).
- Latest fixed regression: browser calls with `target=node` in single-container mode must fall back to local browser.
- Latest infra hardening: runtime temp files moved to state volume via `OPENCLAW_TMPDIR` to avoid `/tmp` ENOSPC restart loops.
- Latest runtime fix: `docker-entrypoint.sh` uses socket-safe ownership update (`find ... ! -type s -exec chown ...`) to avoid restart-loop on Chromium `SingletonSocket`.
- Latest delivery fix: `delivery.ts` dedupes media across reply blocks/calls (including `path` vs `file://path`) and now also covers `replyToMode=off` scopes.
- Security status:
  - high/critical npm audit findings are closed via `openclaw-patches/0007-dependency-security-overrides.patch`
  - residual low/moderate findings are upstream transitive deps (`hono`, `request`, `ajv`)
- Release hygiene focus: run secret scans + history checks before publish; bot self-messages are not valid Telegram e2e triggers.
- Validation status: full checks passed with `WITH_DOCKER=1 WITH_RESET_FLOW=1 ./tests/run-all.sh`; manual Telegram no-duplicate re-check requested after current changes.
