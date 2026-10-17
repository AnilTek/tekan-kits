---
name: elevenlabs
description: How to use ElevenLabs speech-to-text (Scribe, scribe_v2, /v1/speech-to-text, transcription_id, diarize, timestamps_granularity, source_url) and text-to-speech from code without paying twice or losing paid output — approval before paid runs, no automatic retry on a paid call, caching by audio hash, recovering a paid transcript, credit vs dollar accounting. Use whenever code calls api.elevenlabs.io, reads ELEVENLABS_API_KEY or ELEVENLABS_BASE_URL, transcribes audio or video with diarization or word timestamps, hits quota_exceeded or a read timeout on a paid call, or rotates an ElevenLabs API key.
---

# elevenlabs

## Ne

ElevenLabs'in ücretli ses API'lerini (ağırlıklı olarak Scribe ile konuşmadan metne, ayrıca TTS) koddan kullanırken
"aynı sesi iki kez ödemeden ve ödenmiş çıktıyı kaybetmeden" çalışma yöntemi: onay, önbellek, yeniden deneme kuralı,
kurtarma, muhasebe.

## Neyi çözer

Önceki projelerde yaşanmış, hepsi para ya da ödenmiş veri kaybettiren olaylar (bu projede değil — kullanıcıya böyle aktar):

- **Boş transkript hata sayıldı, video başına üç kez ödendi.** Konuşması olmayan iki kısa film için sağlayıcı doğru
  davranıp boş metin döndürdü; kod bunu "yazamadım" saydı ve işi yeniden denedi. Kurtarma yolu (ödenmiş kimliği ücretsiz
  GET ile çekmek) aynı boş metni getirdi, "kurtarma başarısız" deyip ücretli yola düştü. Yokluk geçerli bir sonuçtur.
- **Ödenmiş zaman bilgisi kalıcılaştırmada düştü.** Sağlayıcı her kelime için başlangıç/bitiş döndürüyordu; kod yalnız
  konuşmacı değişimine bakıp kesiyordu. 227 transkriptin %92'si tek segment, zaman hizasız kaldı. Düzeltme ücretsiz GET
  ile yapıldı, çünkü ham yanıt kimlikle geri alınabiliyordu.
- **Anahtar değişince eski transkriptler 404 verdi.** 227 kurtarmanın 19'u 404'tü; sınır, anahtarın değiştirildiği ana
  denk geldi (zaman tabanlı saklama bunu üretemez). Eski anahtar elde olduğu için ücretsiz kurtarıldı. İlk teşhis
  ("saklama süresi doldu") yanlıştı: örneklem alfabetik sırayla seçilmişti.
- **Bayat kimlik kurtarmayı bozdu.** Penceresiz "çift ödeme kalkanı", haftalar sonra yeniden denenen işte eski bir
  kimlik buldu; sağlayıcı tanımadı, GET patladı, video hiç transkript almadı. Kalkan kısa bir pencereyle sınırlandı.
- **Read-timeout'ta sunucu işi bitirip ücretlendirebilir.** Yanıt gelmediği için kimlik de yok, kurtarma imkânsız.
  Otomatik yeniden deneme bu yüzden iki kez ödetir.
- **Defter dolar, kota kredi sayıyor.** Bütçe freni krediyi göremedi; defterde para kalmış görünürken sağlayıcı kotası
  bitmeye yaklaşabildi. Kalan krediden türetilen kredi/saat oranı 3,5 kat yanlış çıktı (sayaç hesabın aylardır süren
  kullanımını da içeriyordu); oran yalnız temiz anahtarla ölçülünce güvenilir oldu.
- **`quota_exceeded` hesap düzeyindedir.** Aynı anahtarla yeniden denemek aynı hatayı alır; kod bunu normal iş hatası
  sayıp deneme hakkı yaktı.
- **Otomatik dil algılaması yanılıyor.** 16 sesin 6'sında yanlış dil çıktı (Türkçe bir ses %99 güvenle İtalyanca).
  Dili zorlamak da başka dildeki sesi bozuyor.

## Doğruluk kaynakları

