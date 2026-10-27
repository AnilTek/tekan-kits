# tekan-kits

Projeden projeye taşınan, uygulanabilir know-how. Her kit bir klasördür; Tekan bu repoyu okur ve kit'i
bir projeye diff → onay → PR olarak uygular. Tekan kullanmayan biri de kit'in `SKILL.md`'sini
([Agent Skills](https://agentskills.io/) formatı) kendi agent'ına verebilir.

## Kit'ler

| Kit | Tür | Sürüm | Ne yapar |
|---|---|---|---|
| [consciouslab-app](kits/consciouslab-app/) | workflow | 0.1.0 | Yeni/taşınan app'i Consciouslab merkezi auth'una bağlama: adımlar, kim yapar, kapılar, uyum testi, panel kaydı |
| [consciouslab-mcp](kits/consciouslab-mcp/) | setup | 0.1.0 | Python app'ine salt okur MCP sunucusu iskeleti: izinli araçlar, alan ayıklama, uyum testi (`consciouslab-auth` paketi) |
| [consciouslab-hermes](kits/consciouslab-hermes/) | setup | 0.1.0 | Bir Hermes profiline `cl-hermes` kurulumu: profil başına ayar, anahtar, panel kaydı, DM-only `/baglan` |
| [docs-os](kits/docs-os/) | setup | 1.1.0 | AGENTS.md router, docs/ slotları, doc-guard CI |
| [local-env](kits/local-env/) | setup | 2.0.0 | `env-up`/`env-down`/`db-reset`/`dev`/`check`, `*_BASE_URL` mock'ları; Postgres şablonu, başka stack'e uyarlanır |
| [railway](kits/railway/) | setup | 1.0.0 | Railway IaC (`.railway/railway.ts`), healthcheck, pre-deploy migration, ortam-dal eşlemesi |
| [apify](kits/apify/) | knowledge | 1.0.0 | Actor çalıştırma: bütçe kapısı, gerçek maliyet, sessiz eksik veri, actor seçimi |
| [elevenlabs](kits/elevenlabs/) | knowledge | 1.0.0 | Scribe STT ve TTS: iki kez ödememe, önbellek, onaylı ücretli çalıştırma |
| [gemini](kits/gemini/) | knowledge | 1.0.0 | google-genai ile Gemini API / Vertex: kimlik, bölge, düşünme token'ı maliyeti, 429 |
| [google-oauth-login](kits/google-oauth-login/) | knowledge | 1.0.0 | Domain'e kısıtlı Google girişi: `hd` + `email_verified`, redirect, çerez, bootstrap admin |
| [google-trends](kits/google-trends/) | knowledge | 1.0.0 | 0–100 indeksini doğru okuma, karşılaştırılabilir çekim, kaynak seçimi |
| [openrouter](kits/openrouter/) | knowledge | 1.0.1 | LLM çağrısında gerçek maliyet, harcama tavanları, retry, yedek model, JSON güvenilirliği |
| [resend](kits/resend/) | knowledge | 1.0.1 | İşlem e-postası: domain doğrulama, idempotency, yerelde Mailpit |
| [supabase](kits/supabase/) | knowledge | 1.0.1 | Backend'den Supabase: anahtar rolleri, JWT doğrulama, RLS, pooler, migration kayması |
| [youtube-data-api](kits/youtube-data-api/) | knowledge | 1.0.1 | YouTube Data API v3: kanal çözme, keşif, kota kovaları |

## Bir kit'in yapısı

```
kits/<id>/
  SKILL.md       agent'ın okuduğu talimat: ne, neyi çözer, kaynaklar, yöntem, araçlar, sınırlar (≤ 150 satır)
  kit.yaml       tür, sürüm, ihtiyaçlar, dosya listesi ve kipleri, kaynaklı olgular
  files/         projeye kopyalanan dosyalar
  CHANGELOG.md   her sürümde ne değişti, neden
```

**Kit türleri:** `knowledge` (bir servisi nasıl kullanırız) · `setup` (projeye dosya ve kural kurar) ·
`workflow` (adımlar; başka kit'leri sırayla uygular).

**Dosya kipleri:**

| Kip | Anlamı | Güncellemede |
|---|---|---|
| `managed` | Kit'in malı; her projede aynı bayt, değişken içermez | Yeni sürüm gelir. Projede elle değiştirildiyse üzerine yazılmaz, fark sorulur |
| `seed` | Bir kez kopyalanır, sonra projenin malıdır | Dokunulmaz |

Projede hangi kit'in hangi sürümünün uygulandığı `.tekan/kits.json`'da durur.

## Katkı

Kit'i projede değil burada düzelt: PR aç, `CHANGELOG.md`'ye yaz, `kit.yaml`'daki `version`'ı artır
(managed dosya değiştiyse minor, kural kaldırıldıysa major).
