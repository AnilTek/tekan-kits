# consciouslab-app — değişiklik günlüğü

## 0.3.0 — 2026-11-09

Yeni adım 12 **Harcama özeti** (Consciouslab-Auth spec `panel-app-spend`, #220): app API'si panelin Maliyet sekmesine aylık
dış servis harcamasını verir; kurallar "her sağlayıcıda app'e özel anahtar" ve "Google yapay zekâsı yalnız app'in projesinden".
Eski 12–17 → 13–18. Python paketi `0.3.0` (olgu `python_install`), yeni olgu `spend_summary`.

## 0.2.0 — 2026-10-29

Tür `workflow` → `knowledge`. Tekan yalnız knowledge (bağla) ve setup (dosya yaz) kit'lerini sohbete ekliyor; workflow kit'i
reddediliyordu (tekan ADR 0037, `add-to-chat.ts`). Artık app reposunda "+" ile projeye bağlanır ve her oturumda yüklenir. İçerik aynı.

## 0.1.1 — 2026-10-29

Python paketi `consciouslab-auth` `0.1.0rc1` → `0.2.0` (olgu `python_install`): `build_app`'e zorunlu `listen` (auth ADR 0047,
ayrıntı `consciouslab-mcp` 0.3.0). npm paketi değişmedi.

## 0.1.0 — 2026-10-27

İlk sürüm (ön sürüm: paketler `0.1.0rc1` / `0.1.0-rc.1`). Nano'nun merkezi auth'a ve GCP'ye taşınmasında (ADR 0038, 0042), Umay/Alp
kurulumunda ve `app-integration-kit` spec'indeki K1–K8 kararlarından damıtıldı; bu kit henüz gerçek bir dış app'te koşulmadı
(ilk kullanıcı YouTube Intel olacak).

- Tür `workflow`: dosya kopyalamaz. Şema başka kit'e bağlanmayı tanımlamadığından `consciouslab-mcp`, `consciouslab-hermes` ve `local-env`
  SKILL.md'de kimliğiyle anılır.
- Her adımda kim (app agent'ı / merkez isteği / Anıl) ve kapı yazılı; son kapı uyum testi.
- Olgular auth reposu belgelerinden ve Artifact Registry belgelerinden 2026-10-27'de alındı. Doğrulanamadı: `gh issue create --template`
  komutunun yml form dosyasıyla çalışması (şablon henüz `dev`'e merge edilmedi); Claude/ChatGPT plan ayrıntıları resmî sayfalardan ayrıca okunmadı.
