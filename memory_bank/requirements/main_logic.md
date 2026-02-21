# Main Logic

- Start from one `.env` profile:
  - `.env.example` for cloud providers
  - `.env.lmstudio.local.example` for LM Studio local server
- Build and run with the same compose stack.
- If switching provider/model mode, reset state first:
  - `./scripts/reset-state.sh --yes`
- Keep runtime artifacts out of git:
  - `workspace/`, `data/`, `.env`
- For screenshot tasks:
  - save to `workspace/screenshots/...`
  - return one media attachment per screenshot result
  - if Telegram rejects image dimensions, retry as document.
