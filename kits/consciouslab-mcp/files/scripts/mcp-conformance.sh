#!/usr/bin/env bash
# Uyum testi (consciouslab-auth paketi): app'i test issuer'a bağlı başlatıp 17 denetimi koşar.
# FAIL varsa çıkış 1. SKIP kanıt değildir. Ayarlar ortamdan: MCP_PORT, MCP_EXPECT_REDACTED.
set -euo pipefail
cd "$(dirname "$0")/.."

PORT="${MCP_PORT:-{{PORT}}}"
PYTHON="${PYTHON:-python}"

exec "$PYTHON" -m consciouslab_auth.conformance \
  --mcp "http://127.0.0.1:${PORT}/mcp" \
  --expect-redacted default \
  --issuer-port 0 \
  --env "PORT=${PORT}" \
  --start "$PYTHON -m mcp_server.app"
