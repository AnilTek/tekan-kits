---
name: google-oauth-login
description: How to build "Sign in with Google" for an internal tool restricted to one email domain — OAuth client setup, redirect URIs per environment, verifying the hd claim AND email_verified server-side, allowed domain + bootstrap admin, session cookie behind a proxy, consent screen Internal vs External, local testing. Use when code or config mentions AUTH_GOOGLE_ID, GOOGLE_CLIENT_ID, ALLOWED_EMAIL_DOMAIN, BOOTSTRAP_ADMIN_EMAIL, OAUTH_REDIRECT_URL, authlib, better-auth, Auth.js, or errors such as redirect_uri_mismatch, UntrustedHost, access_denied, org_internal.
---

# google-oauth-login

## Ne

Tek bir e-posta domainindeki çalışanların girdiği iç araç için "Google ile giriş" kurma yöntemi: OAuth istemcisi, ortam başına
redirect adresi, dönen kimliğin sunucuda doğrulanması, izinli domain + ilk admin, proxy arkasında oturum çerezi, izin ekranı
türü, yerel test. Kütüphaneden bağımsızdır; sonda authlib (FastAPI) ve Better Auth (TS) için kısa notlar var.

## Neyi çözer

Önceki projelerde (bu projede değil — kullanıcıya böyle aktar) yaşananlar:

1. **Domain kontrolü tek başına yetmedi.** Alan adı sonekine bakan kontrol, Workspace dışında bu adresle açılmış yönetilmeyen
   bir Google hesabını geçirebilir (`email_verified` yine true). Ayırt eden şey ID token'daki `hd` iddiasıydı; kontrol
   güçlendirilip saf bir fonksiyona taşındı ve birim testle sınandı.
2. **Domain tanımsızken kontrol atlanıyordu**: ortam değişkeni boşsa herkes giriyordu. Fail-closed'a çevrildi.
3. **Üretim derlemesinde giriş 500 döndü** (Auth.js `UntrustedHost`): dev'de güven kendiliğinden açık, `production`'da kapalı;
   dev'de hiç görünmedi.
4. **Yerelde giriş sessizce başarısız oldu**: çerez `Secure` sabit açıktı, `http://localhost`'ta tarayıcıya göre gönderilmedi.
5. **İlk admin e-postayla koda yazılırsa yetki devri olur**: aynı adres başka birine verilince yeni kişi eski yetkileri alır.

## Doğruluk kaynakları

- Google OpenID Connect (`hd`, `sub`, `email_verified`): https://developers.google.com/identity/openid-connect/openid-connect
- Redirect URI kuralları: https://developers.google.com/identity/protocols/oauth2/web-server
- İzin ekranı türleri: https://support.google.com/cloud/answer/15549945
- Better Auth Google: https://www.better-auth.com/docs/authentication/google
- Starlette oturum çerezi: https://starlette.dev/middleware/
- **Sayıları ve kuralları bu dosyanın yanındaki `kit.yaml` → `facts`'ten oku** (kaynağı ve kontrol tarihiyle); ezberindeki değer
  (test kullanıcı sınırı, redirect kuralları, kütüphane varsayılanları) eski olabilir.

## Yöntem

1. **Akış: sunucu taraflı authorization code.** Client secret yalnız sunucuda; tarayıcı yönlendirilir, token'a çeviren istek
   sunucudan gider. Bu durumda "Authorized JavaScript origins" doldurulmaz (yalnız tarayıcıda token alan akışlar için);
   Google'ın tarayıcı düğmesine geçilirse akış ve bu alan değişir. `state` doğrulanır (kütüphane yapar, kapatma).
2. **`hd` istek parametresi yalnız ipucudur.** Hesap seçiciyi daraltır; adres çubuğundan silinebilir. Karar dönen ID token'da
   verilir; ipucunu göndermek serbest, ona güvenmek yasak.
3. **Üç kontrol, hepsi sunucuda, hepsi geçerse giriş:** `hd` iddiası izinli domaine **eşit**, `email_verified === true`, e-posta
   domaini izinli domaine **tam eşit** (sonek eşleşmesi yok: `evil-example.com`, `example.com.evil.net` elenmeli). `hd` yoksa
   ret. İkisinden biri eksik kalırsa açık kapı olur; `facts` → `hd_claim_check`, `sub_as_identity`.