- Create transcript (parametreler, limitler): https://elevenlabs.io/docs/api-reference/speech-to-text/convert
- Get transcript (kimlikle geri alma): https://elevenlabs.io/docs/api-reference/speech-to-text/get
- Özellikler, SSS, dosya limitleri: https://elevenlabs.io/docs/overview/capabilities/speech-to-text
- Model kimlikleri ve TTS karakter sınırları: https://elevenlabs.io/docs/overview/models
- Fiyatlar: https://elevenlabs.io/pricing/api · Değişiklik geçmişi: https://elevenlabs.io/docs/changelog
- **Sayıları bu dosyanın yanındaki `kit.yaml` → `facts`'ten oku** (kaynağı ve kontrol tarihiyle); ezberindeki fiyat,
  limit ve model adı eski olabilir. Resmî sayfalar kendi içinde çelişebiliyor (dosya boyutu için 3 GB ve 5 GB geçiyor):
  çelişkiyi olduğu gibi aktar, tahmin yürütme.

## Yöntem

1. **Her ücretli çalıştırma açık onayla başlar.** Onay ekranı ses süresini ve "ses ElevenLabs'e gönderilir" uyarısını
   gösterir; ücret tahmini uydurma, süreyi `facts`'teki saat fiyatıyla çarpıp "yaklaşık" diye göster. Toplu/onarım
   betiklerinde ücretli yol varsayılan KAPALI (`--allow-paid` gibi açık bayrak).
2. **Ücretli çağrı otomatik yeniden denenmez.** Read-timeout, bağlantı kopması ya da belirsiz sonuçta dur; kullanıcı
   isterse yeniden başlatır. Yalnız connect-timeout ve iş başlamadan reddedilen 4xx ücretsiz sayılır. Auth, kota ve
   429 hesap düzeyindedir: yedek yol deneme, işi ötele (deneme hakkı yakma).
3. **Aynı sesi bir kez öde: ses özetine (hash) göre önbellek.** Ham yanıtı olduğu gibi sakla (`words[]`, kelime
   zamanları, `speaker_id`, `audio_duration_secs`, `transcription_id`). Dosya adı değil içerik özeti anahtar olsun; model,
   dil ve diarization ayarı da anahtara girsin, yoksa ayar değişince eski çıktı döner.
4. **Kimliği ödemeden hemen sonra, başka hiçbir okumadan önce deftere yaz.** Ödenmiş kimlik ücretsiz GET ile geri alınır
   (`facts` → `stt_get_transcript`). Çağrı ile defter yazımı arasında veritabanı okuması bırakma: patlarsa para gider,
   kayıt kalmaz. Kurtarma kalkanının penceresi kısa olsun; bayat kimlikte GET başarısızsa ücretli yola ancak onayla düş.
5. **Anahtarı değiştirmeden önce kurtarılacakları çek.** Transkriptler anahtarın/hesabın kapsamındadır; sonradan
   erişilemez. Saklama süresi bilinmiyor, uzun süreli kurtarmaya güvenme. Kurtarmayı kapatacak ayarlara dikkat:
   zero retention modunda transkript saklanmaz (`facts` → `stt_zero_retention`).
6. **Boş metin geçerli sonuçtur.** Konuşmasız ses için boş satırı yaz, işi "bakıldı" say, yeniden deneme. "Veri yok" ile
   "konuşma yok" ayrı değerle tutulsun. Sonuç şüpheliyse (uzun videoda 0 karakter) operatör onayıyla doğrula.
