---
name: google-trends
description: How to get Google Trends numbers into a pipeline that you can trust and compare — what the 0-100 index means (relative, per request), sampling noise, zero-inflated low-volume terms, timeframe/geo/category params, top vs rising queries, trending searches, Google Trends API alpha vs Apify actors (APIFY_TOKEN, google-trends-scraper, google-trends-fast-scraper) vs pytrends. Use whenever code pulls or compares Google Trends data, a Trends series "changes between pulls", an actor run SUCCEEDED but the data is empty or for the wrong country, or someone asks which term is searched more.
---

# google-trends

## Ne

Google Trends verisini (arama ilgisi) bir veri hattına almanın ve ondan karar çıkarmanın yöntemi: hangi kaynaktan çekilir,
0-100 indeksi neyi ölçer ve neyi ölçmez, hangi sayılar birbiriyle karşılaştırılabilir, hangi çekim "başarılı" görünüp
boştur. Tek iş: **Google Trends sayılarını güvenebileceğin ve karşılaştırabileceğin hale getirmek.**

## Neyi çözer

Daha önceki projelerde yaşanmış ve ölçülmüş sorunlar (bu projede değil, kullanıcıya böyle aktar):

- **Aynı terim iki farklı çekimde farklı sayı verdi.** İndeks her istekte, o isteğin penceresindeki en yüksek noktaya göre
  yeniden ölçeklenir. Günlük 3 aylık çekim ile haftalık 12 aylık çekimin aylık değişimi, sürekli serilerde bile birbirine
  yakınsamadı (büyüklük 19 puana kadar saptı); **yön** ise 9 terimin 9'unda aynı çıktı.
- **Düşük hacimli terimlerde sayı gürültüydü.** Aynı pencerede, 25 dakika arayla ve taze örnekle tekrar çekilen bir seride
  aylık değişim -%6'dan +%26'ya, bir markada +%15'ten +%68'e kaydı. Hacmi yeterli sürekli serilerde aynı fark 1 puanın altındaydı.
- **"Aynı sonuç" kararlılık sanıldı.** Aynı gün tekrar çekimlerin yaklaşık yarısı birebir aynı seriyi döndü: bu önbellek,
  kararlılık kanıtı değil.
- **Başarılı koşu boş ya da yanlış ülke çıktı.** Fast actor'e `mode` gönderilmeyince `keyword`, `geo` ve zaman aralığı
  sessizce yok sayıldı ve başka ülkenin trend listesi geldi; koşu `SUCCEEDED`, ücret kesildi. Aynı sınıf hata iki projede görüldü (eski
  bir actor'de kayıp bayrak boş zaman serisi, yenisinde başka ülkenin listesi verdi) ve biri sağlayıcının kendi şeması "mode yok"
  dediği için tekrarlandı. Resmî actor'de ise başarısız koşular `SUCCEEDED` + boş veriyle
  bitti ve başarılı koşunun 15-20 katı ücretlendi.
- **Tek terimin geçici ağ hatası tüm koşuyu öldürdü.**

## Doğruluk kaynakları

- İndeks tanımı, normalizasyon, örnekleme, gürültü: https://support.google.com/trends/answer/4365533
- Top / rising / Breakout: https://support.google.com/trends/answer/4355000 · karşılaştırma: https://support.google.com/trends/answer/4359550
- Resmî API (alpha): https://developers.google.com/search/apis/trends · duyuru: https://developers.google.com/search/blog/2025/07/trends-api
- Actor sayfaları (fiyat, girdi/çıktı): https://apify.com/apify/google-trends-scraper · https://apify.com/data_xplorer/google-trends-fast-scraper
- **Sayıları bu dosyanın yanındaki `kit.yaml` → `facts`'ten oku** (kaynağı ve kontrol tarihiyle); ezberindeki değer (fiyat, kota,
  API erişimi, actor alanları) eski olabilir. Önceki projelerin dokümanındaki fast actor fiyatı bugünkü sayfadan farklıydı.

## Yöntem

1. **Kaynağı soruya göre seç.** Resmî API alpha ve erişim başvuruyla; ölçeği istekler arasında tutarlı olduğu için
   erişimin varsa onu tercih et (durum ve aralık: `facts`). Erişim yoksa önceki projelerde iki Apify actor'ü kullanıldı:
   terim eğrisi ve bölge dağılımı için `data_xplorer/google-trends-fast-scraper`, **yükselen / en çok aranan sorgular** için
   `apify/google-trends-scraper`. Fast actor yedi koşunun yedisinde `related_queries` vermedi. `pytrends` / doğrudan
   kazıma önceki projelerde kullanılmadı (bkz. Sınırlar).
2. **İndeksi mutlak sayı gibi okuma.** Web'deki 0-100 her istekte yeniden ölçeklenir; "100" o penceredeki en yüksek noktadır.
   Bu yüzden: iki ayrı çekimin seviyesini toplama, ortalama alma, "hangi terim daha çok aranıyor" diye kıyaslama. Mutlak
   hacim gerekiyorsa Trends doğru araç değil.
3. **Karşılaştırılacak her şeyi aynı istekte çek.** Önceki bir projede aylık değişim için önceki **iki tam ay tek istekte**
   çekildi (aynı normalizasyon), değişim yüzdesi hesaplanıp yalnız o saklandı; ham seviye saklanmadı. Farklı kaynaklar
   arasında (ör. Trends ile trafik verisi) yalnız **yön** karşılaştırıldı.
4. **Pencereyi sabit tut ve kaydet.** `timeframe`, `geo`, `category`, çekim tarihi ve kullanılan actor/sürüm her satırla
   saklanır. Günlük ayrıntı yalnız kısa pencerede (actor ölçümünde ~90 gün ve altı) gelir; uzun pencerede aylık gelir.
   Günlük 3 aylık ve haftalık 12 aylık seriyi birbirine karıştırma: farklı cetveller.
