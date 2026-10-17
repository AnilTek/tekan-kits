---
name: railway
description: Deploy a service (FastAPI, Next.js, worker) to Railway so it deploys predictably and fails loudly — Infrastructure as Code (.railway/railway.ts, railway config plan/apply), migrating off railway.json / railway.toml, healthcheck path and timeout, preDeployCommand migrations, PORT and start command, DATABASE_URL reference variables, private networking (*.railway.internal), staging vs production environments, watch paths, usage limits. Use when the user mentions Railway, railway.json, "healthcheck failed", "service unavailable", "Failed to create code snapshot", "No module named 'psycopg2'", a deploy that goes green but serves old code, or a Railway bill.
---

# railway

## Ne

Bir servisin Railway'e öngörülebilir deploy edilmesi ve sorunda **yüksek sesle** düşmesi: kod olarak altyapı tanımı
(`.railway/railway.ts`), healthcheck, şema göçünün deploy'un parçası olması, özel ağ, ortam–dal eşlemesi
(staging = `dev`, prod = `main`) ve maliyet freni. Kit tek bir seed dosyası taşır; gerisi bu belgede.

## Neyi çözer

Daha önceki projelerde yaşanmış (bu projede değil — kullanıcıya böyle aktar), hepsi **sessiz** arızalar:

- Başlatma komutunda kabuk özelliği (`${PORT:-8080}`, `exec`) konteyneri tek satır log bırakmadan öldürdü; migration'ı
  başlatma komutuna koymak deploy'u sessizce astı ve healthcheck süre dolana kadar bekledi.
- `/health` "ok" dedi ama şema yoktu; arıza kodda sanıldı.
- Dinleme adresi: özel ağ yalnız IPv6 iken `0.0.0.0` servisi ağdan görünmez yaptı, `::` ise IPv4'ten gelen healthcheck'i düşürdü.
- Sağlayıcının `DATABASE_URL`'i sürücüsüz geldi (`postgresql://`); uygulama ve migration aynı adresi okuduğu için hiçbir servis açılmadı.
- CI'dan `railway up --detach` ile çift deploy tetiklendi: Railway çakışmayı eski sürüme geri alarak çözdü, CI yeşildi, prod eski kodu sundu.
  Başka bir repoda "deploy" işi yalnız `echo` basıyordu.
