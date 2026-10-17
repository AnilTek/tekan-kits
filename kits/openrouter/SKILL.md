---
name: openrouter
description: How to call LLMs through OpenRouter (OPENROUTER_API_KEY, /chat/completions, response_format, models fallback list) so that calls cannot silently overspend or silently fail — reading real cost from usage.cost, spend caps per round/day/month, retry rules for 429/5xx/402, truncation by reasoning tokens (finish_reason length, empty content), JSON reliability, model fallback chains. Use whenever code calls OpenRouter, sets max_tokens, parses model JSON, adds a fallback model, estimates LLM cost, or hits 402, 403 budget, 429, "Rate limit exceeded", or invalid JSON errors.
---

# openrouter

## Ne

OpenRouter üzerinden LLM çağrısı yapan kodda para ve güvenilirlik kontrolü: gerçek maliyeti yanıttan okuma, harcamayı
tavanlarla sınırlama, doğru hatada doğru retry, yedek model zinciri, JSON'un bozulması ve kesilmesi. Tek iş: "LLM çağrıları
sessizce fazla harcayamaz ve sessizce bozulamaz."

## Neyi çözer

Daha önceki projelerde yaşanmış ya da ölçülmüş durumlar (bu projede değil — kullanıcıya böyle aktar):

- **Kesilme, format ihlali gibi görünür.** Bir muhakeme modeli, küçük `max_tokens` ile bir evet/hayır sorusuna boş ya da
  kesik cevap verdi; sebep model değil bütçeydi (tek kelimelik cevap için yüzlerce muhakeme token'ı harcandı,
  `finish_reason=length`). `finish_reason` bakılmadan ayrıştırılan cevap, kendi bütçe hatamızı modelin hatası diye kaydetti.
- **Liste fiyatı gerçek maliyeti vermez.** Çıkış token fiyatı ucuz görünen model, muhakeme token'ları yüzünden çağrı başına
  8 kat pahalıya geldi (26 kat fazla muhakeme token'ı). Maliyet fiyat × token tüketimidir, fiyat tek başına değil.
- **Tahmin ile gerçek ayrı şeylerdir.** Bir projede tur başına maliyet tavanı fiyat tablosundan tahminle işletildi; tahmin,
  her cevabın token bütçesinin tamamını kullandığını varsaydığı için gerçeğin 3-4 katı çıktı. Fren için doğru yön bu;
  düşük tahmin freni işlevsiz bırakırdı. Fiyat bilinmediğinde tavan ya sessizce açılırdı ya da sistemi tamamen durdururdu.
- **Başarısız denemeler de para yazar.** Yanıtı gelip ayrıştırılamayan her deneme ücretlendirildi; bu yüzden run
  maliyeti tüm denemelerin toplamı olarak tutuldu.
- **Zincirdeki sessiz düşüş.** Bir projede yedek model zinciri istemcide döngüyle kuruldu; boş ya da geçersiz JSON zincirin
  sonraki modeline geçmeden statik metne düştü, her hata türü (kimlik hatası dahil) tüm modelleri sırayla denetti.
  Zincirin toplam süresi ilk tasarımda ~90 sn'ye çıkıyordu; model başına zaman aşımı ayrı verilerek ~35 sn'ye indirildi.
- **Yalnız sayım freni yetmez, yalnız dolar freni de.** Para harcayan bir botta aylık dolar tavanı + günlük sayı +
  kişi başı bekleme birlikte kullanıldı; başarısız üretim sayaca yazılmadı. Maliyet sabit bir tablodan yazıldı (gerçek
  `usage.cost` değil), yani fiyat değişince sayaç sessizce yanlışlaşır.
- **Takma ad modeller sessizce değişir.** `~vendor/model-latest` gibi kimliklerin altındaki model değişir; karşılaştırmalı
  ölçümde trendi neden kırdığı görünmez.

## Doğruluk kaynakları

- Kullanım/maliyet: https://openrouter.ai/docs/cookbook/administration/usage-accounting ·
  https://openrouter.ai/docs/api-reference/get-a-generation
- Limitler, 402/403/429: https://openrouter.ai/docs/api-reference/limits
- Yedek modeller ve sağlayıcı yönlendirme: https://openrouter.ai/docs/guides/routing/model-fallbacks ·
  https://openrouter.ai/docs/guides/routing/provider-selection
- Yapılandırılmış çıktı: https://openrouter.ai/docs/guides/features/structured-outputs ·
  https://openrouter.ai/docs/guides/features/response-healing
- Muhakeme token'ları: https://openrouter.ai/docs/guides/best-practices/reasoning-tokens
- Fiyat ve ücretler: https://openrouter.ai/pricing
- **Sayıları ve davranış ayrıntılarını bu dosyanın yanındaki `kit.yaml` → `facts`'ten oku** (kaynağı ve kontrol
  tarihiyle); ezberindeki değer eski olabilir (örnek: `usage: {include: true}` eskiden maliyet için gerekliydi, artık
  etkisiz). Bir limit, fiyat ya da parametre söylerken `facts`'teki değeri ve tarihini kullan.

