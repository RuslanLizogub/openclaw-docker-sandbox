#!/usr/bin/env bash
set -euo pipefail

STATE_DIR="${OPENCLAW_STATE_DIR:-/home/openclaw/.openclaw}"
CONFIG_PATH="${OPENCLAW_CONFIG_PATH:-${STATE_DIR}/openclaw.json}"
WORKSPACE_DIR="${WORKSPACE_PATH:-${STATE_DIR}/workspace}"
TMP_DIR="${OPENCLAW_TMPDIR:-${TMPDIR:-${STATE_DIR}/tmp}}"

export TMPDIR="${TMP_DIR}"

is_true() {
  case "${1:-}" in
    1|true|TRUE|yes|YES|on|ON) return 0 ;;
    *) return 1 ;;
  esac
}

mkdir -p \
  "${STATE_DIR}" \
  "${STATE_DIR}/browser" \
  "${WORKSPACE_DIR}" \
  "${TMP_DIR}"

disable_workspace_template_file() {
  local rel_path="$1"
  local marker_a="$2"
  local marker_b="$3"
  local src="${WORKSPACE_DIR}/${rel_path}"
  local disabled_dir="${STATE_DIR}/system/disabled-workspace-files"
  local dst="${disabled_dir}/${rel_path}.disabled"
  local placeholder="# workspace-local
# intentionally minimal to reduce prompt size for local LLM
"

  # If file is missing, create a small placeholder so OpenClaw does not
  # scaffold large onboarding templates into the prompt.
  if [[ ! -f "${src}" ]]; then
    printf "%s" "${placeholder}" > "${src}"
    echo "[entrypoint] Created workspace placeholder ${rel_path}"
    return 0
  fi

  grep -q "${marker_a}" "${src}" || return 0
  grep -q "${marker_b}" "${src}" || return 0

  mkdir -p "${disabled_dir}"
  mv -f "${src}" "${dst}"
  printf "%s" "${placeholder}" > "${src}"
  echo "[entrypoint] Disabled workspace template ${rel_path}"
}

# Backward-compatible mapping for older env templates.
if [[ -z "${GEMINI_API_KEY:-}" && -n "${GOOGLE_GENERATIVE_AI_API_KEY:-}" ]]; then
  export GEMINI_API_KEY="${GOOGLE_GENERATIVE_AI_API_KEY}"
fi

# Backward-compatible mapping for older env templates.
if [[ -z "${SANDBOX_DISABLE_WORKSPACE_TEMPLATES:-}" \
  && -n "${SANDBOX_DISABLE_BOOTSTRAP_PROMPTS:-}" ]]; then
  export SANDBOX_DISABLE_WORKSPACE_TEMPLATES="${SANDBOX_DISABLE_BOOTSTRAP_PROMPTS}"
fi

# In messaging channels, suggest mode tends to ask clarifying confirmations
# instead of executing direct action requests (e.g. screenshot tasks).
if is_true "${SANDBOX_FORCE_CHANNEL_FULL_AUTO:-true}" \
  && [[ "${CONFIRMATION_MODE:-suggest}" == "suggest" ]] \
  && [[ -n "${TELEGRAM_BOT_TOKEN:-}" || -n "${DISCORD_BOT_TOKEN:-}" ]]; then
  export CONFIRMATION_MODE="full-auto"
  echo "[entrypoint] CONFIRMATION_MODE forced to full-auto for channel runtime"
fi

