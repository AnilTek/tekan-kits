---
name: consciouslab-app
description: Connect a NEW or MIGRATING app to Consciouslab central auth, A to Z, run by the app repo's own agent — three app-model questions, central request issue, OIDC login (@consciouslab/auth, Next.js), API token verification (consciouslab-auth, Python), role mapping, removing own user management, SQL audit, MCP, Hermes, conformance gate, panel registration, release. Use when the user mentions Consciouslab auth, merkezi auth, "app'i auth'a bağla", ADR 0035, a new Consciouslab app, or moving an app off its own login.
---

# consciouslab-app

## Ne

Yeni ya da taşınan bir app'in **kendi reposunda, kendi agent'ıyla** merkezi auth'a bağlanması için adım adım akış. Her adımda
**kim** yapar ve **kapı** (geçilmeden ilerlenmez) yazılıdır. Kim: **App agent'ı** (bu repo) · **Merkez isteği** (issue açılır,
Anıl onaylar, merkez uygular; bu repo merkeze kod yazmaz) · **Anıl** (panelde). Bu bir iş akışıdır; MCP ve Hermes işi ayrı kit'lerdedir.

## Neyi çözer

Nano'nun taşınmasında ve Umay/Alp kurulumunda yaşananlar:

- Kimlik ve rol app'in kendi tablosundaydı; çıkan çalışan ya da değişen rol iki yerde güncellendi. Kural: kişi/rol/davet yalnız panelde, app rolü token'dan okur (ADR 0035).
- Her app giriş ve token doğrulamayı kopyaladı; `aud`, yenileme token'ı zinciri (ikinci kullanım zinciri iptal eder) ve `userinfo` hataları tekrar tekrar çıktı. Çözüm sürümlü paket.
- Railway'in güçlü işlemcisi kötü SQL'i gizliyordu; ortak küçük sunucuda iş 30+ dk, sayfa 2-3 sn oldu (eksik indeks, N+1, her istekte tüm tablo).
- Servis yokken deploy adımı kırıldı; ilk imaj MCP kodsuz gidince MCP servisi açılmadı.
- "Çalıştı" sözü kanıtsızdı: giriş, rol, MCP ve token reddi gerçek tarayıcıda ve uyum testinde denenmeden bitti denildi.

## Doğruluk kaynakları

- Auth reposu: `docs/canonical/app-model.md` ("Yeni bir app için üç soru", "Yeni app bağlama", "MCP kalıbı"), `infrastructure.md`
  ("Ortak paketler", "Nano'nun Cloud Run kaynakları"), ADR 0035, 0038, 0042. Paket README'leri (Python, TS).
- Paket sürümü, kurulum adresleri, bölge, issue şablonu, adres kalıpları **`kit.yaml` → `facts`'ten okunur**; gövdede sabit değer yok.

## Yöntem

1. **Üç soru** (app agent'ı + kullanıcı). (a) Alan neyin karşılığı? (b) Müşteri alanı var mı (dışarıya açıksa ADR 0007 kontrol
   listesi: `org_id` + RLS + CI testi)? (c) Kişisel alan kimlere: `off` / `internal` / `all`? Taşıma ise: mevcut kullanıcı/rol yapısı ve
   `viewer` için salt okur davranışı. **Kapı:** cevaplar yazılı.
