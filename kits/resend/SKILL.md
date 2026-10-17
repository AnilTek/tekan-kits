---
name: resend
description: How to send transactional email (magic link, OTP / verification code, invite) with Resend so it actually arrives, and never send real mail from a local environment — domain verification (SPF/DKIM/DMARC DNS records), EMAIL_FROM, onboarding@resend.dev sandbox sender, RESEND_API_KEY, 403 "You can only send testing emails to your own email address" / "domain is not verified", 429 rate and quota errors, idempotency keys, suppression list, Mailpit instead of real sends locally, resend.dev test addresses. Use whenever code calls api.resend.com or smtp.resend.com, reads RESEND_API_KEY or EMAIL_FROM, or an auth flow's email never shows up.
---

# resend

## Ne

Resend ile işlem e-postası (giriş kodu, doğrulama, davet, magic link) göndermenin yöntemi: alan adı doğrulama, gönderen
adresi, anahtar yönetimi, hata ayrımı, yeniden deneme, kota ve yerelde gerçek posta gitmemesi. Pazarlama e-postası kapsam dışı.

## Neyi çözer

Önceki projelerde görülenler (bu projede değil — kullanıcıya böyle aktar):

- Giriş kodu e-postası iki projede kritik yoldaydı: ulaşmazsa kimse giremez. Biri staging'de sağlayıcı bağlı olmadan
  açılmış, her gönderim log'a sessiz bir hata düşmüştü; fark edilmesi geç oldu.
- Bir projede varsayılan gönderen `onboarding@resend.dev` olarak üretim ortam dosyasında, compose'ta ve config
  varsayılanında duruyordu. Bu adres yalnız hesap sahibinin kendi adresine gönderebilir; başkasına giden her istek 403 alır.
  Çağıran taraf yalnız `email_sent: false` gördü.
- Bir kurulum rehberinde örnek kod, anahtar yoksa doğrulama kodunu log'a yazıp dönüyordu (`[DEV]` dalı). Üretimde anahtar
  eksik kalırsa kod sessizce log'a sızar ve e-posta gitmez. Başka bir projede canlıda anahtar yoksa servis hiç başlamıyor.
- Aynı projenin iki dokümanı Resend'in DNS kayıtlarını farklı tiplerle (SPF TXT kökte / `send` altında MX+TXT, DKIM CNAME / TXT)
  listeledi: kayıtlar Resend'in ürettiği değerlerdir, ezberden yazılmaz.
- Ücretsiz katman bir projenin dokümanında "tek alan adı" diye kayıtlıydı; resmî kaynakta sayı farklı. Doküman eskir.
- Tek bir kişiye e-posta gitmiyor, log'da hata yok: kalıcı geri dönüşten sonra adres suppression listesine girer ve
  Resend o adrese sessizce göndermeyi bırakır.

## Doğruluk kaynakları

- Alan adı: https://resend.com/docs/add-a-domain · DMARC: https://resend.com/docs/dashboard/domains/dmarc
- Limitler: https://resend.com/docs/api-reference/rate-limit · https://resend.com/docs/knowledge-base/resend-sending-limits
- Hata kodları: https://resend.com/docs/api-reference/errors · Idempotency: https://resend.com/docs/dashboard/emails/idempotency-keys
- Test adresleri: https://resend.com/docs/dashboard/emails/send-test-emails · SMTP: https://resend.com/docs/send-with-smtp
- **Sayıları bu dosyanın yanındaki `kit.yaml` → `facts`'ten oku** (kaynağı ve kontrol tarihiyle); ezberindeki kota, oran
  ve alan adı sayıları eski olabilir. Bir limit söylerken `facts`'teki değeri ve tarihini kullan.

## Yöntem

1. **Gönderen adresi doğrulanmış alan adından olsun.** `EMAIL_FROM` (`Ad <adres@dogrulanmis-alt-alan>`) Resend'de **Verified**
   alan adıyla aynı olmalı. `onboarding@resend.dev`'i yalnız ilk elle deneme için kullan; `.env.example`, compose, üretim
   dosyası ya da kod varsayılanı olarak bırakma. İşlem e-postası için ayrı alt alan adı kullan (itibar ayrımı; resmî öneri).
2. **403'ün iki yüzü var:** "You can only send testing emails to your own email address" (sandbox gönderen) ve
   "The … domain is not verified" (`from` alanı doğrulanmış alan adında değil). İkisinde de önce `from`'a bak.
3. **DNS kayıtlarını panelden birebir kopyala** (SPF, DKIM, dönüş yolu; tipler panele göre değişir). CNAME'i proxy'leme
   (Cloudflare turuncu bulut doğrulamayı engeller). Süreyi `facts`'ten oku; bitmeden "çalışmıyor" deme, kayıtların
   görünürlüğünü bir DNS aracıyla kontrol et. DMARC `p=none` ile başlar; teslim ve geçme doğrulanınca sıkılaştırılır.
