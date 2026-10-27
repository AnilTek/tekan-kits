# consciouslab-app — değişiklik günlüğü

## 0.1.0 — 2026-10-27

İlk sürüm (ön sürüm: paketler `0.1.0rc1` / `0.1.0-rc.1`). Nano'nun merkezi auth'a ve GCP'ye taşınmasında (ADR 0038, 0042), Umay/Alp
kurulumunda ve `app-integration-kit` spec'indeki K1–K8 kararlarından damıtıldı; bu kit henüz gerçek bir dış app'te koşulmadı
(ilk kullanıcı YouTube Intel olacak).

- Tür `workflow`: dosya kopyalamaz. Şema başka kit'e bağlanmayı tanımlamadığından `consciouslab-mcp`, `consciouslab-hermes` ve `local-env`
  SKILL.md'de kimliğiyle anılır.
- Her adımda kim (app agent'ı / merkez isteği / Anıl) ve kapı yazılı; son kapı uyum testi.
- Olgular auth reposu belgelerinden ve Artifact Registry belgelerinden 2026-10-27'de alındı. Doğrulanamadı: `gh issue create --template`
  komutunun yml form dosyasıyla çalışması (şablon henüz `dev`'e merge edilmedi); Claude/ChatGPT plan ayrıntıları resmî sayfalardan ayrıca okunmadı.