# Disable known workspace onboarding/persona templates that hijack task execution.
# Keep user-authored files intact by matching template-specific marker lines.
if is_true "${SANDBOX_DISABLE_WORKSPACE_TEMPLATES:-true}"; then
  disable_workspace_template_file \
    "BOOTSTRAP.md" \
    "You just woke up. Time to figure out who you are." \
    "Hey. I just came online. Who am I? Who are you?"
  disable_workspace_template_file \
    "AGENTS.md" \
    "## First Run" \
    "Before doing anything else:"
  disable_workspace_template_file \
    "SOUL.md" \
    "# SOUL.md - Who You Are" \
    "You're not a chatbot. You're becoming someone."
  disable_workspace_template_file \
    "IDENTITY.md" \
    "# IDENTITY.md - Who Am I?" \
    "Fill this in during your first conversation."
  disable_workspace_template_file \
    "USER.md" \
    "# USER.md - About Your Human" \
    "Learn about the person you're helping. Update this as you go."
  disable_workspace_template_file \
    "TOOLS.md" \
    "# TOOLS.md - Local Notes" \
    "Skills define _how_ tools work."
  disable_workspace_template_file \
    "HEARTBEAT.md" \
    "# HEARTBEAT.md" \
    "Keep this file empty (or with only comments) to skip heartbeat API calls."
fi

# Ensure base config exists and apply safe defaults/migrations.
export CONFIG_PATH STATE_DIR WORKSPACE_DIR
node <<'NODE'
const fs = require("node:fs");
const path = require("node:path");
const crypto = require("node:crypto");

const cfgPath = process.env.CONFIG_PATH;
const workspace = process.env.WORKSPACE_DIR;
const provider = String(process.env.AI_PROVIDER || "openai").trim().toLowerCase();
const browserDefaultProfile =
  String(process.env.BROWSER_DEFAULT_PROFILE || "openclaw").trim() || "openclaw";
const rawBrowserHeadless = String(process.env.BROWSER_HEADLESS || "")
  .trim()
  .toLowerCase();
const rawBrowserNoSandbox = String(process.env.BROWSER_NO_SANDBOX || "")
  .trim()
  .toLowerCase();
const rawSyncEnvModel = String(process.env.OPENCLAW_SYNC_ENV_MODEL || "")
  .trim()
  .toLowerCase();
const rawOpenaiCustomModelEnabled = String(process.env.OPENAI_CUSTOM_MODEL_ENABLED || "")
  .trim()
  .toLowerCase();
const openaiCustomModelApi =
  String(process.env.OPENAI_CUSTOM_MODEL_API || "openai-completions").trim() ||
  "openai-completions";
const openaiBaseUrl = String(process.env.OPENAI_BASE_URL || "").trim();

function parseBool(raw, fallback) {
  if (!raw) {
    return fallback;
  }
  if (["1", "true", "yes", "on"].includes(raw)) {
    return true;
  }
  if (["0", "false", "no", "off"].includes(raw)) {
    return false;
  }
  return fallback;
}

const browserHeadless = parseBool(rawBrowserHeadless, true);
const browserNoSandbox = parseBool(rawBrowserNoSandbox, true);
const syncEnvModel = parseBool(rawSyncEnvModel, false);
const openaiCustomModelEnabled = parseBool(rawOpenaiCustomModelEnabled, false);

function resolveBrowserExecutablePath() {
  const explicit = String(process.env.BROWSER_EXECUTABLE_PATH || "").trim();
  if (explicit && fs.existsSync(explicit)) {
    return explicit;
  }

  const common = [
    "/usr/bin/chromium",
    "/usr/bin/chromium-browser",
    "/usr/bin/google-chrome",
    "/usr/bin/google-chrome-stable",
  ];
  for (const candidate of common) {
    if (fs.existsSync(candidate)) {
      return candidate;
    }
  }

  const msPlaywrightRoot = "/ms-playwright";
  try {
    const dirs = fs
      .readdirSync(msPlaywrightRoot, { withFileTypes: true })
      .filter((d) => d.isDirectory() && d.name.startsWith("chromium-"))
      .map((d) => d.name)
      .sort()
      .reverse();
    for (const dir of dirs) {
      const candidate = path.join(msPlaywrightRoot, dir, "chrome-linux", "chrome");
      if (fs.existsSync(candidate)) {
        return candidate;
      }
    }
  } catch {
    // ignore
  }

  return undefined;
}

