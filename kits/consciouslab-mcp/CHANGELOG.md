# consciouslab-mcp — değişiklik günlüğü

## 0.1.0 — 2026-10-27

İlk sürüm (ön sürüm: `consciouslab-auth` paketi de `0.1.0rc1`). `consciouslab-auth` paketinin `examples/sample_mcp`'sinden ve Nano'nun
MCP'sinden (araç adları, `space` kalıbı, salt okur DB, ayıklama listesi) türedi; kalıbın gerekçeleri auth reposunda
(`nano-mcp-agents`, `app-integration-kit` spec'leri).

- Seed: `mcp_server/` (sunucu, araçlar, tembel salt okur DB), `tests_mcp/` (test issuer'lı auth sözleşmesi testleri),
  `mcp.mk` + `scripts/mcp-conformance.sh` (uyum komutu), `requirements-mcp.txt` (tek sanal depo, tam sürüme sabit).
- Yer tutucular: `{{APP_NAME}}`, `{{MCP_RESOURCE}}`, `{{PORT}}`; Tekan yalnız `{{PROJECT_NAME}}`/`{{TODAY}}` doldurur, gerisini agent.
- `KIT-SAMPLE` işareti: örnek veri kalırsa `make mcp-sample-check` kırmızı.
- Olgular auth reposu belgelerinden ve Artifact Registry belgesinden alındı (2026-10-27). Kapsam: yalnız Python, yalnız okuma.
- Doğrulama (P4, 2026-10-27): boş repoda yer tutucular doldurulup `make mcp-test` (9 test geçti) ve `make mcp-conformance` (17 PASS, 0 FAIL, 0 SKIP) koşuldu.
  Doğrulanamadı: paket Artifact Registry'den kurulamadı (gcloud ADC süresi dolmuştu); aynı sürüm (`0.1.0rc1`) yerel kaynaktan kuruldu.
  `requirements-mcp.txt`'in sanal depodan çözülmesi bu yüzden denenmedi.