2. **App'in spec'i** (app agent'ı). Repo kendi spec yerinde (`docs/intent/<iş>.md` gibi) alan modeli, rol eşlemesi, MCP araç listesi,
   taşıma günü planı. **Kapı:** kullanıcı spec'i açıkça onayladı; onaysız kod yok.
3. **Merkez isteği** (app agent'ı açar, Anıl onaylar). Issue'yu `gh issue create -R AnilTek/Consciouslab-Auth` ile aç; şablon
   `new-app.yml` (`facts`: `request_template`). `--template new-app.yml` yml formlarda çalışmayabilir (`gh` bunu doğrulanmadı):
   çalışmazsa şablondaki alan başlıklarını `### Alan adı` biçiminde `--body-file` ile yaz, `--label area:app-gecisi` ver. Alanlar:
   ad, adres, yeni/taşınan, kimler girer, varsayılan rol, alan modeli, Cloud Run servisleri (api/pano/mcp/job), veritabanı, SQL
   taraması, MCP araçları ve ayıklanan alanlar, Hermes profili, repo adı (WIF `app_repositories`). **Kapı:** issue numarası spec'e
   yazıldı; merkez DNS, veritabanı, Cloud Run, GCP güveni ve (geliştirme için) yerel auth seed'ini yapana kadar altyapı beklenir.
4. **Yerel ortam** (app agent'ı). `local-env` kit'iyle (Postgres prod'la aynı major). API ve MCP testleri auth-core'suz **TestIssuer**
   ile (`consciouslab-auth` Python paketi). Uçtan uca giriş için auth-core'u auth reposundan Anıl'ın makinesinde (`pnpm env-up && pnpm dev`,
   adres `http://localhost:3000`) kullan; app'in yerel istemcisi merkezde seed'lenir (adım 3'ün parçası). **Kapı:** `AUTH_ISSUER` ile app açılıyor.
5. **Paket kurulumu** (app agent'ı) — tarif `facts`: `python_install`, `npm_install`:
   - Python: **yalnız `--index-url` sanal depo** (`--extra-index-url` yasak), tam sürüme sabit (`==`). Yerelde
     `gcloud auth application-default login` + `keyrings.google-artifactregistry-auth`. Hesabın okuyucu grubunda olması merkez işidir.
   - **CI (her PR ve branch):** `permissions: id-token: write`, `google-github-actions/auth` ile WIF; sağlayıcı `vars.GCP_WIF_PROVIDER`,
     okuma kimliği `vars.GCP_PACKAGES_READER_SA` (merkez bu değerleri verir). `<app>-deploy` kimliği yalnız `main`'e bağlıdır, test için kullanılmaz.
   - **Docker:** imajda kimlik bilgisi yok. Workflow'da kimlik varken `pip download --no-deps -d vendor/ … consciouslab-auth==<sürüm>`
     (npm: `npm pack @consciouslab/auth@<sürüm>`), Dockerfile yerel dosyadan kurar, `vendor/` `.gitignore`'da. Sürüm tek yerde.
   - npm: `.npmrc`'de yalnız `@consciouslab:` kapsamı bizim depoya; `npx google-artifactregistry-auth` kimliği yazar (commit edilmez).
6. **Giriş (Next.js)** — `@consciouslab/auth`: `createAuthConfig` + `createOidcClient`, `proxy.ts` (token yenilemenin **tek** yeri),
   `getServerTokens` yalnız okur. Token yalnız sunucuda; `session` yanıtına token girmez, kimlik (ad, e-posta, rol) girer. PKCE, `resource`,
   `offline_access`, giriş düğmesi yok (panelden geçiş). **Kapı:** tip kontrolü ve app testleri yeşil.
7. **API token doğrulama (Python)** — `TokenVerifier`, `claims_dependency`, `require_permission`. Token'ı API'nin kendisi doğrular
   (pano'nun söylediğine güvenme); `aud` = app adresi. Kodda elle JWT çözme yazma.
8. **Rol eşleme.** Token `role`/`permissions` → app rolü (`mapRole`); bilinmeyen her şey `viewer` (salt okur). Rol arayüzü sadeleştirir,
   asıl yetki API'de.
9. **Kendi kullanıcı yönetimini kaldır** (ADR 0035): kişi/davet/rol/şifre ekranları, kullanıcı tablosu yazımı, ortak sır. **Kapı:** app'te
   kullanıcı oluşturan kod yolu kalmadı (`grep`); kimlik yalnız token'dan.
10. **SQL taraması (ortak veritabanından ÖNCE, zorunlu).** Kod: tüm SQL/view/indeks envanteri; indekssiz koşul (ifade indeksi dahil),
    döngüde sorgu (N+1), her istekte tüm tablo, açık kalan işlem, gereksiz büyük `jsonb`, satır satır yazma. Ölçüm: prod'un **maskeli**
    kopyası, hedef boyuna kısıtlı konteyner (`--cpus`, `--memory`), `pg_stat_statements` + `EXPLAIN`, tüm okuma uçları, 4 eşzamanlı
    kullanıcı. Her bağlantı `statement_timeout`, `idle_in_transaction_session_timeout`, `application_name` ile açılır. Önce/sonra rakamı
    ve çıktının değişmediği kanıtıyla rapor; sunucu büyütmek son çare. **Kapı:** rapor issue'ya bağlandı.
11. **MCP** (verisi modellere açılacaksa): `consciouslab-mcp` kit'ini uygula; Cloud Run servisi ve adres `mcp.<app>.consciouslab.io` adım 3'ün parçasıdır.
12. **Hermes** (isteğe bağlı): bir agent'ın app'e erişmesi için `consciouslab-hermes` kit'i; profil güven sınırıdır (müşteri profilinde iç kaynak yok).
13. **Yerel tarayıcı turu** (gerçek tarayıcı, app agent'ı yapar, kullanıcı görür): panelden yeniden girişsiz geçiş; her rol (`viewer` yazamaz);
    oturum yanıtında token yok ama kimlik var; çıkış app'e döner; oturumsuz kişi doğrudan auth'a gider; 11 dakikalık yenileme; kapatılan hesabın
    düşmesi. **Bir kez de anahtarlı web istemcisiyle** (yerel native istemci anahtar yolunu denemez). Sonucu ekran/çıktıyla raporla.
14. **Uyum testi.** MCP varsa `make mcp-conformance` (`facts`: `conformance_command`); API için `--api <url>`. API-only app'te
    `python -m consciouslab_auth.conformance --api <url> --start "<komut>" --issuer-port 0`. **Kapı: hepsi PASS (FAIL 0, SKIP açıklı).
    Yeşil değilse "bitti" deme.**
15. **Panel kaydı** (Anıl): Yönetim → Uygulama ekle (adres, kimler girer, varsayılan rol) → Bağlantı → istemci ekle (web; dönüş
    `…/api/auth/callback/<sağlayıcı>`, çıkış sonrası dönüş adresi). Anahtar bir kez görünür, doğrudan app'in sır kabına girilir, sohbete yazılmaz.
    MCP varsa alt kaynak (`POST /cl/apps`, `parentResource`) ve roller. Claude/ChatGPT dönüş adresleri auth tarafında hazır.
16. **Release.** Branch → PR (`dev`) → merge; `main` release'i kullanıcı onayıyla. Eski giriş değişkenleri giriş **doğrulanınca** silinir. İlk
    imaj `mcp_server/`'ı içermeli; deploy adımı servis henüz yoksa atlar (kırılmaz).
17. **Taşınan app ekstrası.** Eski girişi (şifre, oturum, ortak sır) adım 16'dan sonra kaldır. **Veri taşıma günü** (ADR 0042 kalıbı):
    Railway Postgres'e genel erişim açma, `railway connect … --tunnel-only` ile şifreli tünel (parolayı dosyaya yönlendir, ekrana basma,
    sonra sil); kaynakta tablo başına sayım; `pg_dump -Fc --no-owner --no-privileges` (aynı major) → geçici bucket (14 gün); ortak sunucu
    **geçici büyütülür**; GCP içinde Cloud Run Job'la `pg_restore --clean --if-exists -j 2` (yerelden proxy ile yükleme yok); sayımlar
    birebir; migration Job; sunucu eski boyuna döner. Taşıma gününü (Railway durur, son kopya, DNS) merkezle takvimle.

## Araçlar

`gh`, `git`, `gcloud` (ADC), `pip`/`pnpm`, `docker`, `make`; app agent'ının tarayıcısı (yerel tur). `consciouslab-auth` (Python) ve
`@consciouslab/auth` (npm) paketleri. Sır değeri sohbete, repoya, imaja yazılmaz.

## Sınırlar

- Altyapı (DNS, ortak veritabanı, Cloud Run modülü, GCP güveni) merkezdedir; bu kit onu app reposuna taşımaz, istek açtırır.
- Python (API/MCP) ve Next.js dışı stack için paket yok; merkezden iste. `gh --template new-app.yml`'in form dosyasıyla çalıştığı doğrulanmadı.
- Müşteri profilleri için agent kapsam tavanı ayrı iştir (YouTube Intel marka alanlarıyla).
- Paket sürümleri ön sürümdür (`0.1.0rc1`, `0.1.0-rc.1`); ilk gerçek dış kullanıcı YouTube Intel olacak, kit ondan öğrenip güncellenir.
- Yerel uçtan uca giriş, auth reposunun yerel çalışmasını ve merkezde seed'lenmiş istemciyi gerektirir; app reposu tek başına yapamaz.
