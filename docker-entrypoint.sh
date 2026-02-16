#!/usr/bin/env bash
set -euo pipefail

STATE_DIR="${OPENCLAW_STATE_DIR:-/home/openclaw/.openclaw}"
CONFIG_PATH="${OPENCLAW_CONFIG_PATH:-${STATE_DIR}/openclaw.json}"
WORKSPACE_DIR="${WORKSPACE_PATH:-${STATE_DIR}/workspace}"

mkdir -p \
  "${STATE_DIR}" \
  "${STATE_DIR}/browser" \
  "${WORKSPACE_DIR}"

# Backward-compatible mapping for older env templates.
if [[ -z "${GEMINI_API_KEY:-}" && -n "${GOOGLE_GENERATIVE_AI_API_KEY:-}" ]]; then
  export GEMINI_API_KEY="${GOOGLE_GENERATIVE_AI_API_KEY}"
fi

# Ensure base config exists and apply safe defaults/migrations.
export CONFIG_PATH STATE_DIR WORKSPACE_DIR
node <<'NODE'
const fs = require("node:fs");
const path = require("node:path");

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
  return raw.includes("/") ? raw : `openai/${raw}`;
}

let cfg = {};
if (fs.existsSync(cfgPath)) {
  try {
    cfg = JSON.parse(fs.readFileSync(cfgPath, "utf8"));
  } catch {
    cfg = {};
  }
}

if (!cfg.agents || typeof cfg.agents !== "object") {
  cfg.agents = {};
}
if (!cfg.agents.defaults || typeof cfg.agents.defaults !== "object") {
  cfg.agents.defaults = {};
}
if (!cfg.agents.defaults.workspace) {
  cfg.agents.defaults.workspace = workspace;
}
if (
  !cfg.agents.defaults.model ||
  typeof cfg.agents.defaults.model !== "object" ||
  !cfg.agents.defaults.model.primary
) {
  cfg.agents.defaults.model = { primary: pickModelRef() };
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

chown -R openclaw:openclaw "${STATE_DIR}"

exec gosu openclaw "$@"