7. **Model: güncel Scribe neslini seç** (kimlik `facts` → `stt_models`'ten). Önceki ölçümde v2 nesli azınlık
   konuşmacıda v1'e göre belirgin iyiydi (%76 → %99); eski kimliği varsayılan bırakma. Kelime zamanı ve konuşmacı ayrımı gerekiyorsa `timestamps_granularity=word` ve `diarize=true`; `character`
   yanıtı gereksiz şişirir. `num_speakers` verilirse üst sınırdır. Anahtar kelime ve transkript düzenleme eklentileri
   ayrıca ücretlidir (`facts` → `stt_addon_prices`): istenmeden açma.
8. **Dil: otomatik algılamaya körü körüne güvenme.** Önemli seslerde iki okuma (otomatik + zorlanmış dil) al ve ikisini
   birlikte sakla; ek maliyeti saat fiyatıyla oranla ve onayda göster. Dil güveni (`language_probability`) yüksek olsa da
   yanlış çıkabilir.
9. **Girdi ve süre.** Limitler `facts`'te (`stt_file_limits`). Uzaktan girdi için `source_url`; `cloud_storage_url`
   kullanımdan kalkıyor. Platform bağlantısı (YouTube vb.) gerçek bir işlem hattında resmî olmayan bir yüzeye
   dayanabilir: kendi indirdiğin sesle çalışan bir yedek yol bırak ve hangisinin kullanıldığını logla. Uzun ses dakikalar
   sürebilir (3 saatlik ses için ~6 dk ölçüldü): senkron çağrıyı olay döngüsünü bloklamayacak biçimde (thread) çalıştır,
   zaman aşımını en kötü duruma göre ver, takılı-iş süpürücüsünün eşiğini ondan büyük tut ki iş yeniden gönderilip
   ikinci kez ödenmesin.
10. **`webhook=true` kullanmadan önce webhook tanımlı mı bak.** Önceki ölçümde tanımsızken 400 döndü; STT batch
    webhook'larında otomatik yeniden deneme yoktu ve webhook workspace düzeyinde olduğundan yerel ve canlı ortam aynı
    seti paylaşır. Basit hatlarda senkron çağrı daha az yüzey açar.
11. **Muhasebe: dolar ve kredi ayrı.** Defteri `audio_duration_secs` (yanıttan okunan gerçek süre) ile tut, tahmine
    güvenme. Aboneliğe bağlı kotada kredi sayılıyor; çevrimi yalnız temiz bir anahtarla ölç ve defter eksik yazıyorsa
    fiyat tablosunu güncelle (`facts` → `api_billing_unit`: API artık dolar faturalıyor, eski kredi ölçümleri
    eskimiş olabilir).
12. **TTS.** Faturalama karakter başınadır ve istek başına karakter sınırı modele bağlıdır (`facts` →
    `tts_price_per_1k_chars`, `tts_character_limits`): göndermeden önce karakteri say, modeli sınıra ve fiyata göre
    seç, metni sınırın altında parçala ve aynı onay/önbellek/yeniden-deneme kurallarını uygula.
13. **Yerel geliştirme:** istemci adresi `ELEVENLABS_BASE_URL`'den okunur (varsayılan `https://api.elevenlabs.io`);
    yerelde sahte sunucu, dışarıda gerçek API. Prod koduna mock dalı girmez; testler sahte sunucuya bağlanır, anahtar
    `ELEVENLABS_API_KEY`, değeri argv'ye, loga ve olaya yazma.

## Araçlar

`ELEVENLABS_API_KEY` (ElevenLabs → Settings → API Keys). Ham REST (`POST /v1/speech-to-text`, multipart) ya da resmî
SDK'lar. Ses çıkarma için `ffmpeg`, platform bağlantısından indirme için `yt-dlp` (yedek yol).

## Sınırlar

- Kanıtın çoğu Scribe (STT, toplu mod) üzerinden: TTS için bu kit yalnız resmî dokümandan doğrulanmış maliyet ve limit
  bilgisi verir; TTS'te önceki projelerde yaşanmış bir çift ödeme/kayıp olayı yok. Read-timeout'ta faturalama için
  TTS tarafında topluluk raporları var, STT için resmî belge yok: davranış doğrulanmış değil, bu yüzden "otomatik yeniden
  deneme yok" kuralı temkin olarak durur.
- Kapsam dışı: müzik üretimi, ses klonlama, ElevenAgents, gerçek zamanlı (WebSocket) STT, tıbbi model ayrıntıları.
- Transkript saklama süresi bilinmiyor (en az ~9,6 saat kanıtlandı); kimlikle kurtarmayı kalıcı arşiv sayma.
- Doğruluk (WER) önceki ölçümlerde resmî referansla değil, modeller arası tutarlılıkla değerlendirildi.
- Kredi/saat çevrimi ölçüldüğü tarihteki plana aittir; fiyat modeli değişti, kendi hesabında yeniden ölç.
