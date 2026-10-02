FROM node:20-bookworm-slim

RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl tar unzip openssl procps \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY package.json ./
RUN npm install --omit=dev --no-audit --no-fund
COPY index.js ./

# Pre-download sing-box
ARG SB_VER=1.11.15
RUN mkdir -p /opt/seed \
 && (curl -fsSL "https://github.com/SagerNet/sing-box/releases/download/v${SB_VER}/sing-box-${SB_VER}-linux-amd64.tar.gz" -o /tmp/sb.tgz \
      && tar -xzf /tmp/sb.tgz -C /tmp \
      && cp /tmp/sing-box-${SB_VER}-linux-amd64/sing-box /opt/seed/sing-box \
      && chmod +x /opt/seed/sing-box ) \
 || echo "sing-box prefetch skipped (will download at runtime)"; \
 rm -rf /tmp/sb.tgz /tmp/sing-box-*

# ====================== ENTRYPOINT اجباری ======================
RUN printf '#!/bin/sh\n\
mkdir -p "$BK_DATA_DIR/bin"\n\
if [ -f /opt/seed/sing-box ] && [ ! -f "$BK_DATA_DIR/bin/sing-box" ]; then cp /opt/seed/sing-box "$BK_DATA_DIR/bin/sing-box"; chmod +x "$BK_DATA_DIR/bin/sing-box"; fi\n\
exec node /app/index.js\n' > /entrypoint.sh \
 && chmod +x /entrypoint.sh

# ====================== تنظیمات سگا + NeoTenet ======================
ENV NODE_ENV=production \
    PORT=2705 \
    BK_DATA_DIR=/data \
    EDGE_TLS=1 \
    EXTERNAL_PORT=443 \
    ENABLE_HYSTERIA2=0 \
    ENABLE_SHADOWTLS_VLESS=0 \
    ENABLE_SS=0 \
    ENABLE_VLESS_GRPC=0

EXPOSE 2705
CMD ["/entrypoint.sh"]
