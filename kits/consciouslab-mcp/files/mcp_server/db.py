"""MCP sürecinin salt okur veritabanı bağlantısı (tembel: kullanılmadıkça psycopg istemez).

🔴 Yalnız `MCP_DSN` okunur: canlıda bu, yalnız SELECT yetkili ayrı kullanıcıdır. App'in yazan
DSN'ine (`DATABASE_URL` vb.) ASLA düşülmez. Geçici tablo gerekiyorsa `cursor(temp_tables=True)`
yalnız SABİT sorgularda kullanılır (paketin `db.py` açıklaması).

Araçta kullanım:

    with get_database().cursor() as cur:
        cur.execute("select id, name from items where space_id = %s order by id limit %s", (space, limit))
        rows = cur.fetchall()          # dict satırlar
"""
from __future__ import annotations

import os

_database = None


def get_database():
    """İlk çağrıda havuzu kurar. `consciouslab-auth[db]` eki gerekir."""
    global _database
    if _database is None:
        dsn = os.environ.get("MCP_DSN", "").strip()
        if not dsn:
            raise RuntimeError("MCP_DSN tanımlı değil (salt okur kullanıcı DSN'i)")
        from consciouslab_auth.db import ReadOnlyDatabase

        _database = ReadOnlyDatabase(dsn, application_name="{{APP_NAME}}-mcp", statement_timeout_s=15)
    return _database


def close_database() -> None:
    global _database
    if _database is not None:
        _database.close()
        _database = None
