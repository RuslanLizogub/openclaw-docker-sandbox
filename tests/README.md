# Tests

Run all local checks:

```bash
./tests/run-all.sh
```

Run with Docker integration checks (container must be running):

```bash
WITH_DOCKER=1 ./tests/run-all.sh
```

Run destructive reset-state flow check:

```bash
WITH_RESET_FLOW=1 ./tests/run-all.sh
```

Recommended full validation (matches production restart flow):

```bash
WITH_DOCKER=1 WITH_RESET_FLOW=1 ./tests/run-all.sh
```

Individual checks:

- `./tests/test_gitignore.sh`
- `./tests/test_env_examples.sh`
- `./tests/test_tmpdir_runtime_config.sh`
- `./tests/test_dependency_security_patch.sh`
- `./tests/test_browser_url_alias_patch.sh`
- `./tests/test_media_dedupe_patch.sh`
- `./tests/test_telegram_photo_fallback_patch.sh`
- `./tests/test_telegram_media_delivery_dedupe_patch.sh`
- `./tests/test_docker_integration.sh`
- `./tests/test_reset_state_flow.sh`

Note:

- Telegram bot self-messages sent via `sendMessage` are not inbound user updates.
- For true end-to-end Telegram validation, send the task from your user account in Telegram.
- Docker integration check also gates `pnpm audit --prod --audit-level high`.
