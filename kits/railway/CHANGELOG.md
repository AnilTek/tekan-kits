# railway — değişiklik günlüğü

## 1.0.0 — 2026-10-17

İlk sürüm. Yöntem, 5 projenin deploy yapılandırması, commit geçmişi ve canlıya çıkış notlarından ve 1 organizasyon
düzeyi entegrasyon dokümanından damıtıldı (api/web/worker/cron servisleri, Postgres/Redis, IaC ve config dosyası kullanan
örnekler). "Neyi çözer"deki her madde bu kaynaklarda yaşanmış bir olaya dayanıyor; olaylar önceki projelerden aktarılıyor.

- **Tasarım kararı:** seed `railway.json` değil `.railway/railway.ts` (IaC). 2026-10-17'de resmî docs Config as Code'un deprecated
  olduğunu ve 2026-12-01'de okunmasının bittiğini söylüyor (`facts`: `config_as_code_end`); ölü olacak bir dosyayı seed yapmak
  kit'in amacına (öngörülebilir deploy) aykırı. Kaynak projelerin çoğu hâlâ `railway.json` kullanıyor; Yöntem adım 1 geçişi
  (`railway config migrate`) anlatıyor.
- **Olgular** 2026-10-17'de docs.railway.com sayfalarının ham metninden ve railway.com/pricing'den tek tek okundu
  (healthcheck, pre-deploy, start command, özel ağ, restart policy, cron, Serverless, Wait for CI, kullanım limitleri, fiyatlar).
  `iac_sdk_version` npm kayıt defterinden okundu (3.16.0, Node >= 22).
- **Seed doğrulaması:** SDK 3.16.0 ile `tsc --strict` temiz; yer tutucular doluyken `production` ve staging ortamları için
  üretilen graf incelendi (dal `main`/`dev`, preDeploy komutu, healthcheck, yeniden başlatma, `DATABASE_URL` referansı).
  Yer tutucu doluyken dosya bilerek hata veriyor. Railway CLI yüklü olmadığı için `railway config plan` **koşulmadı**:
  docs'ta `build` ve `deploy` alanlarının (watch paths, restart policy, pre-deploy süresi) DSL karşılığı anlatılmıyor, yalnız
  SDK tiplerinde var; bu bir doğrulanamadı notudur (SKILL.md "Sınırlar").
- Doğrulanamadı: seed'deki `healthcheckTimeout: 60`. Kaynak projelerde 30–300 saniye arası seçimler var, docs bir değer önermiyor;
  60 bir projenin seçimi, doğrulanmış öneri değil. Kit'in önerisi "açılış süresinin birkaç katı" (ölçerek).
- Bir projenin kod yorumundaki "healthcheck düşerse Railway yeniden başlatır" varsayımı resmî docs'la çelişiyor (docs: healthcheck
  yalnız deploy başında sorulur); kit docs'u esas alıyor ve çelişkiyi SKILL.md "Sınırlar"da not ediyor.
