---
name: consciouslab-mcp
description: Add a read-only MCP server to a Python app that uses Consciouslab central auth — consciouslab-auth package (bearer verification, RFC 9728 metadata, permission-declaring tools, field redaction, read-only DB), seed server/tests/Makefile, conformance run, address mcp.<app>.consciouslab.io. Use when the user mentions Consciouslab MCP, "app'in verisini Claude/ChatGPT'ye aç", consciouslab-auth, conformance, or a new app MCP service.
---

# consciouslab-mcp

## Ne

Bir Python app'inin verisini, Consciouslab merkezi auth'una bağlı **salt okur MCP sunucusu** olarak açmak: ayrı süreç,
aynı imaj, her istekte soranın token'ı doğrulanır, her araç gerektirdiği izni bildirir, para ve iletişim alanları
modele gitmez. Kit seed olarak çalışan bir iskelet (sunucu, üç örnek araç, testler, uyum testi komutu) kopyalar.
İskelet `consciouslab-auth` paketinin `examples/sample_mcp`'sinden türedi ve Nano'nun MCP'siyle aynı kalıptadır.

## Neyi çözer

Nano ve Umay'da yaşananlar (tahmin değil):

- Token doğrulama her app'te elle yazılınca `aud` kuralı (ikinci `aud`), `typ`, süre ve imza denetimleri atlandı; paket bunu tek yerde tutar.
- MCP'nin DB kullanıcısı yazan kullanıcıyla aynıydı: kod hatası ya da prompt injection veriyi değiştirebilirdi.
- Para (`cost_usd`) ve iletişim (`contact_email`) alanları araç çıktısında modelin sağlayıcısına gitti.
- Araçlar `space` almadığı için marka A'nın kişisi B'yi görebilirdi (app-model "MCP kalıbı").
- "Çalıştı" sözü kanıtsızdı: 401, `WWW-Authenticate`, RFC 9728 belgesi ve izin reddi denenmeden bitti denildi.
- Nano'da para harcayan araç (iş başlatma) eklenirken MCP ↔ API arasına **ortak gizli anahtar** önerildi; gereksizdi.
  Kanıtı Cloud Run servis kimliği zaten veriyor (pano → API'de kullanılıyordu); sır saklamak ve yenilemek boşuna yük (2026-10-28).

## Doğruluk kaynakları

- Kalıp: auth reposunda `docs/canonical/app-model.md` ("MCP kalıbı", "Yeni app bağlama" 7) ve `infrastructure.md` ("Nano MCP").
- Paket: `consciouslab-auth` README'si (modüller, uyum testi). Davranış: MCP spec'i (yetkilendirme) ve RFC 9728.
- **Sürüm, kurulum adresi, bölge, MCP SDK sürümü ve adres kalıbı `kit.yaml` → `facts`'ten okunur**; gövdede sabit değer yok.

## Yöntem

1. **Önce bak.** Repoda Python app'i var mı, `consciouslab-auth` kurulu mu, `mcp_server/` ya da `mcp.mk` çakışıyor mu?
   Merkezden `consciouslab-app` adım 3 (istek issue'su) ve paket kurulumu yapılmadıysa önce onlar.
2. **Kopyala.** Seed dosyaları yaz; `mcp.mk`'i ana Makefile'a `include mcp.mk` ile bağla (Makefile yoksa `mcp.mk`'yi `Makefile` yap).
   `scripts/mcp-conformance.sh` çalıştırılabilir kalmalı.
3. **Yer tutucuları doldur, tahmin etme** (`grep -rn '{{' mcp_server tests_mcp scripts mcp.mk`):
   `{{APP_NAME}}` = auth'taki app adı (küçük harf, tire); `{{MCP_RESOURCE}}` = `https://mcp.<app>.consciouslab.io/mcp`
   (sonradan değişmez); `{{PORT}}` = yerel port (app'in kendi portundan farklı, 8001 gibi). Adı bilmiyorsan kullanıcıya sor.
4. **Kur.** `pip install keyrings.google-artifactregistry-auth`, `gcloud auth application-default login`,
   `pip install -r requirements-mcp.txt`. Yalnız `--index-url` sanal depo; **`--extra-index-url` yasak** (`facts`: `python_index`).
   Sürümü `facts`: `package_version`'la karşılaştır. CI ve Docker kurulumu `consciouslab-app` kit'indedir.
5. **Araçları yaz** (`mcp_server/tools.py`, `KIT-SAMPLE` işaretlerini sil):
   - Ad `list_*`, `get_*`, `search_*`; en fazla ~10 araç; ilk sürüm yalnız `read`. Yazan ya da para harcayan araç bu kit'te yok.
   - `list_spaces` vardır; **her araç `space` alır**, verilmezse kişinin kendi alanı; `visible_spaces()` app-model'in dört kuralını kodlar.
   - Docstring **İngilizce, modele yazılır**: ne yapar, ne yapmaz ("Contact details and money are not available"). Sayfalı listede üst sınır 100.
   - Dönüş `dict[str, Any]`. Araç içinde izin kontrolü yazma; `tool(mcp, "read")` yapar.
   - **Ayıklama listesi app'e özeldir:** `REDACTED_KEYS`'e iletişim, para, çalışan kimliği alanlarını ekle; sorguda hiç seçme.
     Listeyi daraltmak kullanıcı onayı ister.
   - **Dinleme hattı açık seçimdir** (`facts`: `mcp_listen`; auth ADR 0047). Seed kapalı gelir: `MCPServer(..., subscriptions=False)`
     + `build_app(..., listen=False)`. Hat yalnız "araç / prompt / kaynak listesi değişti" ve "kaynak güncellendi" taşır; "iş bitti"
     ya da araç sonucu taşımaz. Açıkken istemci bağlı kaldıkça Cloud Run sunucuyu ücretler (Nano'da ~12–15 $/ay, 300 sn'lik
     akışlar). Yalnız liste **oturum açıkken** değişiyorsa aç (`listen=True`) ve maliyeti kullanıcıya söyle; çoklu kopyada haberin
     her kopyaya gitmesi ayrı yayın altyapısı ister. Yeni sürümle değişen liste için gerekmez (istemci yeniden bağlanınca alır).
6. **Veritabanı** `db.py`: yalnız `MCP_DSN` (ayrı, yalnız SELECT kullanıcı). Yazan DSN'e düşme. Geçici tablo gerekiyorsa
   `cursor(temp_tables=True)` yalnız sabit sorguda. Sorgular parametreli; liste uçlarında `limit`. SQL taraması `consciouslab-app`'te.
7. **Testleri koş:** `make mcp-test`. Kendi araçların için ayıklama ve alan (`space`) testleri ekle: başka alan ⇒ hata.
8. **Uyum testi:** `make mcp-conformance` — hepsi PASS olmadan "bitti" deme. SKIP kanıt değildir; zorunlu argümanlı
   araçlar için betikteki komuta `--tool-args '{"araç": {…}}'` ve `--read-tools` ekle. Çıkış kodu 0 beklenir.
9. **Bitiş kapısı:** `make mcp-check` (test + uyum + `KIT-SAMPLE` yok). Çıktıyı raporla.
10. **Servis ve adres merkezden.** Cloud Run servisi, alan eşlemesi, DB kullanıcısı ve auth'ta MCP alt kaynağı **merkez isteğiyle**
    (`consciouslab-app` adım 3) yapılır; bu repoya altyapı yazılmaz. İmaj `mcp_server/`'ı içermeli, komut `python -m mcp_server.app`
    (ilk imaj MCP kodsuz giderse servis açılmaz). Cloud Run'da `MCP_RESOURCE` ve `AUTH_ISSUER` env'i, adres `{{MCP_RESOURCE}}`.
11. **Para harcayan araç (`spend`) gerekiyorsa** (Nano ADR-0036 kalıbı; kullanıcı ayrıca istemeli; `facts`: `spend_tool_pattern`):
    - MCP'nin DB kullanıcısı **salt okur kalır**; işi app'in API'si başlatır, arayüzün kullandığı **aynı çekirdekle** (ikinci kapı yok).
    - Kişinin token'ı API'ye **taşınmaz** (`aud` MCP'nin). MCP doğruladığı kişiyi (`sub`, `role`, `permissions`, `client_id`,
      `act_sub`) gövdede bildirir; API yetkiyi **yeniden** denetler (`spend` + rol + aktif kişi).
    - "İstek gerçekten MCP'den mi?" → **ortak sır YOK** (`facts`: `service_to_service_identity`): API herkese kapalı, MCP
      kimliğine `run.invoker`; MCP kimlik kartını `X-Serverless-Authorization`'a koyar; API yükteki `email`'i beklenen MCP
      kimliğiyle karşılaştırır (ikinci kilit). Cloud Run'da (`K_SERVICE` dolu) bu ayar yoksa uç kapalı.
    - Tavan = kullanıcının önizlemede gördüğü rakam; araç onu parametre alır, o arada yükseldiyse iş açılmaz.
    - Para alanları yalnız `spend` araçlarında açık. Sır yalnız **kimliği olmayan** taraf için (tarayıcıdan açılan süreli indirme linki, HMAC).
12. **Canlı doğrulama:** `curl <adres kökü>/.well-known/oauth-protected-resource` (`resource` adresle birebir),
    `curl -i <adres>` 401 + `WWW-Authenticate`; sonra Anıl panelden bağlar.

## Araçlar

`python` ≥ 3.11, `pip`, `gcloud` (ADC), `make`, `consciouslab-auth` paketi (`[mcp,db]`), `uvicorn`, `pytest`, `gh` (merkez isteği).
Salt okur DB'ye bağlanmak için yerel Postgres (`local-env` kit'i). Sır yazılmaz; DSN ortamdan gelir.

## Sınırlar

- Yalnız Python. Başka dilde MCP için paket yok: merkezden iste, kendin yazma.
- Seed yalnız okuma araçları kurar. `spend` kalıbı Yöntem 11'de (çalışan örnek: Nano `apps/mcp/api_client.py`,
  `apps/api/main.py` `/internal/mcp/search`). `write` araçları için kalıp henüz yaşanmadı.
- Altyapı, DNS, panel kaydı, Claude/ChatGPT bağlayıcısı kapsam dışı (merkez ve Anıl).
- Müşteri alanı olan app'te alan kuralları kapsam tavanı gerektirir; bu kit onu çözmez (spec'te "yapılmayacak").
- Seed'in `visible_spaces()` ve örnek verisi yalnız iskelettir; gerçek alan kuralı app'e göre yazılır.
- Docker/CI kurulum tarifi ve yerel auth-core ile uçtan uca deneme bu kit'te değil.