function pickModelRef() {
  if (provider === "google") {
    const raw = String(process.env.GOOGLE_GENERATIVE_AI_MODEL || "gemini-3-pro-preview").trim();
    return raw.includes("/") ? raw : `google/${raw}`;
  }
  if (provider === "anthropic") {
    const raw = String(process.env.ANTHROPIC_MODEL || "claude-sonnet-4-5").trim();
    return raw.includes("/") ? raw : `anthropic/${raw}`;
  }
  const raw = String(process.env.OPENAI_MODEL || "gpt-5.1-codex").trim();
  if (raw.includes("/")) {
    if (openaiCustomModelEnabled && !raw.startsWith("openai/")) {
      return `openai/${raw}`;
    }
    return raw;
  }
  return `openai/${raw}`;
}

let cfg = {};
if (fs.existsSync(cfgPath)) {
  try {
    cfg = JSON.parse(fs.readFileSync(cfgPath, "utf8"));
  } catch {
    cfg = {};
  }
}

// Keep gateway auth token stable across restarts/tool calls.
// Runtime auto-generation can race with embedded clients and cause
// "device token mismatch" for browser/gateway tool actions.
if (!cfg.gateway || typeof cfg.gateway !== "object") {
  cfg.gateway = {};
}
if (!cfg.gateway.auth || typeof cfg.gateway.auth !== "object") {
  cfg.gateway.auth = {};
}
const envGatewayToken = String(process.env.OPENCLAW_GATEWAY_TOKEN || "").trim();
const cfgGatewayToken =
  typeof cfg.gateway.auth.token === "string" ? cfg.gateway.auth.token.trim() : "";
const nextGatewayToken = envGatewayToken || cfgGatewayToken || crypto.randomBytes(24).toString("hex");
if (cfg.gateway.auth.mode !== "token" || cfg.gateway.auth.token !== nextGatewayToken) {
  console.log("[entrypoint] Ensured stable gateway auth token (mode=token)");
}
cfg.gateway.auth = {
  ...cfg.gateway.auth,
  mode: "token",
  token: nextGatewayToken,
};

if (!cfg.agents || typeof cfg.agents !== "object") {
  cfg.agents = {};
}
if (!cfg.agents.defaults || typeof cfg.agents.defaults !== "object") {
  cfg.agents.defaults = {};
}
if (!cfg.agents.defaults.workspace) {
  cfg.agents.defaults.workspace = workspace;
}
const pickedModelRef = pickModelRef();
if (syncEnvModel) {
  const currentModel =
    cfg.agents.defaults.model && typeof cfg.agents.defaults.model === "object"
      ? cfg.agents.defaults.model
      : {};
  if (currentModel.primary !== pickedModelRef) {
    console.log(`[entrypoint] Synced agents.defaults.model.primary from env (${pickedModelRef})`);
  }
  cfg.agents.defaults.model = {
    ...currentModel,
    primary: pickedModelRef,
  };
} else if (
  !cfg.agents.defaults.model ||
  typeof cfg.agents.defaults.model !== "object" ||
  !cfg.agents.defaults.model.primary
) {
  cfg.agents.defaults.model = { primary: pickedModelRef };
}

// Backward-compatible config migration:
// OpenClaw schema expects models.providers.openai.models to be an array
// whenever providers.openai exists.
if (
  cfg.models &&
  typeof cfg.models === "object" &&
  cfg.models.providers &&
  typeof cfg.models.providers === "object" &&
  cfg.models.providers.openai &&
  typeof cfg.models.providers.openai === "object" &&
  !Array.isArray(cfg.models.providers.openai.models)
) {
  cfg.models.providers.openai = {
    ...cfg.models.providers.openai,
    models: [],
  };
}

