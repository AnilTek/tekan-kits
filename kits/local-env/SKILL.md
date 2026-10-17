---
name: local-env
description: Set up or adopt the local environment contract in a repository - Docker Postgres on the same major as prod, schema built from migrations, a small hand-written seed, one-command reset (env-up, env-down, db-reset, dev, check), external services as mock-or-real via <SERVICE>_BASE_URL, and a structural guard (env-check.sh, run locally via `make check`; CI optional). Ships a Postgres template; for other stacks (SQLite/D1, Supabase, BigQuery, object storage) keep the contract and adapt the files. Use when the user says "yerel ortam", "local env", "docker compose", "db-reset", "env-up", "mock", "seed", when a port clashes ("address already in use", "port is already allocated", "bind: address already in use", wrong DB answering on 5432), when .env.example has a *_BASE_URL with no mock, or when a repo has no compose file or no env-up/db-reset commands. Never invent ports or Postgres versions from memory.
---

# local-env

## Ne

Her projede aynı yerel ortam: Docker'da prod'la aynı major Postgres, şemayı migration'lardan kuran, elle yazılmış küçük seed,
tek komutla sıfırlama (sil, migrate, seed). Her dış servis `<SERVICE>_BASE_URL` ile mock ya da gerçek seçilir; mock
compose'ta ayrı servistir. Komut adları sabit: `env-up`, `env-down`, `db-reset`, `dev`, `check`. Kapı yerel `make check`'tir; CI
isteğe bağlıdır. Dosyalar Postgres şablonudur; başka veritabanında sözleşme aynı kalır, dosyalar stack'e uyarlanır.

## Neyi çözer

Önceki projelerde yaşananlar:

- **Port çakışması.** Aynı makinede birkaç proje 5432'yi istedi; kalan projeler 5433, 5434, 55432, 55442 gibi elle seçilmiş
  portlara düştü, bir kısmı başka dalın ya da kardeş deponun portundan kaçmak için. Çakışma bazen sessizdir: ikinci proje
  başlamaz ya da model başka projenin veritabanına bağlanır ve fark etmez.
- **Aynı klasör adı, aynı compose proje adı.** Varsayılan ad klasör adıdır; iki projede aynı ad konteyner, ağ ve birim adlarını çakıştırır.
- **Her projede farklı komut adları** (`dev:env:up`, `down`, `db`, `env-up`): "ortamı kaldır" her seferinde keşif istedi.
- **Mock'suz dış bağlantı gerçek API'ye gider ve para harcar.** Önceki bir projede paralı bir token'la ağa çıkan komutlar
  yalnız `--go` bayrağıyla kuru çalışıyordu; koruma tek bir bayrağa bağlıydı.
- **Agent "çalıştı" dedi, kullanıcı tekrar edemedi.** Test, geçici bir klasörde kurulan ayrı bir DB'de yapılmıştı.
- **Yanlış veri yolu, veriyi kalıcı yapmaz.** Postgres imajının veri birimi yolu major'a göre değişir; yanlış yola bağlanan birim `down` sonrası
  veriyi tutmaz (resmî imaj dokümanından doğrulandı, `facts` → `postgres_volume_path`; projelerde yaşanmış bir olay değil).

## Doğruluk kaynakları

- Bu klasör: `kit.yaml` (dosya kipleri ve `facts`) ve `files/`. Sayıları, yolları ve kuralları `kit.yaml` → `facts`'ten oku
  (kaynağı ve kontrol tarihiyle); ezberindeki değer eski olabilir.
- Compose davranışı: resmî Compose dokümanı; Postgres imajı: resmî imaj dokümanı; Mailpit: kendi dokümanı (`kit.yaml` → `sources`).
- Projenin prod Postgres major'ı: repodan oku (altyapı kodu, deploy ayarı, ADR). Bulamazsan kullanıcıya sor; tahmin etme.
- Makinenin durumu (dinlenen portlar, Docker): her seferinde sorgula, bir yere not alma.