- Otomatik derleyici üç denemede üç ayrı hata verdi (eksik `npm`, eksik konsol betiği, runtime'a taşınmayan venv); tanı her seferinde
  deploy'dan ~10 dakika sonra logdan çıktı.
- IaC'de "omit means delete": dosyada bildirilmeyen kaynak ve değişken ilk `apply`'da silindi.
- Maliyet: gereksiz ikinci replika, ölçeklenmeyen ama sürekli RAM tutan servisler, sınırsız bırakılmış Postgres belleği (dosya önbelleği bellek diye faturalandı).

## Doğruluk kaynakları

- Docs: https://docs.railway.com (IaC, healthchecks, pre-deploy, start command, private networking, environments, cost control).
- Fiyat: https://railway.com/pricing.
- **Süre, fiyat, tarih ve davranış sayılarını yanındaki `kit.yaml` → `facts`'ten oku** (kaynağı ve kontrol tarihiyle); ezberindeki
  değerler eski olabilir. Özellikle `config_as_code_end`: `railway.json` / `railway.toml` artık deprecated; bu yüzden seed IaC.
  Davranış belirsizse `facts`'teki kaynak sayfayı yeniden aç.

## Yöntem

1. **Önce bak.** Repoda `railway.json`, `railway.toml`, `.railway/`, `Dockerfile*` var mı; Railway projesi/ortamları var mı?
   `railway.json` / `railway.toml` varsa yeni dosya yazma: `railway config migrate` önizlemesini göster, kullanıcı onaylarsa uygula
   (Railway iki kaynağı birlikte planlamaz; servisin ayarlarındaki config dosyası yolu da temizlenir).
2. **Kopyala.** `kit.yaml`'daki seed'i yaz; `.gitignore` satırı eklenir. SDK Node ESM ister: kökte `package.json` yoksa
   `npm init -y`, `"type": "module"`, sonra `npm install railway` (SDK kurulu değilse `plan` çalışmaz).
3. **Yer tutucuları repoyu OKUYARAK doldur, tahmin etme.** Dockerfile yolu, port, sağlık ucu, migration komutu repodan; okunamayan
   kullanıcıya sorulur. Seed doldurulmamışsa kendisi hata verir. Birden çok servis (worker, web) gerekiyorsa `service(...)`
   bloğunu çoğalt; worker HTTP sunmuyorsa `healthcheck` verme.
4. **Önce yerelde doğrula.** Deploy'dan önce `docker build` ve konteyneri yerel Postgres'e karşı çalıştır. Temiz build'de çıkan
   bağımlılık çakışmaları (yalnız geliştirici ortamında kurulu paket, eski pin) ve başı boş submodule (`.gitmodules` olmayan gitlink
   snapshot'ı kırdı) burada görünür. Build'i Dockerfile'a sabitle; `nixpacks.toml` gibi ölü yapılandırmayı sil.
5. **Başlatma komutu tek yerde: imajın `CMD`'si.** Dockerfile/imajda `start` exec biçiminde koşar, değişken genişletmez
   (`facts`: `start_command_exec_form`); gerekirse `/bin/sh -c`. Port: `PORT` env'ini açıkça tanımla ve uygulama ona uysun
   (iki projede Railway'in `PORT` davranışı beklenenden farklı çıktı; alan adı yanlış porta bakınca 502). Next.js'te
   `-p ${PORT}` ve `--hostname` açıkça verilir (Docker `HOSTNAME`'i kap kimliğiyle doldurur).
6. **Healthcheck ve açılış doğrulaması.** Yol 2xx dönmeli; Railway `healthcheck.railway.app` host'uyla gelir — host allowlist'i
   (MCP/DNS-rebinding) bunu kabul etmeli, yoksa 421/400. Sağlık ucu **gerçeği** denetlesin: veritabanına erişim ve şemanın head'de
   olması; yoksa 503. Healthcheck yalnız deploy başında sorulur (`facts`: `healthcheck_behavior`); süreç sonradan bozulursa
   uygulama içi izleme gerekir. `healthcheckTimeout`'u açılış süresinin birkaç katına indir, varsayılan arızayı geç gösterir.
   Gerekli env eksikse uygulama **adıyla** hata verip açılmasın.
7. **Şema deploy'un parçası: `preDeploy`.** Migration, ayrı kapta uygulamadan önce koşar; sıfırdan farklı çıkış deploy'u durdurur,
   eski sürüm yerinde kalır (`facts`: `predeploy_behavior`). Süre sınırı (`preDeployTimeoutSeconds`) ver; kilit bekleyen migration
   için `PGOPTIONS="-c lock_timeout=…"`. Başlatma komutuna migration koyma. Komut idempotent olsun; imajda bulunmalı.
8. **Veritabanı ve değişkenler.** `DATABASE_URL: db.env.DATABASE_URL` (referans; elle yapıştırma yok). Uygulama `postgresql://` ve
   eski `postgres://` biçimlerini sürücü ekleyerek normalize etsin. Servisler arası adres `<SERVICE>_BASE_URL` env'inden okunur:
   Railway'de `api.env.RAILWAY_PRIVATE_DOMAIN` + port, yerelde compose'taki mock/yerel servis; prod koduna mock dalı girmez.
   `NEXT_PUBLIC_*` build anında gömülür: Dockerfile'da `ARG` ile al, değiştirince yeni build gerekir.
9. **Özel ağ.** İç servise (API) public domain verme; çağıran `http://<servis>.railway.internal:<port>` kullanır. Ortamın
   dual-stack mı IPv6-only mı olduğuna bak (`facts`: `private_network_dns`); IPv6-only ortamda hem özel ağ hem IPv4 healthcheck için
   çift yığın dinle (`--host ''` ölçüldü; `::` ve `0.0.0.0` tek başına yetmedi). Çağıran konteynerden `wget …/health` ile kanıtla.
10. **Ortamlar ve dallar.** Prod yalnız `main`'den, staging `dev`'den (seed `ctx.isEnvironment("production")` ile seçer). Ayrı
    ortam = ayrı veritabanı. Ortamı çoğaltınca sealed değişkenler gelmez (`facts`: `duplicate_environment_secrets`); sırları elle
    gir, `.env` yükleme/commit yok, `preserve()` yalnız mevcut değeri korur. CI'dan `railway up` ile deploy etme: Railway'in dal
    izlemesi deploy'u yapsın, CI yalnız kapı olsun ve serviste **Wait for CI** açık olsun (`facts`: `wait_for_ci`).
11. **Plan ve apply.** `railway config plan` çıktısını oku ("omit means delete"); beklenmeyen silme varsa dur, kaynağı/değişkeni
    dosyaya ekle. CI'da `plan --detailed-exit-code` ile sürüklenme denetle. Sonra `apply`; ardından canlı doğrulama: `/health`,
    bir gerçek uç, auth'lu bir uç 401.
12. **Zamanlanmış ve tekil işler.** Cron servisi işi bitirince çıkmalı (açık bağlantı sonraki koşuyu atlatır), saati UTC'dir ve
    kap yaklaşık bir dakika geç ayağa kalkar (ölçüldü): tetik saati duvar saatine tam eşleme, ızgaraya yuvarla (`facts`: `cron_behavior`).
    Scheduler/beat gibi tekil işler `replicas: 1` ile sabit; süreç içi zamanlayıcıda Serverless açıksa uyuyan servis tick'i kaçırır
    (`facts`: `serverless_sleep`) — vadeye bağlı, kendini onaran tick yaz. Her deploy süreci öldürür: yarım kalan işi açılışta kapat.
13. **Maliyet freni.** Replika ve servis sayısı ölçülerek artar; worker/beat/Redis kendi RAM'ini sürekli tutar. Veritabanı ve
    servise bellek limiti koy; kullanım limitini önce yumuşak (e-posta) kur — sert limit tüm iş yüklerini kapatır
    (`facts`: `usage_limits`). Fiyatlar için `facts`: `plan_prices`, `resource_prices`.

## Araçlar

`railway` CLI (IaC motoru CLI'dadır; `facts`: `iac_status`), `node` ve `railway` npm paketi (`railway/iac`), `docker` (yerel doğrulama),
`git`. Kimlik: `railway login`; CI'da `RAILWAY_API_TOKEN` ya da ortama kapsamlı `RAILWAY_TOKEN`. Anahtar değeri repoya girmez.

## Sınırlar

- Seed yalnız tek servis + Postgres iskeletidir; worker, web, Redis, cron, volume ve alan adı proje okunarak eklenir.
  DSL'de `build`, `deploy` altındaki alanlar (watch paths, restart policy, pre-deploy süresi) docs'ta değil SDK tiplerinde
  belgelidir: `plan` çıktısı bu alanların uygulanmadığını gösterirse dashboard'dan ayarla ve kit'e bildir.
- Yedekleme/geri yükleme (PITR), alan adı, OAuth dönüş adresleri ve gözlemlenebilirlik kapsam dışı.
- Seed gerçek bir Railway projesine karşı `plan` ile denenmedi; ilk `plan` çıktısı doğrulamadır.
- Healthcheck'in süreç sonrası sağlığı izlemediği docs'ta açık; bir projenin "healthcheck düşünce Railway yeniden başlatır"
  varsayımı bununla çelişir — izleme ve restart politikası ayrı kurulur.