5. **Düşük hacmi tanı, yüzde üretme.** Google düşük hacimli terimi "0" gösterir ve gürültü orada belirgindir. Aydan birinin
   medyanı 0 ise (ya da gün payının yarısına yakını 0 ise) değişim yüzdesi yayımlama, satırı "belirsiz" işaretle. Önceki
   projede güvenilirlik üç kademeydi (yüksek / orta / belirsiz); eşikler ölçümle kalibre edildi, kendi veride yeniden ölç.
   Terim seçerken marka, tür ve tema terimlerini seç; tek tek ürün kodları düz sıfır döner.
6. **Spike'ı olay say, trend sayma.** Önceki projede medyanın 3 katını aşan gün ay ortalamasından çıkarıldı ve ayrıca
   kaydedildi ("olay, trend değil"). `isPartial` işaretli son (eksik) kovayı momentum hesabına katma.
7. **Tekrar çekimi önbellek farkındalığıyla oku.** Fark sıfırsa bunu kararlılık sayma; gürültüyü ölçmek için taze örnek gerekir.
8. **Top ve rising farklıdır.** Top: terimle aynı oturumda en sık aranan sorgular. Rising: önceki döneme göre en çok büyüyen
   sorgular, yüzde artışla; çok hızlıysa "Breakout" (eşik `facts`'te). Rising küçük tabandan büyüdüğü için tek başına
   hacim göstermez: top ile birlikte oku.
9. **Trend listesi talep verisi değildir.** Fast actor'ün `trending` kipinde hacim kovalıdır ("500K+"), kesin sayı yok.
   Küçük maddelerde ilgili terim sayısı 1-2'ye düşer ve sınıflandırma çözemez. Bir alan için süzüldüğünde önceki projede
   listenin ~%99'u alan dışıydı ve anahtar kelime süzgeci dizi adlarını yemek sandı. Liste, kendi terimlerini Trends'e
   **sormanın** yerine geçmez; ancak gündem alarmı olarak işe yarar. Maliyet madde sayısından bağımsız ölçüldü (tüm liste tek
   kayıt): kesilmiş 25 yerine geniş (`trendingSearchesMaxItems` üst sınırı `facts`'te) saklamak ek maliyet getirmedi.
10. **Actor'ü sessiz boşluğa karşı koru.** (a) `mode` ve `geo`'yu her çağrıda açıkça gönder; şemaya değil çalışan girdiye
    güven. Çıktıda istenen anahtar kelimenin zaman serisinin gerçekten olduğunu doğrula. (b) Boş sonucu başarı sayma, reddet.
    (c) Çalışma süresine üst sınır, `maxRequestRetries` düşük, tek koşuda terim sayısına koruma koy: maliyeti başarısız
    terimlerin yeniden denemesi şişirir. (d) Her terim ayrı yalıtılır; bir terimin hatası koşuyu öldürmez, koşu `partial` biter.
    Bazı terimler için Google hiç seri döndürmez; kronik boşları "hata" değil "veri yok" olarak kaydet.
11. **Yerel geliştirme:** actor çağrılarının adresi `APIFY_BASE_URL`'den okunur; yerelde sahte (mock) sunucu, dışarıda
    gerçek API. Prod koduna mock dalı girmez. Token `APIFY_TOKEN`.

## Araçlar

`APIFY_TOKEN` (Apify). İstemci: ham HTTP (`run-sync-get-dataset-items` ucu önceki projelerde yeterli oldu) ya da resmî
Apify istemcisi. Resmî Trends API için Google'a alpha başvurusu. Proxy: kullanılan actor'lerden birinde kaynak
projedeki hesapta `RESIDENTIAL` proxy alanı HTTP 400 verdi; alan gönderilmeyince çalıştı. Kendi hesabında dene.

## Sınırlar

- Mutlak arama hacmi yok; Trends göreli ilgidir. Mutlak sayı için önceki projeler Google Ads Keyword Planner'ı
  alternatif olarak not etti ama kullanmadı.
- `pytrends` ve doğrudan kazımanın neden kırıldığı bu kit'in kaynak projelerinde ölçülmedi: orada yalnız "actor'ler daha
  bakımlı" gerekçesiyle seçildi. Kırılganlık iddiasını kanıt olmadan aktarma; kullanacaksan kendin ölç.
- Resmî actor'ün güvenilirliği ölçümler arasında farklı: bir ölçümde 17 denemenin 4'ü, sonrakilerde 7 terimin 1'i ve 10 terimin
  5'i başarılı; actor sayfasındaki başarı oranı çok daha yüksek. Sayfa istatistiğine değil kendi ölçümüne güven.
- Hesabın aynı anda birkaç actor'ü kullanıyorsa koşu maliyeti faturadan ayrıştırılamaz: koşunun kendi
  `usageTotalUsd` ve `chargedEventCounts` alanlarını kaydet.
- Ortak "çapa terim" ile ayrı çekimleri birbirine bağlama yaklaşımı kaynak projelerde denenmedi; Google'ın önerdiği yol aynı
  istekte karşılaştırmak (sınır `facts`'te). Çapa kullanacaksan bağlama hatasını önce ölç.
- Trend listesi RSS'i (`facts`'te madde sayısı) yalnız sağlık kontrolü ya da yedek olarak değerlendirildi.
- Google'ın yaptığı filtreler (çok az kişinin aradığı terimler, kısa sürede tekrarlanan aramalar, özel karakterli sorgular,
  Google ürünlerinin kendi iç aramaları) sayıya yansır; Trends bir anket değil, tam bir ayna da değil.
