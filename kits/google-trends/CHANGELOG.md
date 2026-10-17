# google-trends — değişiklik günlüğü

## 1.0.0 — 2026-10-17

İlk sürüm. Yöntem, 3 projenin (bir marka-izleme ve veri hattı projesi ile bir gündem-keşif projesi) integration dokümanlarından,
ADR'lerinden ve gerçek çekimlerle yapılmış bir kalibrasyon testinin sonuçlarından damıtıldı: pencere göreliliği, örnekleme
gürültüsü, sıfır-şişkin seriler, sessiz boş / yanlış ülke koşuları, iki actor'ün güvenilirlik ölçümleri. Olaylar kaynak projelerde
yaşanmış olanlardır; kit metni projeye özgü ad ya da kimlik taşımaz.

Olgular 2026-10-17'de resmî kaynaklardan karşılaştırıldı:

- Trends yardım merkezi (SSS, yükselen sorgular, karşılaştırma sayfaları) ve Google Trends API (alpha) sayfası ile duyuru yazısı
  okundu. Duyuru yazısının gövdesi ham HTML'den doğrudan çıkarıldı.
- Apify actor sayfaları (fiyat, girdi kipleri, çıktı alanları) okundu. Fast actor fiyatı kaynak projelerin dokümanındaki
  değerden farklıydı (değişmiş); sayfadaki bugünkü değer `facts`'e yazıldı.
- RSS beslemesi `curl` ile çekilip madde sayısı sayıldı.
- Doğrulanamayanlar: Trends API alpha'sının erişim kapsamı ve zamanlaması (sayfa yalnız "başvuru açık" diyor), "100"ün tam
  tanımı (yardım sayfası "bir konunun tüm aramalara oranı" diyor, zirve noktası demiyor; "en yüksek nokta = 100" bilgisi kaynak
  projelerin ölçümünden ve web davranışından geliyor), `pytrends`'in kırılma nedenleri (kaynak projelerde ölçülmedi; kit'e
  iddia olarak girmedi). Actor çıktılarının "çalışan girdi" ayrıntıları kaynak projelerin ölçümüne dayanır, bugün yeniden koşulmadı.
- Duyuru yazısı Google'ın resmî Search Central blogundadır; `sources`'ta `official_docs` olarak işaretlendi çünkü API'nin
  ölçekleme ve veri aralığı ayrıntısı yalnız orada.
