# apify — değişiklik günlüğü

## 1.0.0 — 2026-10-17

İlk sürüm. 4 projenin 10 Apify entegrasyon dokümanı (genel actor platformu, Instagram, TikTok, X/Twitter, Meta Ad Library, Google Trends), aynı projelerin bütçe kapısı/istemci kodu ve commit mesajları damıtıldı: maliyet kapısı ve sağlayıcı maliyetine güvenmeme, gizli ücret kalemleri, senkron çağrı ve hata sınıfları, sessiz boş/kısmi
veri, actor seçim ölçütü, ücretli test engeli ve actor'e özgü tuzaklar. Projelere özgü actor kimlikleri, ürün ve şirket adları
bilerek dışarıda bırakıldı.

Olgular (`kit.yaml` → `facts`) 2026-10-17'de resmî Apify dokümanlarından okundu (docs.apify.com, apify.com/pricing); her olgunun
kaynak sayfası kendi kaydında. Notlar:

- Sync endpoint 408 sonrası run'ın devam edip etmediği belgede yok; kit bunu "Sınırlar"da açıkça söylüyor.
- `maxTotalChargeUsd` limite ulaşınca davranış yalnız pay-per-event için belgeli.
- Run varsayılan bellek/zaman aşımı değeri ilgili sayfalarda yok; kit bu sayıları vermiyor.
- Python istemcisinin dönüş tipi değişikliği (dict/camelCase yerine nesne/snake_case) resmî dokümandan doğrulanamadı: kit bunu
  yalnız önceki projedeki hata belirtisi olarak aktarıyor ve her iki biçimi okumayı öneriyor.
- Hesap kullanımı için `GET /v2/users/me/limits` önceki bir projenin çalışan kodundan alındı, resmî sayfadan ayrıca doğrulanmadı.
- Sayfaların çoğu özetleme aracıyla okundu (uzun API sayfalarının ilk kısmı); tam metin okunamadı.
- Actor ölçümleri (ücret farkları, doluluk oranları) projelerin kendi ölçümüdür, actor sürümüne bağlıdır ve burada yeniden doğrulanmadı.