4. **Hesabı `sub` ile eşle, e-postayla değil** (Google de böyle diyor). E-posta kimlik anahtarıysa yeniden kullanılan adres eski
   yetkiyi taşır; kendiliğinden hesap bağlamayı kapat, Google token'larını yalnız Google API'si çağıracaksan sakla.
5. **Fail-closed yapılandırma.** Domain boşsa ya da istemci kimliği/sırrı/oturum sırrı eksikse korunan uçlar 503 (401 değil:
   sorun kullanıcıda değil). Domain değerini normalize et (tırnak, baştaki `@`, boşluk, küçük harf) ama TLD'yi **tamamlama**:
   `corp` ile `corp.io` farklı domaindir. Sıra: 503 yapılandırma, 401 oturum yok, 403 domain dışı.
6. **Red tek tip, sebep log'da.** Kullanıcıya "bu hesapla giriş yapılamaz" göster; hangi kontrolün tuttuğunu adres çubuğuna ya da
   ekrana yazma; sebebi (yalnız alan adıyla) sunucu log'una yaz. Domain reddi **403**'tür. Her istekte domaini yeniden denetle
   (yapılandırma oturum ömrü içinde daralabilir).
7. **Bootstrap admin.** `BOOTSTRAP_ADMIN_EMAIL` yalnız kullanıcı kaydı ilk oluşurken ya da sistemde hiç admin kalmadığında
   uygulanır; her girişte zorlanırsa o adresin rolü devredilemez. Daha sıkı seçenek: kişi önce bir kez girer, sonra tek seferlik
   betik aktif admin yoksa yetki verir ve audit'e yazar. Admin kendi rolünü düşüremez (en az bir admin kalır).
8. **Redirect adresi ortam başına, birebir.** Scheme, büyük/küçük harf ve sondaki `/` dahil eşleşir; fark `redirect_uri_mismatch`
   verir. Adresi koddan türetme, env'den oku (`OAUTH_REDIRECT_URL`) ve konsoldakiyle aynı tut. İki yol yaşandı: ortam başına ayrı
   GCP projesi + ayrı istemci (sır ve izin ekranı ortama göre ayrı) ya da tek istemciye ikinci URI eklemek (Google birden çok URI
   kabul eder, yerel olanı silmek gerekmez). `facts` → `redirect_uri_*`.
9. **Proxy arkasında şemayı sabitle.** TLS'i proxy sonlandırıyorsa uygulama isteği `http` görebilir. Redirect adresini ve
   uygulama adresini env'den ver (kütüphanenin Host/Proto çıkarımına bırakma; Auth.js'te `AUTH_URL` kanonik adresi sabitler, host
   başlığına körü körüne güvenen `AUTH_TRUST_HOST`'a tercih edildi; Better Auth'ta `baseURL`). Uvicorn'da `X-Forwarded-Proto`
   için proxy adresi `--forwarded-allow-ips` ile güvenilir yapılır; her adrese açma.
10. **Oturum çerezi:** imzalı, `SameSite=Lax` (OAuth dönüşü başka siteden yönlendirmedir; `Strict` çerezi o istekte göndermez ve
    giriş hiç tamamlanmaz), `Secure` canlıda açık. `Secure`'ı redirect adresinin şemasından türet: yerelde `http` kapalı, canlıda
    `https` açık. Varsayılanlar kütüphaneye göre farklı: `facts` → `starlette_session_defaults`.
