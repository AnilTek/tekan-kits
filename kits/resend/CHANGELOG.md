# resend — değişiklik günlüğü

## 1.0.1 — 2026-10-18

- Görünen ad İngilizce: "Resend transactional email" (arayüz dili İngilizce; Türkçe ad uygulama branch'inin adını da bozuyordu).

## 1.0.0 — 2026-10-17

İlk sürüm. Yöntem, 3 projenin kaynaklarından damıtıldı: biri tam bir işlem e-postası kararı ve entegrasyon dokümanı
(gönderen, DNS, anahtar, süre sınırı, arıza tablosu, yerel Mailpit), ikisi kurulum rehberi / kod / ortam dosyaları (sandbox
gönderenin varsayılan kalması, anahtar yokken kodu log'a yazan dal, farklı listelenen DNS kayıtları).

- Limit, kota, oran, idempotency, test adresi, SMTP ve DNS süresi olguları 2026-10-17'de resmî Resend dokümanından (HTML
  sayfaları doğrudan okunarak) ve Mailpit dokümanından doğrulandı; `kit.yaml` → `facts` her biri kendi kaynak URL'siyle.
- Proje dokümanlarındaki iki değer resmî kaynakla çelişti ve resmî kaynak esas alındı: ücretsiz katman alan adı sayısı
  (dokümanda 1, resmî kaynakta 3) ve varsayılan hız sınırı (resmî kaynakta saniyede 10 istek).
- Doğrulanamayan: alan adı doğrulama panelindeki kayıt tiplerinin güncel listesi (panel hesap gerektirir; kit yalnız "panelden
  kopyala" der). Idempotency'nin yeniden-deneme gerekçesi (zaman aşımına uğrayan isteğin ulaşmış olabileceği) resmî
  davranıştan türetilmiş bir çıkarımdır, projelerde yaşanmış bir olay değildir; SKILL.md'de böyle işaretli.
- SMTP ile tek kod yolu önerisi (üretimde `smtp.resend.com`, yerelde Mailpit) resmî SMTP ve Mailpit dokümanlarından türetildi;
  sahada denenmedi, SKILL.md'de böyle işaretli.
