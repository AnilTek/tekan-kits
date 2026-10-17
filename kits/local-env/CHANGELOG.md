# local-env — değişiklik günlüğü

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