11. **İzin ekranı: Internal tercih et** (yalnız Cloud Organization'a bağlı projede açılır). Yabancı hesap Google'ın kendi
    ekranında durur; bu, koddaki kontrolün yanında ikinci kilittir, yerine geçmez. External seçilirse test modunun sınırları:
    `facts` → `external_testing_limits`. Workspace'te iki adımlı doğrulama zorunluluğu koddan denetlenemez, kontrol listesine yaz.
12. **Yerel test.** Kuralı (üç kontrol, tam eşleşme, boş domain) HTTP'den bağımsız saf fonksiyon olarak yaz ve tablolu testle sına:
    `hd` yok, `hd` başka, `email_verified` false, sonek domain, boş yapılandırma. Testlerde `.env` okuma (dolu `.env` 503 testlerini
    401'e çevirdi). Yerelde Google redirect'i `http://localhost:<port>/...` kabul eder. Gerçek `hd` davranışı yalnız gerçek bir
    iç hesap ve domain dışı bir hesapla (staging ya da yerel) denenir; mock bunu kanıtlamaz. Mock gerekirse OIDC discovery adresi
    `GOOGLE_BASE_URL`'den okunur; prod koduna mock dalı girmez.
13. **Sır sızarsa:** konsolda istemciye ikinci sır ekle, yeni sürümü sır deposuna koy, servisi yeniden başlat, girişi dene, sonra
    eski sırrı sil.

### authlib (FastAPI / Starlette)

`oauth.register(..., server_metadata_url="https://accounts.google.com/.well-known/openid-configuration", client_kwargs={"scope": "openid email profile"})`;
callback'te `token = await oauth.google.authorize_access_token(request)`, kimlik `token["userinfo"]`. **`hd` ipucunu
`client_kwargs`'a koyma:** authlib 1.9.1'de yetkilendirme adresine gitmedi (ölçüldü); `authorize_redirect(request, url, hd="example.com")`
ile gider. Önceki projedeki kodda `hd` `client_kwargs`'taydı; zararsızdı çünkü asıl kontrol dönüşteydi. `hd` iddiasını
`userinfo.get("hd")` ile sen karşılaştır (authlib'in bunu zorladığına dair belge bulunamadı). Oturum için `SessionMiddleware` (`https_only`, `same_site="lax"`).
Authorize/callback uçlarını kökte tut (SPA `fetch` etmez, tarayıcı gider); redirect URI sabit kalır.

### Better Auth (TS)

Sağlayıcı seçeneği `hd`: doğrulanmış hosted-domain iddiasını ister, `hd`'siz token'ı reddeder (`facts` → `better_auth_hd_option`).
**`getUserInfo`'yu ezme**, yoksa yerleşik `hd` kontrolü sessizce kapanır (önceki bir projede PoC'de testle kanıtlandı); `email_verified`
ve tam e-posta domaini kontrolünü `user.validateUserInfo` kancasında yap. `baseURL`'i açıkça ver (yoksa callback üretimde
`localhost`'a düşebilir). Varsayılan hesap bağlama doğrulanmış e-postada bağlar; kapat.

## Araçlar

Google Cloud Console → Google Auth Platform (Branding, Audience = Internal/External, Clients → Web application). Env:
`GOOGLE_CLIENT_ID` / `AUTH_GOOGLE_ID` (sır değil), `GOOGLE_CLIENT_SECRET` / `AUTH_GOOGLE_SECRET`, `SESSION_SECRET`,
`ALLOWED_EMAIL_DOMAIN`, `OAUTH_REDIRECT_URL`, `BOOTSTRAP_ADMIN_EMAIL`. Sırlar repoya girmez.

## Sınırlar

- Yalnız tek domain, Google Workspace hesabı, sunucu taraflı kod akışı. Çok kiracılı SaaS, Google One Tap / tarayıcı düğmesi,
  Google API'lerini kullanıcı adına çağırma (refresh token, kapsamlar, doğrulama) kapsam dışı.
- Pasifleştirilen çalışanın açık oturumu kapanmaz; token/çerez `exp`'e kadar yaşar. Hasarı rol/üyelik kontrolüyle sınırla;
  anında kapatma ayrı bir tasarım işi.
- "Internal izin ekranı Google doğrulaması istemez" bir önceki projenin dokümanında yazıyor; Google sayfasında doğrulanamadı.
- Uvicorn `--forwarded-allow-ips` varsayılanı sayfada yazmıyor; kullandığın sürümde ölç.
- Secondary domain (alias) kullanan Workspace'lerde `hd` ile e-posta domaini farklı çıkabilir; kaynak projelerde denenmedi.
