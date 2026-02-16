ARG NODE_VERSION=22.22.0
ARG OPENCLAW_REF=v2026.2.15
ARG PLAYWRIGHT_IMAGE_TAG=v1.58.2-noble

FROM mcr.microsoft.com/playwright:${PLAYWRIGHT_IMAGE_TAG}

ARG OPENCLAW_REF
ARG OPENCLAW_REPO=https://github.com/openclaw/openclaw.git

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    ffmpeg \
    git \
    gosu \
    python3 \
    tini \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY openclaw-patches /tmp/openclaw-patches

RUN git clone --depth 1 --branch "${OPENCLAW_REF}" "${OPENCLAW_REPO}" .
RUN set -eux; \
  if [ -d /tmp/openclaw-patches ]; then \
    for patch_file in /tmp/openclaw-patches/*.patch; do \
      [ -f "${patch_file}" ] || continue; \
      git apply --recount "${patch_file}"; \
    done; \
  fi

RUN corepack enable \
  && corepack prepare pnpm@10.23.0 --activate \
  && pnpm install --frozen-lockfile \
  && pnpm build \
  && OPENCLAW_PREFER_PNPM=1 pnpm ui:build

RUN groupadd --gid 10001 openclaw \
  && useradd --uid 10001 --gid 10001 --create-home --shell /bin/bash openclaw \
  && mkdir -p \
    /home/openclaw/.openclaw \
    /home/openclaw/.openclaw/browser \
    /home/openclaw/.openclaw/workspace \
  && chown -R openclaw:openclaw /app /home/openclaw

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENV HOME=/home/openclaw \
    NODE_ENV=production \
    OPENCLAW_STATE_DIR=/home/openclaw/.openclaw \
    OPENCLAW_CONFIG_PATH=/home/openclaw/.openclaw/openclaw.json \
    WORKSPACE_PATH=/home/openclaw/.openclaw/workspace

ENTRYPOINT ["tini", "--", "/usr/local/bin/docker-entrypoint.sh"]
CMD ["node", "dist/index.js", "gateway", "--allow-unconfigured"]
