# openrouter — değişiklik günlüğü

## 1.0.1 — 2026-10-18

- Görünen ad İngilizce: "OpenRouter LLM calls" (arayüz dili İngilizce; Türkçe ad uygulama branch'inin adını da bozuyordu).

## 1.0.0 — 2026-10-17

İlk sürüm. Yöntem ve uyarılar şu kaynaklardan damıtıldı: 4 projenin kod ve ayar dosyaları (tur/gün/ay harcama tavanları,
retry sayaçları, yedek model zinciri, maliyet raporlama), 3 projenin integration dokümanı (biri OpenRouter istemcisinin
ölçümlerini, ikisi sınıflandırma ve sözlük keşfi kullanımını anlatıyor), bir projenin ADR'leri (token bütçesi, tur bütçesi)
ve organizasyon düzeyindeki bir gözlem notu (para yolu, bütçe kapısı arayüzü, retry kuralı).

Olgular (`kit.yaml` → `facts`) 2026-10-17'de resmî OpenRouter sayfalarından (docs ve pricing) doğrudan okunarak doğrulandı;
modeller kataloğunun alanları (`alias_target`, `canonical_slug`, `expiration_date`, `pricing.overrides`) aynı gün
`GET /api/v1/models` yanıtında gözlendi. Doğrulanamayan ya da bilerek dışarıda bırakılanlar:

- Kredi alım ücreti plana bağlıdır (Standard / Business); yalnız bu iki planın değeri `facts`'e yazıldı.
- Bir proje dokümanında geçen "maliyet için istek gövdesine `usage: {include: true}` eklenir" bilgisi güncel dokümanda
  eskimiş çıktı (parametre etkisiz, maliyet her yanıtta geliyor); kit yeni davranışı yazıyor.
- Sağlayıcı değişiminin çıktı kalitesine etkisi ölçülmedi; "Sınırlar"da belirtildi.
- Ücretli modeller için rate limit sayısı dokümanda yok (sağlayıcıya bağlı); sayı yazılmadı.
- Sınıflandırma modeline özgü `alpha` karar uç noktası ve görsel üretimi kapsam dışı bırakıldı.
