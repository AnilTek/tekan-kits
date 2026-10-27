# consciouslab-hermes — değişiklik günlüğü

## 0.1.0 — 2026-10-27

İlk sürüm (ön sürüm). Auth reposundaki `clients/hermes/README.md` ve `nano-mcp-agents` spec'inden (Umay Mac mini ve Pi kurulumları,
S4a denemesi) damıtıldı.

- Tek seed: `scripts/cl-hermes-install.sh` (kopyala + `keygen --profile-home`); geçici profil dizininde denendi, anahtar 0600 yazıldı,
  JWK ve `config.json` şablonu basıldı.
- Olgular 2026-10-27'de auth reposu belgelerinden alındı; Hermes'in kendi belgesi ayrıca doğrulanmadı (`plugins enable` komutu ve
  `config.yaml` anahtarı README'ye dayanır).
- Doğrulanamadı: eklenti için yayın paketi yok, kaynak kanalı "yerel kopya ya da merkezden iste". Gerçek bir Hermes profilinde
  uçtan uca (panel kaydı, `/baglan`) bu kit'le koşulmadı.
