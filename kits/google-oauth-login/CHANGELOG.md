# google-oauth-login — değişiklik günlüğü

## 1.0.0 — 2026-10-17

İlk sürüm. Dört önceki projenin (üç iç araç ve bir merkezî kimlik servisi) integration/güvenlik dokümanları, ADR'leri,
kod yorumları ve commit mesajlarından damıtıldı: `hd` + `email_verified` + tam domain eşleşmesi, ilk admin için bootstrap
kuralı, çerez `Secure`/`SameSite` kararları, proxy arkasında Auth.js `UntrustedHost` olayı, `hd` iddiasının neden gerektiği.

Doğrulama:

- `kit.yaml` olguları 2026-10-17'de resmî sayfalardan okundu (Google Identity, Google Cloud Help, Better Auth, Starlette,
  Uvicorn). Sayfalar doğrudan getirildi; Google OAuth sayfasının son ~21.000 karakteri okunamadı (redirect kuralları ilk
  100.000 karakterde bulundu).
- Authlib: resmî sayfada `SessionMiddleware`/proxy notu yok; yönteme yazılan "`hd` `client_kwargs`'ta gitmez, `authorize_redirect`
  parametresi olmalı" bulgusu 2026-10-17'de geçici bir sanal ortamda authlib 1.9.1 ile ölçüldü (yetkilendirme adresinde `hd`
  yalnız `authorize_redirect(..., hd=...)` ile çıktı). Olgu olarak `facts`'e girmedi, çünkü sürüme bağlı.
- Uvicorn'un `forwarded-allow-ips` varsayılanı sayfada yazmıyor: doğrulanamadı, değer yazılmadı.
- "Internal izin ekranı Google doğrulaması gerektirmez" iddiası önceki bir projenin dokümanında var; Google sayfası bunu
  anlatmıyor, bu yüzden kit'te olgu değil, doğrulanamadı notu olarak durur.
