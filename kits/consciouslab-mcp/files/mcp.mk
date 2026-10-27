# consciouslab-mcp kit'i. Ana Makefile'a `include mcp.mk` eklenir (yoksa kopyala, değiştirme).
# Gerekli: python ≥ 3.11, `pip install -r requirements-mcp.txt` (Artifact Registry kimliği için README: kit SKILL.md).
MCP_PORT ?= {{PORT}}
PYTHON ?= python

.PHONY: mcp-dev mcp-test mcp-conformance mcp-sample-check mcp-check

# Yerelde çalıştır (AUTH_ISSUER verilmeli: auth-core `pnpm dev` ya da uyum testi issuer'ı).
mcp-dev:
	PORT=$(MCP_PORT) $(PYTHON) -m mcp_server.app

mcp-test:
	$(PYTHON) -m pytest tests_mcp

# Uyum testi: test issuer açar, app'i AUTH_ISSUER ile başlatır, denetler, kapatır. Çıkış 0 = bitti denebilir.
mcp-conformance:
	bash scripts/mcp-conformance.sh

# Örnek veri ve KIT-SAMPLE işaretleri gerçeğiyle değiştirilmeden "bitti" denmez.
mcp-sample-check:
	@! grep -rn --include="*.py" "KIT-SAMPLE" mcp_server || (echo "KIT-SAMPLE işaretleri kaldı: örnek veriyi gerçeğiyle değiştir" && exit 1)

mcp-check: mcp-test mcp-conformance mcp-sample-check