## Yöntem

1. **Önce stack'e bak, sonra kopyala.** Veritabanı ve depolama nedir (altyapı kodu, ADR, `wrangler.toml`, `package.json`)?
   - **Postgres değilse** kit'in Postgres parçalarını (`compose.yaml`'daki `postgres` servisi, `db-seed`'deki `psql`) olduğu gibi
     bırakma: sözleşmeyi (dört komut + `check`, `*_BASE_URL` mock'ları, tek komutla sıfırlama, elle seed) stack'in yerel
     eşdeğeriyle doldur. Örnek: D1/SQLite → `wrangler d1 migrations apply --local` ve `wrangler d1 execute --local --file`;
     R2/S3 → compose'ta S3 uyumlu bir mock (MinIO gibi); Supabase → Supabase CLI'ın yerel stack'i. Docker gerekmiyorsa compose
     dosyası olmayabilir; o zaman mock satırları `# env-check: process`.
   - **Proje CI kullanmıyorsa** (bir ADR'de "CI yok" kararı) workflow ekleme; kapı `make check`.
   Sonra: compose dosyası (`compose.yaml`, `compose.yml`, `docker-compose.yaml`, `docker-compose.yml`), `Makefile` ya da
   `package.json` script'leri, `.env.example`, migration klasörü, CI. Var olanın üzerine yazma.
   - Repoda zaten bir compose dosyası varsa kit'in `compose.yaml`'ını ekleme: Compose ikisi varken `compose.yaml`'ı seçer, eskisi
     sessizce devre dışı kalır. Kit'in servislerini var olan dosyaya, onun adıyla birleştir.
   - Komutlar `package.json` script'leriyle kuruluysa Makefile ekleme; aynı dört adı script olarak yaz (Tekan ikisini de tanır).
   - Auth/Storage için Supabase kullanılıyorsa Postgres compose'u yerine Supabase CLI'ın yerel stack'i gelir; kural aynı.
2. **Kopyala.** `kit.yaml`'daki dosyalar: `managed` birebir (varsa ve farklıysa farkı göster, onay iste), `seed` yoksa kopyala.
   `ensure_lines` ile `.gitignore`'a satırları ekle. `{{PROJECT_NAME}}` → compose proje adı (küçük harf, rakam, tire, alt çizgi).
3. **Yer tutucuları repoyu OKUYARAK doldur** (`<PLACEHOLDER: ...>`; `env-check.sh` doldurulmamışı kırmızıya düşürür):
   Postgres major'ı prod'dan, veri yolu `facts`'ten, `db-migrate` / `db-seed` / `dev` komutları `package.json` / `pyproject.toml` /
   `Makefile`'dan. Kullanıcı ve veritabanı adı projeye özgü kısa ad olsun, `postgres`/`postgres`
   değil: yanlış porta bağlanırsan sessizce başka veritabanı değil, kimlik hatası al.
4. **Portu makineden sorgulayarak seç.** Aday seç; üç sorguda da yoksa kullan. Duran konteynerler ve öteki projelerin dosyaları da sayılır,
   çünkü duran proje portunu geri ister:
   ```
   lsof -nP -iTCP -sTCP:LISTEN | awk 'NR>1{n=split($9,a,":"); print a[n]}' | sort -un
   docker ps -a --format '{{.Ports}}' | grep -oE ':[0-9]+->' | tr -d ':>-' | sort -un
   grep -rhoE --include='compose*.y*ml' --include='docker-compose*.y*ml' '([0-9.]+:)?[0-9]{4,5}:[0-9]+' <projelerin durduğu kökler>
   ```
   5432 ve komşularından, 3000/8000 gibi yaygın dev portlarından uzak dur; önceki projelerde `55432`, `55442` biçimi ve 5433, 5434
   işe yaradı. Mock'lar ve Redis gibi ek servisler için de ayrı boş port seç. Portlar compose'ta `127.0.0.1`'e bağlanır. Seçimi
   ve nedenini `.env.example`'a tek satır yaz. Bağlanmadan önce `docker compose port postgres 5432` ile kendi konteynerine bağlandığını doğrula.
5. **Her dış servis için `<SERVICE>_BASE_URL`.** Uygulama adresi yalnız bu env'den okur: yerel adres mock'a, dış adres gerçeğe gider; prod
   koduna mock dalı girmez. Mock compose'ta ayrı servistir (SMTP için Mailpit örneği `compose.yaml`'da yorumda; portlar `facts` → `mailpit_ports`).
   Portu compose'ta yayımla, `.env.example` satırı ona baksın. Bilerek gerçek servis: satıra `# env-check: real` ve maliyet yorumu. Mock compose dışında
   ayrı süreçse (`make dev` başlatıyorsa) `# env-check: process`. Yeni dış bağlantı gelince mock ve `*_BASE_URL` aynı PR'a girer.
6. **Seed küçük ve elle yazılır** (`db/seed.sql`): gerçek kişi ya da prod verisi yok. Yeni tablo örnek veri istiyorsa seed aynı PR'da güncellenir.
   Gerçeğe yakın veri gerekirse maskelenmiş snapshot: yalnız kullanıcı onayıyla, salt okunur kimlikle, maskeleme dump sırasında; ham dump makineye inmez
   (bu kit snapshot sağlamaz).
7. **Kendin doğrula, geçici ortamda değil bu ortamda:** `make check`; boş makineden `make db-reset`; ikinci `make db-reset`;
   `make env-down && make env-up` sonrası verinin durduğunu kontrol et. Aynı komutları kullanıcıya yaz, kendi terminalinde tekrarlasın.
8. **Ortamlar bölümü.** `docs/canonical/architecture.md`'ye `## Ortamlar` ekle (yoksa; docs-os'ta yer tutucusu hazır): dış bağlantı tablosu
   (servis, yerel varsayılanı mock ya da gerçek, mock'un adı, staging'de durumu) ve staging var mı, adresi. `last_reviewed` tarihini güncelle.
