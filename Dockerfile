ARG NODE_VERSION=22.22.0
ARG OPENCLAW_REF=v2026.2.15
ARG PLAYWRIGHT_IMAGE_TAG=v1.58.2-noble

FROM node:${NODE_VERSION}-bookworm-slim AS builder

ARG OPENCLAW_REF
ARG OPENCLAW_REPO=https://github.com/openclaw/openclaw.git

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    git \
    python3 \
    ffmpeg \
  && rm -rf /var/lib/apt/lists/*

RUN npm install -g bun@1.3.1

WORKDIR /build

RUN git clone --depth 1 --branch "${OPENCLAW_REF}" "${OPENCLAW_REPO}" openclaw

WORKDIR /build/openclaw

RUN bun install --frozen-lockfile && bun run build:prod

FROM mcr.microsoft.com/playwright:${PLAYWRIGHT_IMAGE_TAG}

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
    gosu \
    python3 \
    tini \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=builder /build/openclaw/dist ./dist
COPY --from=builder /build/openclaw/dist/package.json ./package.json

RUN npm install --omit=dev --omit=optional && npm cache clean --force

RUN groupadd --gid 10001 openclaw \
  && useradd --uid 10001 --gid 10001 --create-home --shell /bin/bash openclaw \
  && mkdir -p \
    /home/openclaw/.openclaw/storage \
    /home/openclaw/.openclaw/browser-profile \
    /home/openclaw/.openclaw/workspace \
  && chown -R openclaw:openclaw /app /home/openclaw

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENV NODE_ENV=production \
    AGENT_STORAGE_PATH=/home/openclaw/.openclaw/storage/agent.json \
    SQLITE_DB_PATH=/home/openclaw/.openclaw/storage/memory.db \
    BROWSER_PROFILE_PATH=/home/openclaw/.openclaw/browser-profile \
    WORKSPACE_PATH=/home/openclaw/.openclaw/workspace

ENTRYPOINT ["tini", "--", "/usr/local/bin/docker-entrypoint.sh"]
CMD ["node", "dist/index.js"]
