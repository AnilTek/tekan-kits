# supabase — değişiklik günlüğü

## 1.0.1 — 2026-10-18

- Görünen ad İngilizce: "Supabase backend" (arayüz dili İngilizce; Türkçe ad uygulama branch'inin adını da bozuyordu).

## 1.0.0 — 2026-10-17

İlk sürüm. Gerçek projelerde yaşanmış hatalardan damıtıldı: 4 projenin ADR, güvenlik denetimi, migration README'si, entegrasyon
dokümanı, commit mesajı ve `.env.example` dosyaları, ayrıca kurumsal bilgi katmanındaki Supabase entegrasyon notu.

- **Olaylar** (anahtar sızıntısı, anon/authenticated kilidi, imzasız JWT, supabase-py oturum dönüşü, `user_metadata` ile yetki,
  iki migration koşucusu, pooler adres tuzakları, yanlış şemaya bağlanma, Free plan kararı) ilgili projelerdeki kayıtlardan
  alındı; resmî dokümanla çelişen ya da onu aşan bir iddia eklenmedi.
- **Olgular** (`kit.yaml` → `facts`) 2026-10-17'de resmî sayfalardan okundu: fiyat sayfası, Project Pausing, Connecting to
  Postgres, JWTs, JWT claims reference, API keys, Row Level Security, Database migrations, Local development overview, CLI getting
  started, Storage buckets. Hepsinin `checkedAt` değeri bu tarih.
- **Çelişki, çözüldü:** pause sonrası geri yükleme süresi Project Pausing sayfasında 1 yıl yazıyor, aynı sayfanın bölüm bağlantısı
  ve eski bir changelog 90 gün diyor; sayfa metni esas alındı, `facts`'te çelişki belirtildi.
- **Resmî dokümanla ayrışan nokta:** önceki projelerde HS256 token yerelde `SUPABASE_JWT_SECRET` ile doğrulandı; resmî doküman
  bunu önermiyor (Auth sunucusuna sor ya da asimetrik anahtar). SKILL.md ikisini de söylüyor, "Sınırlar"da işaretli.
- **Doğrulanamadı / bilinçli dışarıda:** `aud` için resmî JWTs sayfası değer vermiyor, değer JWT claims reference'tan alındı.
  Yerel CLI stack'inin Auth tarafında (yerel JWT sırrı) davranışı resmî sayfalardan okunmadı, anlatılmadı. Hiçbir kaynak projede CLI
  yerel stack'i kullanılmadığı için madde 12 önceki projelerde görülen sorunların tersinden ve resmî dokümandan türetildi.