## Yöntem

1. **Para yolu tek yerde.** Tüm OpenRouter çağrıları tek bir istemci fonksiyonundan geçsin; bütçe kapısı, retry ve maliyet
   kaydı orada. Dağınık çağrı, her tavanı ayrı ayrı unutturur. Adres `OPENROUTER_BASE_URL` env'inden okunur; yerelde
   compose'taki sahte sunucu, dışarıda gerçek API. Prod koduna mock dalı girmez.
2. **Gerçek maliyeti yanıttan oku:** `usage.cost` her yanıtta gelir (ek parametre yok, `facts` → `cost_in_response`).
   Her denemenin `cost`'unu, `generation_id`'siyle birlikte kaydet. Sonradan denetim için `GET /generation?id=`
   (`facts` → `generation_endpoint`). Fiyat tablosundan hesaplanan sayı yalnız ön tahmindir; sabit fiyat tablosunu
   sayaç olarak kullanma.
3. **`finish_reason`'ı ayrıştırmadan önce kontrol et.** `length` ise cevap kesilmiştir: format ihlali sayma, ayrıştırma
   deneme, `max_tokens`'ı artırarak yeniden sor (aynı bütçeyle tekrar aynı sonucu verir). Muhakeme modellerinde
   `max_tokens` muhakemeyi de kapsar (`facts` → `reasoning_tokens_billing`): taban bütçeyi hedef kümedeki en çok
   düşünen modele göre belirle.
4. **Retry sayaçlarını ayır:** (a) taşıma: yalnız 429 ve 5xx, üstel backoff, `Retry-After`'a uy; diğer 4xx tekrarlanmaz.
   (b) kesilme: bütçe artırarak. (c) format: hatırlatma ekleyerek. Üçünün de tavanı olsun; tükenince `ok=false` dön ve
   çağıran taraf eksik sonucu işaretlesin. Karışık sayaç, "bu model bu formatta ölçülemiyor" bulgusunu kirletir.
5. **402/403/429'u ayır.** 402'de `error.metadata.limit_source`'a göre dallan (geçici anlık bütçe: bekle; anahtar
   limiti ya da bakiye: retry anlamsız, alarm ver — `facts` → `error_402_cases`). 403 bütçe bloğu `resets_at`'e kadar
   aynı sonucu verir. 429 geçici.
6. **Harcama freni iki katman ve önden:** (a) yapısal: turdaki çağrı/cevap sayısı, fiyattan bağımsız;
   (b) maliyet: tahmini USD tavanı, yalnız tüm modellerin fiyatı biliniyorsa. Tahmin üst sınır olsun (her cevap tüm
   bütçeyi kullanır) ve arayüzde "en çok" diye yazılsın. Fiyatı bilinmeyen model turu engellemez ama bilinmediği
   görünür. Kontrol geri alınamaz adımdan **önce** yapılır. Kapı istisna fırlatmak yerine `(izin, sebep)` döndürsün ki
   sebep kayda yazılsın. Fiyatta `pricing.overrides` (uzun bağlam, UTC saat dilimi) varsa tahmini en yüksek fiyatla yap
   (`facts` → `pricing_overrides`).
