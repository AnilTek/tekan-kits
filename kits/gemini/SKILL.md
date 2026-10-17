---
name: gemini
description: How to call Gemini through the google-genai Python SDK correctly and within cost, in both Gemini API key mode and Vertex AI mode (service account, ADC, region, global endpoint) — choosing the mode, auth, response_schema structured output, YouTube/video URL input, thoughts_token_count and cost ledger, thinking_level vs thinking_budget, 429 RESOURCE_EXHAUSTED handling, model ids. Use whenever code uses genai.Client, google-genai, GEMINI_API_KEY, GOOGLE_API_KEY, GOOGLE_GENAI_USE_VERTEXAI, VERTEX_PROJECT_ID, GCP_REGION, generate_content, or hits 404 "Publisher model was not found", 400 INVALID_ARGUMENT on thinking_budget, 403 aiplatform.endpoints.predict, or a Gemini bill larger than the token estimate.
---

# gemini

## Ne

`google-genai` SDK'sıyla Gemini'yi çağırma yöntemi: iki mod (Gemini API anahtarı / Vertex AI), kimlik, yapılandırılmış çıktı,
video ve YouTube URL girdisi, token ve maliyet defteri, kota ve 429, model adları. Tek iş: Gemini'yi doğru kimlikle ve
ödediğini bilerek çağırmak.

## Neyi çözer

Daha önceki projelerde yaşanmış hatalar (bu projede değil — kullanıcıya böyle aktar):