4. **Anahtar:** yalnız gönderim yetkili, ortam başına ayrı, sır deposunda; `RESEND_API_KEY` env'i. Log'a ve hata mesajına
   anahtar ya da tam alıcı adresi girmesin (maskele). Üretimde anahtar yoksa **servis başlamasın**; yoksa sessiz
   "gönderildi" ya da kodu log'a yazma dalı doğar.
5. **Gönderimi bekle, süre sınırı koy.** Sunucusuz platformlar yanıttan sonra işlemciyi kısar; arka plana atılan gönderim
   yarıda kalabilir. Önceki projelerden birinde süre 1 sn (kod isteğinin yanıt süresi sabit kalsın diye), diğerlerinde 10-30 sn
   idi: süre bir karardır, bilinçli seç.
6. **Hatayı görünür kıl.** Kullanıcıya dönen yanıt aynı kalabilir (adres sızdırmamak için), ama log'da durum kodu olsun ya da
   çağırana `email_sent` gibi bir bayrak dön. Ayırt et: 401 anahtar geçersiz/silinmiş · 403 alan adı/sandbox · 429 hız
   mı kota mı (hata `name`'i `daily_quota_exceeded` / `monthly_quota_exceeded` ise kota; değilse oran) · zaman aşımı.
7. **Yeniden deneme = aynı Idempotency-Key.** Zaman aşımına uğrayan istek Resend'e ulaşmış olabilir; anahtarsız yeniden
   deneme ikinci bir kod e-postası demektir. Anahtarı `<olay>/<varlık-id>` biçiminde kur; kuralları (süre, 409'lar)
   `facts`'ten oku. (Bu madde resmî dokümandan; önceki projelerde idempotency kullanılmamıştı.)
8. **Oran ve kota:** limitler takım başına, tüm anahtarlar ortak; toplu gönderim tek istek sayılır. Ücretsiz katmanda günlük
   kota UTC gününe göre sıfırlanır, her alıcı ayrı sayılır; test adreslerine gönderim de kotadan düşer.
9. **Teslim edilmeyen tek kişi:** log temizse Resend panelinde **Suppressions**'a bak; nedenini giderip çıkar, yoksa yeniden
   eklenir. Haberdar olmak için `suppression.added` webhook'u var.
10. **Yerel: gerçek posta gitmez.** Servis adresi env'den okunur; yerelde Mailpit (compose'ta ayrı sahte sunucu),
    dışarıda gerçek Resend. Resend aynı hesapla SMTP röle de sunduğundan (`facts` → `smtp_relay`) tek bir SMTP istemcisi
    yeterli: üretimde `smtp.resend.com` + API anahtarı, yerelde `localhost` + Mailpit portu (`facts` → `mailpit_default_ports`);
    prod koduna mock dalı girmez. Yerel `.env`'e gerçek `RESEND_API_KEY` koyma. Önceki bir projede Resend'e HTTP ile
    gidilip yerelde ayrı bir Mailpit gönderici seçiliyordu (anahtar varsa Resend önce gelir: yerel `.env`'deki gerçek anahtar
    gerçek posta demekti). SMTP tek-kod-yolu önerisi resmî dokümanlardan türetildi, sahada denenmedi.
11. **Staging'de gerçek akış:** teslim, geri dönüş ve şikâyet senaryolarını `resend.dev` test adresleriyle dene (`facts` →
    `test_addresses`); sahte adrese göndermek itibarı bozar. Kod çıktısını yerelde Mailpit'ten, staging'de gerçek
    kutudan doğrula.

## Araçlar

`RESEND_API_KEY`, `EMAIL_FROM` (Resend panelinde Domains + API Keys). İstemci: resmî SDK ya da ham `POST https://api.resend.com/emails`
(`Authorization: Bearer`). Yerel: `axllent/mailpit` imajı.

## Sınırlar

- Pazarlama / broadcast, gelen e-posta (receiving), şablon ve webhook kurulumu kapsam dışı.
- Resend, kendi test adresleri varken "sahte SMTP sunucusu kurma" der; bu teslim edilebilirlik testi içindir. Mailpit yalnız
  yerel geliştirme ve kod/akış doğrulaması içindir, Resend'in teslim davranışını (geri dönüş, engel listesi) taklit etmez.
- Alan adı doğrulama süresi ve panel ekranları değişebilir; kayıt değerleri her zaman panelden alınır.
- Başka bir sağlayıcıya (SES, Postmark) geçiş kapsam dışı; yalnız SMTP istemcisi tek kod yolu olursa geçiş kolaylaşır.
