# gemini — değişiklik günlüğü

## 1.0.0 — 2026-10-17

İlk sürüm. Altı projenin (iki integration dokümanı, kod yorumları, ADR'ler, ölçüm kayıtları ve commit mesajları) ve bir
organizasyon gözlem notunun damıtması: Vertex ve API anahtarı modunda kimlik hataları, bölge/404 karışıklığı, düşünme
token'ı muhasebesi, `thinking_budget` regresyonu, ödenip kaybolan çağrılar, önbellek eşiği ölçümü, kota (429) ve yeniden
deneme. YouTube/video URL girdisi önceki projelerde kullanılmadı; o madde yalnız resmî dokümana dayanır ve SKILL.md'de böyle
işaretli.

Olguların doğrulanması (hepsi 2026-10-17'de resmî kaynaktan):

- Fiyat, model adı, kapanış tarihi, kota, düşünme, önbellek, YouTube URL ve Vertex-vs-API karşılaştırması resmî sayfalardan
  okundu (ai.google.dev ve Google Cloud dokümanları). Vertex fiyat ve önbellek sayfaları ham HTML'den metne çevrilerek okundu.
- SDK davranışı (istemci kurucusu, env adları, hata sınıfları, yeniden deneme varsayılanları, zaman aşımı birimi,
  `base_url`, `thinking_budget`/`thinking_level` alanları) `google-genai 2.31.0` paketini kurup kaynağından okuyarak
  doğrulandı; PyPI'daki son sürüm de aynı.
- Fiyat sayfası `gemini-3.6-flash` için 2027-01-01'de değişen tarife gösteriyor (2026-12-31'e kadar giriş $0,75 / çıkış
  $3,75; sonrası $1,50 / $7,50). Önceki projelerin 2026 ağustos tarihli dokümanları $1,50 / $7,50 yazıyordu; aradaki farkın
  nedeni doğrulanamadı. `facts` bugünkü resmî sayfayı yansıtır.

Doğrulanamayanlar ve bilerek dışarıda bırakılanlar:

- Vertex'te model bölge matrisi (hangi model hangi bölgede) ve Vertex kota sayıları: sayfa metninden güvenilir okunamadı,
  gövdede yalnız "gerçek çağrıyla doğrula" denir. Önceki ölçüm (yeni model yalnız `global` uçta) 2026-08-25 tarihlidir.
- Vertex'te Interactions API desteği doğrulanamadı.
- Önceki bir projenin "Vertex'te otomatik önbellek yok" notu Gemini için resmî dokümanla çelişiyor (örtük önbellek açık
  varsayılan); SKILL.md "Sınırlar"da çelişki olarak kayıtlı.
- İki önceki doküman `thinking_budget=0`'ı SDK sürümüne bağlı "hâlâ destekli" gösteriyordu; sonraki üretim hatası bunun model
  bağımlı olduğunu kanıtladı, kit sonraki kanıtı esas alır.
