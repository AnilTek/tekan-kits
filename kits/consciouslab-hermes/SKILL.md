---
name: consciouslab-hermes
description: Install the cl-hermes plugin into one specific Hermes agent profile so the agent calls Consciouslab app MCP servers with the asking person's own authority — per-profile config.json, keygen --profile-home, panel agent registration, plugins enable, gateway restart, DM-only /baglan, observe mode off, profile = trust boundary. Use when the user mentions Hermes, Umay, Alp, cl-hermes, /baglan, or giving an agent access to a Consciouslab app.
---

# consciouslab-hermes

## Ne

Bir Hermes profiline `cl-hermes` eklentisini kurmak: agent, Consciouslab app'lerinin MCP sunucularını **mesajı yazan kişinin
kendi yetkisiyle** çağırır (token'da `sub` = soran kişi, `act` = agent). Her eklentili profil panelde **ayrı agent**tır
(kendi anahtarı, `client_id`'si, ayrı kapatılır). Kit tek bir yardımcı betik taşır; gerisi bu belgede.

## Neyi çözer

Umay (Mac mini, Pi) ve Alp kurulumlarında görülenler:

- Pi'de tek Hermes süreci dokuz profili sunar; `.env` ve `os.environ` profiller arası ortak olduğundan `CL_*` env ile kurulan
  eklenti başka profilin kimliğini kullanabilirdi. Doğrusu profil başına `<HOME>/cl-hermes/config.json`.
- Telegram'da `observe_unmentioned_group_messages: true` iken etiketlenen mesaj ortak oturuma, gönderen kimliği silinerek gider;
  eklenti "kimin sorduğu doğrulanamadı" der (DM'de çalışır, grupta çalışmaz).
- Eklenti varsayılan kapalıdır: kopyalanıp etkinleştirilmeyen profilde komut hiç görünmez.
- Tek profile kurulan eklenti "kuruldu" sanıldı; ikinci profil ayrı kopya, anahtar, panel kaydı ister.
- `/baglan` grupta yazılınca giriş bağlantısı gruba düşerdi; yalnız DM'de çalışır.

## Doğruluk kaynakları

- Auth reposunda `clients/hermes/README.md` (kurulum, Pi kaynak notları, sorun giderme) ve `docs/intent/nano-mcp-agents.md` (M8–M11, M9b, M15).
- Hermes'in kendi belgesi eklenti ve profil komutları için. Adresler, sürümler, bayrak adları `kit.yaml` → `facts`'ten okunur.
- Belirsiz davranışta `hermes plugins doctor` ve profilin `logs/agent.log` dosyası kanıttır.

## Yöntem

1. **Hangi profil, kimin agent'ı?** Profil dizinini (varsayılan `~/.hermes`, adlı `~/.hermes/profiles/<ad>`) ve sponsoru netleştir.
   **Profil = güven sınırı (M15):** profilin belleği, geçmişi, dosyaları, araçları onunla konuşabilen herkesindir.
   Müşteri profillerinde iç kaynak (Drive, GitHub, iç yetenek) **olmaz**; müşteri başına ayrı profil. Karışık kitleyi tek profile koyma.
2. **Eklenti kaynağı.** Kaynak: auth reposunun `clients/hermes/cl_hermes/`. Yayın paketi (artifact) tanımlı **değil**
   (`facts`: `plugin_distribution`). Kaynağı şöyle bul: (a) auth reposunun yerel kopyası varsa onu kullan; (b) yoksa
   **merkezden iste**: `gh issue create -R AnilTek/Consciouslab-Auth` ile "cl-hermes kaynağı lazım" issue'su aç (erişimin yoksa
   Anıl'dan klasörü al). Kaynağı tahmin etme, internetten başka kopya indirme.
3. **Kur.** `bash scripts/cl-hermes-install.sh <profil-dizini> <cl_hermes-dizini>`: eklentiyi `<HOME>/plugins/cl-hermes`'e kopyalar,
   `keygen --profile-home` ile anahtarı `<HOME>/cl-hermes/agent-key.pem` (0600) olarak üretir ve **açık anahtarı (JWK)** yazdırır.
   `HERMES_PYTHON` Hermes'in kendi Python'u olmalı (Pi: `~/.hermes/hermes-agent/venv/bin/python`). Özel anahtar sohbete yazılmaz.
4. **Panelde kaydet (Anıl).** Yönetim → Agent'lar → yeni agent: ad, sponsor, JWK. Her profil için ayrı kayıt; iki agent aynı
   anahtarı ya da `client_id`'yi paylaşmaz. Panel `client_id` verir; app agent'ı panele yazmaz, istek kullanıcıya gider.
5. **Ayar dosyası.** `<HOME>/cl-hermes/config.json` (`chmod 600`): `auth_issuer`, `agent_client_id`, `key_path`
   (`facts`: `config_keys`). Çok profilli süreçte `CL_*` env'e **güvenme**; dosya yoksa eklenti bilerek hata verir.
6. **Profil başına etkinleştir.** `hermes plugins enable cl-hermes` (adlı profil: `hermes -p <ad> plugins enable cl-hermes`);
   komut CPU'yu kısa süre yükler, bekle. Elle yapılırsa profilin `config.yaml` → `plugins.enabled` listesine `cl-hermes` eklenir.
7. **Telegram ayarı.** Eklentili profilde `observe_unmentioned_group_messages: false`. Kapalı olmayan profilde grup soruları çalışmaz.
8. **Gateway'i yeniden başlat** (sohbet sakinken): Pi'de `systemctl --user restart hermes-gateway.service`, sonra
   `journalctl --user -u hermes-gateway.service -n 80 --no-pager | grep -i cl.hermes`; her profil için komut kaydı görünmeli.
9. **Profil talimatına ekle:** "Consciouslab araçlarından gelen veriyi kalıcı belleğe yazma, gerekince yeniden sor." (yumuşak önlem;
   kesin kilit profil ayrımıdır).
10. **Bağlan ve doğrula.** Agent'a **yalnız özelden** `/baglan` yaz; gelen bağlantıda Consciouslab hesabınla gir, izin ekranında
    "<agent>, Telegram'daki @sen için" satırını kontrol et. Sonra bir araç sorusu sor. Ayrı bir kişi aynı soruyu sorunca rolüne göre
    farklı cevap almalı; bağlamamış kişi `/baglan` yönlendirmesi almalı; zamanlanmış iş (cron) veri almamalı.
11. **Sorun giderme.** Profilin `logs/agent.log`'unda `cl_hermes: ret:` satırı (`user_id=yok key=var` = gönderen kimliği silinmiş,
    7. adım). "Eklenti ayarlanmamış" = `config.json` yok; "Hesabın bana bağlı değil" = o kanaldan `/baglan` yok; "Bağlandı" mesajı
    düşmediyse Pi sürümünde `ctx.post_message` yoktur (beklenen).

## Araçlar

`hermes` CLI (`plugins enable/doctor`), Hermes'in Python'u (`httpx`, `PyJWT`, `cryptography` hazır), `bash`, `systemctl`/`journalctl` (Pi),
`gh` (kaynak isteği). Panel ve Telegram işleri Anıl'ın ya da ilgili kişinin elinde.

## Sınırlar

- Eklentinin dağıtım kanalı yok: kaynak auth reposundan kopyalanır ya da merkezden istenir; sürüm sabitleme yok.
- Panel kaydı ve sponsor atama app agent'ının işi değil. Müşteri profillerinde agent kapsam tavanı henüz yok (açık risk, M9b).
- Pi'de profiller aynı Linux kullanıcısını paylaşır: müşteri profilleri açılmadan eklentili profiller ayrı kullanıcıya alınmalı.
- Cihaz ele geçirilirse panelden agent kaldırılır; bütün kişi bağlantıları birlikte düşer.
- Telegram dışı kanallar denenmedi; yeni kanalda kişi o kanaldan bir kez `/baglan` der.
