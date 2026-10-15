---
name: youtube-data-api
description: How to use the YouTube Data API v3 without wasting quota or fetching the wrong channel — channel lookup by handle, video discovery via the uploads playlist, stats refresh, Shorts detection, quota buckets. Use whenever code calls the YouTube Data API (googleapis youtube v3, YOUTUBE_API_KEY), resolves a channel from a @handle, lists a channel's videos, refreshes view/like counts, or hits quotaExceeded.
---

# youtube-data-api

## Ne

YouTube Data API v3'ü (herkese açık veri, API anahtarıyla) kotayı boşa harcamadan ve yanlış kanala gitmeden kullanma
yöntemi: kanal çözme, video keşfi, istatistik tazeleme, Shorts tespiti, kota bütçesi.

## Neyi çözer

İki pahalı hata tekrar ediyor: (1) kanalı `search.list(q="@handle")` ile bulmak — "en alakalı" tahmini döner, handle'ı
dikkate almaz; ilk sonuç alakasız küçük bir kanal çıktı ve doğrulanmadan kabul edildiği için yanlış kanalın
içeriği için ücretli işlem başladı. (2) Video keşfini `search.list` ile yapmak — günde 100 çağrılık ayrı kovayı hızla
bitirir. İkisinin de ucuz ve kesin karşılığı var.

## Doğruluk kaynakları

- Kota tablosu: https://developers.google.com/youtube/v3/determine_quota_cost
- Değişiklik geçmişi (kota modeli burada değişir): https://developers.google.com/youtube/v3/revision_history
- `channels.list` filtreleri: https://developers.google.com/youtube/v3/docs/channels/list
- Değişen değerler (kota, kova, maliyet) `kit.yaml` `facts`'te kaynağı ve kontrol tarihiyle durur; buradaki metin onlara
  dayanır, sayıyı oradan oku.

## Yöntem

1. **Kanal çözme: `channels.list(forHandle=...)`** (`@` isteğe bağlı) — kesin eşleşme, 1 birim. `search.list` ile kanal
   arama yapma. Eski Python istemcisinin (`google-api-python-client`) gömülü discovery dokümanında `forHandle` yoksa
   `TypeError` alırsın: istemciyi güncelle ya da bu tek çağrıyı ham REST ile yap.
2. **Video keşfi: uploads playlist.** Kanalın `contentDetails.relatedPlaylists.uploads` kimliğini **bir kez** al ve
   sakla; sonra `playlistItems.list` (sayfa başına 50, 1 birim). `UC…→UU…` dönüşümü çalışır ama belgeli garanti değil —
   kimliği API'den al. Tarih aralığında erken durma **sayfa bazında**: liste sırası kesin monoton değil, tek öğede durma.
3. **`playlistItems` sunucuda arama yapmaz.** Anahtar kelime filtresi istemcide; bir sayfa sınırı koy ve yanıtta
   "taranan / sayfa / kesildi" bilgisini döndür ki "kelime yok" ile "derine bakmadık" ayrılsın.
4. **İstatistik tazeleme:** `videos.list` 50 kimlik/çağrı, 1 birim. Yalnız sayaç (izlenme, beğeni, yorum, süre,
   yayın zamanı) gerekiyorsa `videos.batchGetStats` (1 birim, çoklu kimlik) daha uygun.
5. **Sayfalama:** `nextPageToken` ile her sayfa ayrı istek, tam maliyet. Sayfa ortasında geçici hata olursa o ana kadar
   toplananı koru.
6. **Shorts tespiti:** API'de resmî alan yok. `HEAD https://www.youtube.com/shorts/<id>` → Short ise 200, normal video
   ise 303 (`/watch?v=`). Var olmayan kimlik de 200 döner: önce `videos.list` ile varlığı doğrula. Süre eşiği kullanma
   (19 saniyelik normal video ölçüldü).
7. **Kota bütçesi:** her çağrıyı birimiyle say ve günlük toplamı kaydet. `search.list`'i yalnız "platform genelinde
   anahtar kelimeyle ara" için, elle ve tur başına sayarak kullan. Kova sıfırlanması Pasifik saatiyle gece yarısı.
8. **Yerel geliştirme:** istemci adresi `YOUTUBE_BASE_URL`'den okunur; yerelde mock, dışarıda gerçek API. Anahtar
   `YOUTUBE_API_KEY`; herkese açık veri için OAuth gerekmez.

## Araçlar

`YOUTUBE_API_KEY` (Google Cloud Console → APIs & Credentials). İstemci: resmî `googleapis` / `google-api-python-client`
(güncel sürüm) ya da ham REST (`https://www.googleapis.com/youtube/v3/...`).

## Sınırlar

- Yalnız herkese açık veri ve API anahtarı. Yükleme, OAuth, YouTube Analytics / Reporting API kapsam dışı.
- `videos.batchGetStats`'in hangi kovaya yazıldığı kaynaklarda çelişkili (kendi kovası mı, ortak 10.000 mi); en fazla
  kaç kimlik aldığı belgede yok. Kullanmadan önce kendi projende ölç.
- Most-replayed (heatmap) API'de yok; `yt-dlp` gibi araçlarla alınır ve yeni videoda ~7 gün sonra oluşur — "yok"
  sonucunu kalıcı sayma, zamana bağlı yeniden dene.
- İzlenme sayımı 2026-08-27'de tüm formatlarda "oynatma başladığı an"a geçti (Shorts için 2025-03-26'dan beri):
  `viewCount` zaman serileri o tarihte kırılır.
