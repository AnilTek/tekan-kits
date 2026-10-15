---
name: docs-os
description: Set up or adopt the standard documentation system (AGENTS.md router, docs/ slots, doc-guard CI) in a repository by copying the kit's files verbatim. Use when starting a new project, when the user says "kur", "init docs", "yeni proje", "docs sistemi", or when a repo has no AGENTS.md. Also use to bring an existing repo's doc-guard up to the kit version. Never write these files from memory.
---

# docs-os

## Ne

Her projede aynı doküman sistemi: `AGENTS.md` router (`CLAUDE.md` onu import eder), `docs/` slotları
(canonical · decisions · intent · inbox · _scratch), `skills/`, `assets/` ve her PR'da koşan `doc-guard`.

## Neyi çözer

Agent'lar bu sistemi her projede hafızadan yeniden yazınca sürümler ayrışıyor: 2026-10-15'te 6 projede
`doc-guard.sh`'in 4 sürümü vardı ve `.env` sızıntı kontrolü 3 projede eksikti. Bu kit dosyaları **taşır**;
agent yazmaz, kopyalar.

## Doğruluk kaynakları

- Bu klasör: `kit.yaml` (dosya listesi ve kipleri) ve `files/` (dosyaların kendisi). Tek kaynak budur.
- ADR biçimi: Michael Nygard, "Documenting Architecture Decisions".

## Yöntem

1. **Önce bak.** Repoda `docs/`, `AGENTS.md`, `CLAUDE.md` var mı?
   - İçi dolu bir `docs/` varsa ve bu sistemde değilse, önce dondur:
     `git mv docs docs_tmp && mkdir docs && git mv docs_tmp docs/_legacy`
   - Var olan `AGENTS.md`/`CLAUDE.md`'nin üzerine yazma; içeriğini yeni router'a taşı, diff'i kullanıcıya göster.
2. **Kopyala, yazma.** `kit.yaml`'daki her dosyayı `files/`'tan birebir kopyala.
   - `managed` dosya projede zaten varsa ve farklıysa: farkı göster, kullanıcı onaylarsa kit'inkiyle değiştir.
     Projeye özgü kural `doc-guard.sh`'e değil `assets/scripts/doc-guard.local.sh`'e girer (doc-guard onu en sonda çalıştırır).
   - `seed` dosya projede zaten varsa dokunma.
   - Seed dosyalarda `{{PROJECT_NAME}}` → repo adı, `{{TODAY}}` → bugünün tarihi (YYYY-MM-DD).
   - `ensure_lines`: `.gitignore`'da eksik satırları sona ekle.
3. **Yer tutucuları repoyu OKUYARAK doldur, tahmin etme.** Stack ve komutlar `package.json` / `pyproject.toml` /
   `Makefile`'dan; architecture.md'deki alanlar üst düzey kaynak dizinlerinden. Repo cevap vermiyorsa
   `<PLACEHOLDER>` kalır. Repodan okunamayanı kullanıcıya sor (task tracker, altyapı nasıl yönetiliyor).
   Var olan projede doc-guard "last_reviewed yok" derse o canonical dosyaya frontmatter ekle; tarih dosyanın git'teki
   son commit günüdür (`git log -1 --format=%cs -- <dosya>`), bugün değil — dosya bugün incelenmedi.
   Kit bir managed dosyanın projedeki kendi sürümünü değiştirdiyse (ilk uygulama) eskisini `git show <base>:<dosya>` ile
   karşılaştır; projeye özgü kontrolleri (ör. kişisel veri deseni) `assets/scripts/doc-guard.local.sh`'e taşı, managed
   dosyayı düzenleme. Sonra doc-guard'ı yeniden çalıştır ve kalan hataları listele.
4. **Sürümü kaydet.** `.tekan/kits.json`'a `{ "source", "kit": "docs-os", "version", "files": { path: sha256 } }`
   (yalnız managed dosyalar). Tekan bunu kendisi yazar; Tekan dışındaysan elle yaz.
5. **Tek PR.** Branch `chore/docs-os`, `bash assets/scripts/doc-guard.sh` yerelde yeşil, sonra PR.

## Araçlar

`git`, `bash`. Ek bağlantı ya da anahtar gerekmez.

## Sınırlar

- Dosya içeriğini yeniden yazmak, "iyileştirmek" ya da özetlemek yok — değişiklik kit'e PR olarak gider.
- Var olan projeye uygulanınca yeni kurallar kırmızı verebilir (ör. `last_reviewed` eksik canonical dosya).
  Bunları aynı PR'da düzelt ya da PR açıklamasında listele; kuralı kapatma.
- Boş "ihtimalen lazım olur" dosyası açma; yalnız `kit.yaml`'daki dosyalar.