9. **Sürümü kaydet ve PR.** `.tekan/kits.json`'a `{ "source", "kit": "local-env", "version", "files": { path: sha256 } }` (yalnız managed
   dosyalar; Tekan kendisi yazar). `make check` yeşil. Proje CI kullanıyorsa ve istiyorsa `optional/.github/workflows/`
   (`env-check.yml`, `db-reset.yml`; toolchain adımı doldurulur) eklenir; CI'sız projede eklenmez.

## Araçlar

`docker` (Compose v2), `make` (ya da paket yöneticisi script'leri), `bash`, `lsof`, `git`, `gh`. Anahtar gerekmez.

## Sınırlar

- Kit dosyaları yalnız Postgres ve HTTP/SMTP mock'ları için hazır. Başka veritabanı ya da Redis gibi ek servis aynı kalıpla
  (boş port, `127.0.0.1`, adlandırılmış birim, `*_BASE_URL`) uyarlanır; onlar için kit dosyası yok.
- `env-check.sh` yapıyı denetler (komut adları, sabit major, yayımlanan port, doldurulmuş yer tutucu), mock'un doğru davranıp davranmadığını değil.
  Compose'u YAML olarak ayrıştırmaz: `ports:` liste satırlarını ve `published:` alanını okur; `include`/`extends` ile gelen portları görmez.
- Aynı repo'nun paralel worktree'leri aynı sabit portu ve proje adını paylaşır: ortam tek kopyadır, bir worktree'deki `db-reset` ötekinin verisini siler.
- Yerel şifre yalnız yerel içindir; gerçek anahtar `.env.example`'a girmez. Staging, snapshot ve gözlem (OTel) bu kit'in dışında.
- Managed dosyayı projede düzenleme; değişiklik kit'e PR olarak gider. Boş "ihtimalen lazım olur" dosyası açma.
