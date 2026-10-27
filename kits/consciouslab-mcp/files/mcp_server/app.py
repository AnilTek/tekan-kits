"""{{APP_NAME}} MCP sunucusu: Consciouslab merkezi auth'una bağlı, salt okur kaynak sunucusu.

Ortam:
  AUTH_ISSUER   merkezi auth (yerelde http://localhost:3000 ya da uyum testinin issuer'ı)
  MCP_RESOURCE  bu servisin kendi adresi = token'ın beklenen `aud`'u. Canlıda {{MCP_RESOURCE}}
                (sonradan değişmez); yerelde verilmezse http://127.0.0.1:$PORT/mcp
  MCP_DSN       salt okur veritabanı kullanıcısının DSN'i (app'in yazan DSN'i DEĞİL)
  PORT          varsayılan {{PORT}}

Çalıştırma: `python -m mcp_server.app` (repo kökünden). Uyum testi: `make mcp-conformance`.
"""
from __future__ import annotations

import os
from contextlib import asynccontextmanager

from consciouslab_auth.mcp import build_app
from consciouslab_auth.tokens import TokenVerifier
from mcp.server.mcpserver import MCPServer

from mcp_server.db import close_database
from mcp_server.tools import register

DEFAULT_PORT = "{{PORT}}"


@asynccontextmanager
async def lifespan(_app):
    """Süreç kapanırken salt okur havuzu kapatılır."""
    try:
        yield
    finally:
        close_database()


def create_app():
    """Starlette uygulaması. AUTH_ISSUER ya da MCP_RESOURCE eksikse açılışta adıyla düşer."""
    port = os.environ.get("PORT", DEFAULT_PORT)
    os.environ.setdefault("MCP_RESOURCE", f"http://127.0.0.1:{port}/mcp")
    verifier = TokenVerifier.from_env("MCP_RESOURCE", strict_audience=True)
    mcp = MCPServer("{{APP_NAME}}-mcp", instructions="Read-only access to {{APP_NAME}} data.")
    register(mcp)
    return build_app(mcp, verifier=verifier, lifespan=lifespan)


if __name__ == "__main__":
    import uvicorn

    # Cloud Run PORT'u verir ve dış arayüzü bekler; yerelde yalnız loopback yeter.
    host = "0.0.0.0" if os.environ.get("K_SERVICE") else "127.0.0.1"
    uvicorn.run(create_app(), host=host, port=int(os.environ.get("PORT", DEFAULT_PORT)))
