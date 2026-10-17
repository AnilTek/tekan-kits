# local-env — değişiklik günlüğü

## 2.0.0 — 2026-10-18

İlk gerçek uygulamada (Postgres'siz, CI'sız bir proje: D1 + R2, ADR'si "CI yok, kontroller yerelde") görülenler:

- CI workflow'ları artık kopyalanmaz (`files`'tan çıktı, `optional/.github/workflows/`'a taşındı). Kapı yerel `make check`;
  CI yalnız proje kullanıyorsa eklenir. Önceki sürüm CI'sız projeye iki workflow koymuştu.
- `Makefile`'a `check` hedefi.
- `env-check.sh`: compose dosyası yoksa hata değil not (Docker'sız stack'te servisler compose dışında olabilir).
- SKILL.md Yöntem 1: önce stack'e bakılır; Postgres değilse dosyalar olduğu gibi bırakılmaz, sözleşme stack'in yerel
  eşdeğeriyle (D1/SQLite, S3 mock, Supabase CLI) doldurulur.

## 1.0.0 — 2026-10-17

İlk sürüm. Yerel ortam sözleşmesinin (Docker Postgres, migration'dan şema, seed, tek komutla sıfırlama, `<SERVICE>_BASE_URL` ile
mock ya da gerçek, sabit komut adları, CI denetimi) kit hali.

Damıtıldığı kaynaklar (proje adı verilmeden):

- 5 yerel projenin compose dosyaları, `Makefile`/`package.json` komutları ve `.env.example` dosyaları: port seçimleri ve nedenleri
  (komşu projeden ya da başka daldan kaçınma), 127.0.0.1 bağlama, adlandırılmış birim, sağlık denetimi, projeye özgü
  kullanıcı/veritabanı adı, dört komut adının bir projede örnek olarak zaten çalışan hali, paralı dış bağlantının `.env.example` uyarısı.
- Kuruluşun iki bilgi notu: compose proje adı çakışması ve sabit host portunun paralel projeleri kilitlemesi.
- Kullanıcının ortam sözleşmesi (yerel, staging, prod tablosu; seed, sıfırlama, mock ve CI güvence kuralları).

Olguların doğrulanması: compose dosya adı önceliği, `up --wait`, `down -v`, değişken ifadeleri, proje adı kuralı, Postgres imajının veri yolu
değişikliği ve Mailpit portları 2026-10-17'de resmî dokümandan okundu (`kit.yaml` → `facts`, her biri kaynak URL'si ve kontrol tarihiyle).
Doğrulanamayan olgu yok. Postgres veri yolu uyarısı resmî dokümana dayanır; kaynak projelerde yaşanmış bir olay değildir.

`env-check.sh` macOS'un bash 3.2'sinde, kanonik örnek projenin bir kopyasında (mock'lar compose dışında: bilinçli olarak kırmızı, işaretle yeşil)
ve kit dosyalarından kurulmuş bir deneme projesinde (Docker ile `make db-reset`, ikinci sıfırlama, `env-down`/`env-up` sonrası veri) çalıştırıldı.