- **Yanlış mod, yanlış kimlik:** yerelde kişisel `gcloud` oturumuyla çalışan Vertex çağrısı sunucuda düştü (kişisel oturum
  süresi doluyor; kimlik env'den okunmuyordu, yerel ADC hatayı gizlemişti). Başka bir projede Vertex servis hesabı
  `aiplatform.endpoints.predict` iznine sahip olmadığı için 403 aldı ve çağrı API anahtarı koluna taşındı.
- **Yanıltıcı 404:** Vertex'te "Publisher model ... not found or your project does not have access" fatura/yetki hatası
  sanıldı; sebep bölgeydi (yeni model yalnız `global` uçta vardı). Fatura kapalıyken mesaj 403 "requires billing" idi.
- **Eksik maliyet:** düşünme token'ları `candidates_token_count`'ta yok ama çıktı olarak faturalanıyor; yalnız candidates
  sayan defter %1301 eksik çıktı. Düşünmeyi kapatamayan bir pro modelle küçük sınıflandırma çağrıları, bir haftada faturanın
  büyük kısmını düşünme token'ına yaktı.
- **Sessiz çürüyen dal:** düşünmeyi kapatan `thinking_budget=0`, model yükseltilince 400 INVALID_ARGUMENT vermeye başladı;
  dal varsayılan yolda koşmadığı için üretimde görünmedi.
- **Ödenip kaybolan çağrılar:** metinsiz yanıt (`response.text` None) ayrıştırmayı çökertti, defter satırı yazılmadı;
  kalıcı hatalı iş vade sorgusuna her turda yeniden girip yeniden ödendi.

## Doğruluk kaynakları

- Fiyat: https://ai.google.dev/gemini-api/docs/pricing ve https://cloud.google.com/vertex-ai/generative-ai/pricing
- Model adları ve kapanış tarihleri: https://ai.google.dev/gemini-api/docs/models · https://ai.google.dev/gemini-api/docs/deprecations
- Kota: https://ai.google.dev/gemini-api/docs/rate-limits · Vertex 429: `kit.yaml` → `sources`
- SDK davranışı: https://github.com/googleapis/python-genai (kurulu sürümün kaynağı en kesin kaynaktır)
- **Sayıları (fiyat, kota, limit, model adı, sürüm, endpoint) bu dosyanın yanındaki `kit.yaml` → `facts`'ten oku**
  (kaynağı ve kontrol tarihiyle); ezberindeki değer eski olabilir — fiyatlarda tarife kesim tarihi var, model adları kapanıyor
  ya da başka bir adrese yönlendiriliyor. Bir maliyet, kota ya da model adı söylerken `facts`'teki değeri ve tarihini kullan.

## Yöntem

1. **Modu bilinçli seç; istemciyi tek fonksiyonda kur.** API anahtarı: hızlı başlangıç, tek sır, ücretsiz katmanda
   istemler ürün geliştirmede kullanılabilir. Vertex: IAM kimliği, aynı GCP projesinde fatura, veri kullanımı yok, bölge/
   global seçimi, Provisioned Throughput (`facts`: `vertex_vs_api_data_use`). Önceki projelerde fatura ve kimlik zaten GCP'de
   olduğunda Vertex seçildi. Kodu iki moda açık bırak: `genai.Client(api_key=...)` ya da
   `genai.Client(vertexai=True, project=..., location=..., credentials=...)`; `project`/`location`'ı anahtar moduna verirsen
   SDK `ValueError` fırlatır (`facts`: `client_env_vars`). Ortamdan örtük okumaya güvenme: önceki projeler anahtar ve proje kimliği
   için farklı env adları kullandı; SDK'nın kendi adları vardır ve iki anahtar adı birden tanımlıysa `GOOGLE_API_KEY` kazanır.
2. **Vertex'te sunucu kimliği servis hesabıdır.** Anahtar dosyasının YOLUNU değil İÇERİĞİNİ env'e koy
   (`GOOGLE_APPLICATION_CREDENTIALS_JSON`), `service_account.Credentials.from_service_account_info(..., scopes=
   ["https://www.googleapis.com/auth/cloud-platform"])` ile `credentials=` ver; değişken boşsa ortamın kimliğine (yerelde
   ADC) düş; yol verilmişse sebebiyle hata ver. Kimlik zincirini yerel ADC'siz bir ortamda (ilk deploy, staging) bir kez gerçek
   çağrıyla dene. IAM'de Vertex kullanıcı rolü gerekir; 403'te eksik izin adı mesajda yazar.
3. **Bölge:** Vertex'te yeni modeller bölgesel uçta olmayabilir ve liste ucu bunu göstermez; var olup olmadığını
   gerçek bir çağrıyla öğren. 404 + "not found / no access" kimliğin doğrulandığını gösterir: önce bölgeyi/model adını
   değiştir, fatura değil. `global` uç 429'u azaltır ve bölgesele göre daha ucuzdur ama veri ikametini garanti etmez
   (`facts`: `vertex_global_endpoint_residency`, `vertex_global_vs_regional_price`); Avrupa'da kalma bir hukuk
   kararıdır, teknik varsayılan değil. Hata metnine bu ayrımı yaz.
4. **Model adını koda gömme; fiyatı model satırıyla birlikte sakla.** Önceki bir projede model ve fiyat veritabanında
   tutuldu: model değişimi migration oldu, deploy değil; eski satır silinmedi (defter ona referans verir). Üretimde
   sabitlenmiş (stable) adı kullan, `-latest` takma adı kullanma; bazı eski adlar yenisine sessizce yönlendiriliyor —
   `response.model_version`'ı kaydet (`facts`: `model_naming_rules`, `model_lifecycle_dates`). Ucuz modelle koşup pahalı
   tarifeden yazmak defteri şişirir: tarife, çağrının gerçekten kullandığı model satırından okunur.
5. **Token defteri: dört alanı da yaz.** `prompt_token_count`, `candidates_token_count`, `thoughts_token_count`
   (çıktı tarifesinden faturalanır, candidates'a dahil değil), `cached_content_token_count`. `usage_metadata` yoksa
   `None` yaz, `0` yazma ("ücretsiz" ile "bilmiyoruz" ayrılsın). Defter satırı ayrıştırmadan ÖNCE yazılır; metinsiz yanıtta
   `finish_reason`'ı sakla (yanıt nesnesini sonradan okuyamazsın). Tahmin yaparken sistem istemini ve düşünme token'ını say:
   önceki bir tahmin sistem istemini unuttu ve eksik çıktı. Defter ile fatura arasında fark çıkarsa önce çağrı sayısını
   karşılaştır; önceki ölçümde fark fiyat hatası değil faturalama gecikmesi çıktı.
6. **Düşünmeyi iş türüne göre ölç.** 3.x'te `thinking_level` vardır, tam kapatma yok (`facts`: `thinking_controls`);
   `thinking_budget` eski modellerin parametresidir ve yeni modelde 400 verebilir. Model değiştirirken kapalı/seyrek
   dalları da gerçek çağrıyla koştur. Önceki bir ölçümde etiketleme/sınıflandırmada düşünme doğruluğa 0,5 puandan az
   katıp maliyetin yarısını götürdü; düzyazı üretiminde açık kaldı. Karar kendi verinde ölçülür, tahminle verilmez.
7. **Yapılandırılmış çıktı: `response_mime_type="application/json"` + Pydantic `response_schema`.** Şema kodda durur,
   isteme JSON tarifi yazılmaz; sınıflandırmada kapalı enum kullan (serbest metin kategori önceki bir projede onlarca
   dağınık değer üretti). Şema ŞEKLİ garanti eder, tamlığı etmez: "N girdi → N etiket" bekçisi, `SummaryParseError` gibi
   tipli ayrıştırma hatası ve hata yolunda da defter yazımı yerinde kalır (`facts`: `structured_output_guarantee`).
   3.6+ modellerde `temperature`/`top_p`/`top_k` yok sayılır, koyma (`facts`: `sampling_params_3_6`).
8. **Çok öğeli çağrı, önbelleğe güvenmeden.** Örtük önbellek var ama asgari ön ek eşiği yüksek (`facts`:
   `implicit_cache_minimum`); önceki projelerde ~500 ve ~1.500 token'lık sabit ön ek eşiğin altında kaldı, üretimde
   `cached_content_token_count` hep boştu. Kısa sistem istemini öğe başına tekrar ödememek için bir çağrıya ~10 öğe paketle
   (önceki ölçümde öğe başına tek çağrı ~3 kat pahalıydı). Paket boyunu ve aynı çağrıdaki öğelerin etiketlerinin
   birbirine bulaşıp bulaşmadığını kendi verinde ölç; önceki projede bu ayrı bir bilinmeyen olarak izlendi.
9. **429 ve kota.** Kota Gemini API'de proje başınadır, anahtar başına değil; günlük sınır Pasifik gece yarısı sıfırlanır
   (`facts`: `api_rate_limit_model`). Dakikalık `rate_limit_exceeded` beklemeyle geçer; günlük `quota_exceeded` geçmez,
   ikisini hata gövdesinden ayır. Yeni projede yeni kuşak modelin kotası düşük olabilir: önceki bir ölçümde ikinci koşuda
   429 geldi — büyük toplu işten önce kotayı kontrol et. SDK kendiliğinden yeniden denemez; `HttpOptions(retry_options=
   HttpRetryOptions(...))` ver ya da dışarıda üstel geri çekilme + jitter kur; yalnız 408/429/5xx denenir, 400/403 denenmez.
   Hataları `errors.APIError.code` ile sınıflandır. Zaman aşımı milisaniyedir (`HttpOptions.timeout`); önceki bir projede
   istemci tarafı zaman aşımı ve devre kesici eklendi. Kalıcı başarısız iş için "denendi ve bitti" durumu tut, yoksa vade
   sorgusu aynı işi sonsuza dek yeniden ödetir.
10. **Video ve YouTube URL girdisi** (önceki projelerde kullanılmadı; yalnız resmî dokümana dayanır): URL özelliği
    önizlemedir; yalnız herkese açık video, Vertex'te istek başına tek URL, API anahtarı modunda ücretsiz katmanda günlük
    süre sınırı (`facts`: `youtube_url_gemini_api`, `youtube_url_vertex`). Video token'ı saniye başına faturalanır: önce
    kırp (`start_offset`/`end_offset`) ve çözünürlüğü/`fps`'i düşür, toplam süreyi çarparak maliyeti tahmin et. Hâlihazırda
    metin transkripti varsa videoyu değil transkripti ver.
11. **Para harcayan yol tek yerde, kapı önde.** Defter + tavan + kapı tek fonksiyonda; toplu iş CLI'ları kuru çalışır, gerçek
    harcama `--go` ister, testlerde `-m live` ile ayrılır. Bütçe kapısı istisna fırlatmak yerine `(izin, sebep)` döner ki sebep
    kayda yazılsın.
12. **Yerel geliştirme:** istemci adresi `GEMINI_BASE_URL`'den okunur ve `HttpOptions(base_url=...)` ile verilir; yerelde
    mock sunucu, dışarıda gerçek uç. Prod koduna mock dalı girmez. Mock ile geçen test, gerçek çağrıyı kanıtlamaz (madde 6'daki
    sessiz bozulma mock'ta görünmezdi): model, SDK ya da şema değişiminde gerçek çağrıyla bir doğrulama turu yap.

## Araçlar

`google-genai` (`pip install google-genai`; sürüm `facts`'te; pydantic şartı sıkı, bağımlılık çakışmasını ilk build'de
yakala). API modu: `GEMINI_API_KEY` (AI Studio'dan). Vertex modu: GCP projesi + bölge (`global` önerilir),
`GOOGLE_APPLICATION_CREDENTIALS_JSON` (servis hesabı JSON içeriği) ya da yerelde `gcloud auth application-default login`.
Vertex belgelerinde ürün adı "Gemini Enterprise Agent Platform"a dönüştü; SDK'da `vertexai=True` ve `enterprise=True` ikisi de
geçerli. Fiyat ve kota panoları: AI Studio rate-limit sayfası, GCP Billing.

## Sınırlar

- Metin/çok kipli üretim çağrıları kapsamdadır; Live, TTS, görsel/video üretimi (Veo), embedding, ince ayar, Provisioned
  Throughput satın alma kapsam dışı.
- Güncel resmî dokümanlar yeni Interactions API'yi öneriyor, `generateContent` "legacy ama tam desteklenir"
  (`facts`: `interactions_api_status`). Önceki projeler `generate_content` + `response_schema` kullandı; Vertex'te
  Interactions desteği doğrulanmadı.
- Önceki bir projenin "Vertex'te otomatik önbellek yok" notu Claude-on-Vertex taramasından geliyordu; Gemini için resmî doküman
  örtük önbelleği açık varsayılan olarak tanımlıyor. Önbellek vardır, eşik yüksektir.
- Bölge başına model kullanılabilirliği ve Vertex kota sayıları değişir; bölge sayfası ve gerçek çağrıyla doğrula.
- Fiyat tarifesi tarihlidir (kesim tarihi `facts`'te); defter satırına çağrı anındaki birim fiyatı kopyala, geçmişi
  sonradan yeniden hesaplama.
