# Decisions

- Keep `AI_PROVIDER=openai` for LM Studio because LM Studio exposes an OpenAI-compatible API.
- Use `OPENAI_MODEL=openai/<lm-studio-model-id>` for local custom models.
- Keep model sync optional by default; enable `OPENCLAW_SYNC_ENV_MODEL=true` for LM Studio profile.
- Persist media dedupe scope for the whole run to avoid duplicate screenshot delivery.
- Keep reset-to-zero as a separate explicit command (`./scripts/reset-state.sh --yes`).
- For Telegram image delivery, fall back from `sendPhoto` to `sendDocument` on `PHOTO_INVALID_DIMENSIONS`.
- For Telegram e2e checks, do not use bot self-message (`sendMessage`) as trigger; only inbound user messages start agent handling.
- Keep commit-history checks in release flow (secrets + optional author metadata privacy check).
- Keep dependency security override patch (`0007`) in build pipeline to pin known vulnerable transitive packages.
- Gate Docker integration checks with `pnpm audit --prod --audit-level high` (fail on high/critical).
- Keep browser tool backward compatibility for URL field names: accept both `targetUrl` and `url`.
- Use `OPENCLAW_TMPDIR=/home/openclaw/.openclaw/tmp` in Docker runtime to avoid `/tmp` space exhaustion (`ENOSPC`).
- Keep an additional Telegram delivery-layer dedupe (`src/telegram/bot/delivery.ts`) to catch duplicates that bypass agent-level dedupe.
- Apply dedupe across repeated delivery calls even when `replyToMode=off` (scope key uses `chatId + thread + no-reply`) to suppress double screenshot sends in DM/group paths.
- Keep delivery dedupe TTL short (`30s`) to block immediate duplicates without suppressing legitimate later re-sends.
- Avoid recursive `chown -R` on state dir at container start; skip socket files to prevent boot loops on Chromium singleton socket artifacts.
