"""{{APP_NAME}} MCP araçları.

Kurallar (consciouslab-mcp kit'i):
  - İlk sürüm yalnız okuma; en fazla ~10 araç; ad `list_*`, `get_*`, `search_*`.
  - `list_spaces` vardır; her araç `space` alır, verilmezse kişinin kendi alanı kullanılır.
  - Docstring modele AÇIKLAMA olarak gider: İngilizce, ne yaptığını ve ne YAPMADIĞINI söyler.
  - Dönüş türü `dict[str, Any]` (yapılandırılmış çıktı). Para ve iletişim alanları REDACTED_KEYS ile
    her derinlikte silinir; sorguda zaten seçilmemesi daha iyidir.
  - İzin `tool(mcp, "read")` ile bildirilir ve merkezi kontrol edilir; araç içinde ayrıca kontrol yazılmaz.

🔴 `KIT-SAMPLE` işaretli her şey örnektir: gerçek veri ve alan kuralıyla DEĞİŞTİRİLİR, işaret silinir
(`make mcp-sample-check` işaret kaldıysa kırmızıdır).
"""
from __future__ import annotations

from typing import Any

from consciouslab_auth.mcp import current_claims, tool
from consciouslab_auth.redaction import DEFAULT_REDACTED_KEYS
from mcp.server.mcpserver import MCPServer

# Modele gitmeyecek alanlar. Varsayılan Nano'nun kümesidir; app'in kendi alanlarını ekle
# (ör. DEFAULT_REDACTED_KEYS | {"iban"}). Kümeyi daraltma kararı ayrı onay ister.
REDACTED_KEYS = DEFAULT_REDACTED_KEYS | frozenset()

MAX_LIMIT = 100

# KIT-SAMPLE: gerçek veri db.get_database() ile gelir (bkz. mcp_server/db.py).
SAMPLE_ITEMS = [
    {"id": 1, "name": "Alfa", "contact_email": "alfa@example.test", "cost_usd": 12.5},
    {"id": 2, "name": "Beta", "contact_email": "beta@example.test", "cost_usd": 3.0},
]


def visible_spaces() -> list[dict[str, Any]]:
    """Token'daki kişinin görebildiği alanlar; `default` kişinin kendi alanıdır.

    KIT-SAMPLE: app-model.md dört kuralı burada kodlanır: kuruluş alanı (claims.org_id), kişisel
    alan (claims.sub; app ayarı `internal`/`all` ise), Consciouslab çalışanı müşteri alanlarını da
    görür, agent soranın gördüğünü görür. Alan listesi app'in kendi tablosundan gelir.
    """
    claims = current_claims.get()
    assert claims is not None  # tool() sarmalayıcısı token'sız çağrıyı zaten reddetti
    return [{"id": "main", "name": "Main", "default": True}]


def resolve_space(space: str | None) -> str:
    """`space` verilmediyse kişinin kendi alanı; erişimi olmayan alan hata verir."""
    spaces = visible_spaces()
    chosen = space or next(item["id"] for item in spaces if item["default"])
    if chosen not in {item["id"] for item in spaces}:
        raise ValueError("Unknown space or no access. Call list_spaces first.")
    return chosen


def register(mcp: MCPServer) -> None:
    """Araçları verilen sunucuya kaydeder."""

    @tool(mcp, "read", redacted_keys=REDACTED_KEYS)
    def list_spaces() -> dict[str, Any]:
        """List the spaces you can read. Call this first; every other tool takes a space."""
        return {"spaces": visible_spaces()}

    @tool(mcp, "read", redacted_keys=REDACTED_KEYS)
    def list_items(space: str | None = None, limit: int = 20) -> dict[str, Any]:
        """List items in a space, newest first. Contact details and money are not available."""
        resolve_space(space)
        limit = max(1, min(limit, MAX_LIMIT))
        return {"items": SAMPLE_ITEMS[:limit]}  # KIT-SAMPLE

    @tool(mcp, "read", redacted_keys=REDACTED_KEYS)
    def get_item(item_id: int, space: str | None = None) -> dict[str, Any]:
        """Get one item by id from a space. Contact details and money are not available."""
        resolve_space(space)
        found = next((item for item in SAMPLE_ITEMS if item["id"] == item_id), None)  # KIT-SAMPLE
        if found is None:
            raise ValueError("Item not found in this space.")
        return {"item": found}
