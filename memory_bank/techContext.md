# Tech Context

- Host: macOS (Apple Silicon).
- Runtime: Docker Compose, single `openclaw` service.
- Local model mode: LM Studio at `http://host.docker.internal:1234/v1`.
- Persistence mounts:
  - `./data/storage` -> `/home/openclaw/.openclaw`
  - `./data/browser` -> `/home/openclaw/.openclaw/browser`
  - `./workspace` -> `/home/openclaw/.openclaw/workspace`
- Patch system: `openclaw-patches/*.patch` applied during image build.
- Security hardening patch: `openclaw-patches/0007-dependency-security-overrides.patch`.
- Browser URL alias compatibility patch: `openclaw-patches/0008-browser-url-alias-compat.patch`.
- Telegram delivery media dedupe patch: `openclaw-patches/0009-telegram-media-delivery-dedupe.patch`.
- Entrypoint startup hardening: socket-safe `chown` in `docker-entrypoint.sh` (skip socket files).
- Runtime temp directory is pinned to state volume via `OPENCLAW_TMPDIR` / `TMPDIR`.
- Test gate: Docker integration check runs `pnpm audit --prod --audit-level high`.
- Extra regression gate: `tests/test_entrypoint_socket_safe_chown.sh` + delivery dedupe assertions in `tests/test_telegram_media_delivery_dedupe_patch.sh`.