if (openaiCustomModelEnabled) {
  if (!cfg.models || typeof cfg.models !== "object") {
    cfg.models = {};
  }
  if (!cfg.models.providers || typeof cfg.models.providers !== "object") {
    cfg.models.providers = {};
  }
  const existingProvider =
    cfg.models.providers.openai && typeof cfg.models.providers.openai === "object"
      ? cfg.models.providers.openai
      : {};
  const nextBaseUrl =
    openaiBaseUrl || existingProvider.baseUrl || "http://host.docker.internal:1234/v1";
  const nextApi = existingProvider.api || openaiCustomModelApi;
  const nextModels = Array.isArray(existingProvider.models) ? existingProvider.models : [];
  if (existingProvider.baseUrl !== nextBaseUrl || existingProvider.api !== nextApi) {
    console.log(
      `[entrypoint] OPENAI custom model mode enabled (baseUrl=${nextBaseUrl}, api=${nextApi})`,
    );
  }
  cfg.models.providers.openai = {
    ...existingProvider,
    baseUrl: nextBaseUrl,
    api: nextApi,
    models: nextModels,
  };
}

if (!cfg.browser || typeof cfg.browser !== "object") {
  cfg.browser = {};
}
if (!cfg.browser.defaultProfile || typeof cfg.browser.defaultProfile !== "string") {
  cfg.browser.defaultProfile = browserDefaultProfile;
}
if (cfg.browser.headless === undefined) {
  cfg.browser.headless = browserHeadless;
}
if (cfg.browser.noSandbox === undefined) {
  cfg.browser.noSandbox = browserNoSandbox;
}
if (!cfg.browser.executablePath) {
  const detectedExecutablePath = resolveBrowserExecutablePath();
  if (detectedExecutablePath) {
    cfg.browser.executablePath = detectedExecutablePath;
  }
}

const telegramToken = String(process.env.TELEGRAM_BOT_TOKEN || "").trim();
if (telegramToken) {
  const allowed = String(process.env.TELEGRAM_ALLOWED_USER_IDS || "")
    .split(",")
    .map((v) => v.trim())
    .filter(Boolean)
    .map((v) => (/^-?\d+$/.test(v) ? Number(v) : v));

  if (!cfg.channels || typeof cfg.channels !== "object") {
    cfg.channels = {};
  }
  if (!cfg.channels.telegram || typeof cfg.channels.telegram !== "object") {
    cfg.channels.telegram = {};
  }
  cfg.channels.telegram.enabled = true;
  if (!cfg.channels.telegram.dmPolicy) {
    cfg.channels.telegram.dmPolicy = allowed.length ? "allowlist" : "pairing";
  }
  if (allowed.length && (!Array.isArray(cfg.channels.telegram.allowFrom) || !cfg.channels.telegram.allowFrom.length)) {
    cfg.channels.telegram.allowFrom = allowed;
  }
  if (!cfg.channels.telegram.groups || typeof cfg.channels.telegram.groups !== "object") {
    cfg.channels.telegram.groups = { "*": { requireMention: true } };
  }
}

fs.mkdirSync(path.dirname(cfgPath), { recursive: true });
fs.writeFileSync(cfgPath, `${JSON.stringify(cfg, null, 2)}\n`, "utf8");
NODE

# Chromium leaves singleton lock/socket links in persistent profiles.
# After container recreation those links can point to dead PIDs/sockets,
# preventing CDP startup for the managed browser profile.
if [[ -d "${STATE_DIR}/browser" ]]; then
  while IFS= read -r user_data_dir; do
    rm -f \
      "${user_data_dir}/SingletonLock" \
      "${user_data_dir}/SingletonCookie" \
      "${user_data_dir}/SingletonSocket" \
      "${user_data_dir}/DevToolsActivePort"
  done < <(find "${STATE_DIR}/browser" -mindepth 2 -maxdepth 2 -type d -name user-data 2>/dev/null)
fi

# Avoid startup failures on Chromium runtime sockets (SingletonSocket),
# which cannot be chowned on some host filesystems.
if [[ -d "${STATE_DIR}" ]]; then
  find "${STATE_DIR}" -xdev ! -type s -exec chown openclaw:openclaw {} +
fi

exec gosu openclaw "$@"
