# elevenlabs — değişiklik günlüğü

## 1.0.0 — 2026-10-17

İlk sürüm. 3 projenin integration dokümanı, 2 projenin karar kayıtları ve ilgili commit mesajlarından damıtıldı (marka-izleme
ve içerik-analizi hatları, bir ses/video düzenleme aracı, bir masaüstü agent uygulamasının ücretli-transkript kararı); yöntemdeki
her uyarı o kaynaklarda yaşanmış ya da ölçülmüş bir olaya dayanır.

Olgular 2026-10-17'de resmî ElevenLabs sayfalarından (API reference, capability overview, models, pricing, changelog) doğrudan
okundu; hepsinin `checkedAt` değeri bu tarihtir. Okurken görülen ve kit'e olduğu gibi yazılan çelişkiler:

- STT dosya boyutu: capability SSS'sinde 3 GB, API reference'ta `file` için 5.0 GB. Hangisinin geçerli olduğu doğrulanamadı.
- Multichannel süre sınırı: SSS'nin bir yerinde "10 saat", özet bölümünde "1 saat". Kit yalnız standart mod (10 saat) değerini yazıyor.
- Fiyat sayfası artık "API usage is billed in US dollars, not credits" diyor; önceki projelerde ölçülen kredi/saat çevrimi
  (abonelik dönemine ait) kit'e sayı olarak alınmadı, yalnız eskimiş olabileceği notuyla anlatıldı.

Doğrulanamayan: read-timeout'ta sunucunun işi bitirip ücretlendirdiği (STT için resmî belge yok, yalnız bir projenin
araştırma notu), transkript saklama süresi, TTS için yaşanmış olay (yok; TTS yalnız resmî doküman değerleriyle yer alıyor).