7. **Kullanıcıya açık uç için ek fren:** kişi/gün sayı sınırı, kişi başı bekleme, aylık USD tavanı; sayaca yalnız
   başarılı çağrı yazılsın. Tavanlar env'den okunur (örn. `MAX_ROUND_COST_USD`, `MAX_*_RETRIES`), kodda sabit değil.
8. **Son savunma sunucu tarafında:** anahtara kredi limiti + sıfırlama aralığı koy
   (`facts` → `per_key_credit_limit`). Uygulama içi tavan yazılım hatasında delinebilir; anahtar limiti delinmez.
   Uzun işten önce `GET /key` ile `limit_remaining`'e bak.
9. **Yedek model: önce amaca karar ver.** Dayanıklılık için `models` listesi kullanılabilir (`facts` →
   `models_fallback_param`); yanıttaki `model` alanını kaydet, çünkü o modelin fiyatı ödenir. Karşılaştırmalı ölçümde
   yedek kullanma ve sağlayıcıyı sabitle (`provider.order` + `allow_fallbacks: false`); yoksa aynı kimlik altında
   sağlayıcı değişir ve "eşit şartlar" bozulur. İstemci tarafı zincir kuruyorsan: model başına zaman aşımı ver, kimlik/
   bakiye hatasında zinciri sürdürme, boş ya da geçersiz yanıtı da sonraki modele geçiş sebebi say.
10. **JSON güvenilirliği: şema kodda, doğrulama her zaman yerelde.** `response_format` (`json_schema`, `strict: true`)
    iste ama desteği sağlayıcı bazlı ve desteklenmezse sessizce yok sayılabilir (`facts` → `unsupported_param_ignored`);
    gerekiyorsa `require_parameters: true`. Gelen metni yine de şemayla doğrula. Başarısızlıkta: bir kez hatırlatmayla
    yeniden sor ya da bir kez daha güçlü modele yükselt (sonsuz döngü yok). `response-healing` eklentisi sözdizimi hatalarını
    onarır, kesilmiş JSON'u onaramaz (`facts` → `response_healing_limits`).
11. **Model kimliğini sürümlü kaydet.** Katalogdaki `canonical_slug` ve `alias_target` ile takma adı ele; `expiration_date`
    dolu olan modeli erken uyar. `supported_parameters`'a bak: bazı modellerde `seed`/`temperature` yok.
12. **Para harcayan test ve betikler varsayılan kuru çalışsın** (`--go` ile gerçek); gerçek çağrı testleri ayrı işaretli
    (`-m live`) ve varsayılan test koşusunun dışında kalır.

## Araçlar

`OPENROUTER_API_KEY` (openrouter.ai/keys; kredi limiti anahtar ayarlarında). Uçlar: `POST /api/v1/chat/completions`,
`GET /api/v1/models` (kimliksiz), `GET /api/v1/generation?id=`, `GET /api/v1/key`. İstemci: OpenAI-uyumlu herhangi bir
HTTP istemcisi ya da resmî SDK; sağlayıcıya özel SDK eklemeye gerek yok.

## Sınırlar

- Yalnız metin sohbet tamamlama yolu. Görsel üretimi, ses, gömme, `alpha` uç noktaları (örn. sınıflandırma modelleri
  için ayrı bir karar uç noktası) ve BYOK ayrıntıları kapsam dışı.
- Yoğun, sürekli yük altındaki davranış bilinmiyor: ücretli modellerde bağlayıcı bir rate limit gözlenmedi, ama bu bir
  gözlem, taahhüt değil; 429 için backoff her zaman kalsın.
- Aynı model kimliği için sağlayıcı değişiminin çıktı kalitesini ne kadar etkilediği ölçülmedi; kritik ölçümde sağlayıcıyı sabitle.
- Fiyat, limit ve davranışlar sık değişir: bu kit'in `facts`'i kontrol tarihiyle gelir, tarih eskiyse yeniden doğrula.
