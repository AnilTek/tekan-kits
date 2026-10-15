# docs-os — değişiklik günlüğü

## 1.1.0 — 2026-10-15

İlk gerçek benimsetmede (bir proje, `dev` akışlı) görülenler:

- `doc-guard.yml` (managed): `push` artık `main` ve `dev`'de koşar. Önceki sürüm yalnız `main`'deydi; `dev` akışlı
  projede birleştirmeden sonra kontrol koşmuyordu.
- `SKILL.md` Yöntem 3: managed dosya projenin kendi sürümünü değiştirdiyse projeye özgü kontroller (ör. kişisel veri
  deseni) `doc-guard.local.sh`'e taşınır. Önceki sürümde bu adım agent'a iletilmiyordu ve bir projenin kontrolü kayboldu.

## 1.0.1 — 2026-10-15

- `SKILL.md` Yöntem 3: var olan projede eksik `last_reviewed`, dosyanın git'teki son commit günüyle doldurulur (bugünün tarihi
  değil). Managed dosya değişmedi; uygulanmış projelerde güncelleme gerekmez.

## 1.0.0 — 2026-10-15

İlk sürüm. `init-docs-architecture` skill'inin kit hali; dosyalar artık kit'te, agent yazmıyor.

- `doc-guard.sh`: 6 projede ayrışmış 4 sürümün kurallarının birleşimi. Temel en kapsamlı sürüm (router, slotlar, linkler,
  ADR biçimi ve supersede zinciri, `last_reviewed`, geçici slotlar, `.env` sızıntısı). Diğer sürümlerden eklenenler:
  docs/ altında tanımsız klasör ve kökte serbest dosya yasağı; link kontrolünde şablonları ve `_legacy`'yi atlama;
  her kuralın "Neden" satırı; projeye özgü kontroller için `doc-guard.local.sh` kancası (ör. kişisel veri deseni kontrolü).
