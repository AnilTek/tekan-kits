# {{PROJECT_NAME}} — agent router

Bu dosya bir **router**'dır: içerik tutmaz, nerede ne olduğunu söyler.
Bir bilgi burada anlatılıyorsa yanlış yerdedir — slot dosyasına taşı.

## Proje

<PLACEHOLDER: projenin ne yaptığı, tek paragraf>

Detay: [docs/canonical/context.md](docs/canonical/context.md)

## Stack & komutlar

[docs/canonical/architecture.md](docs/canonical/architecture.md) ile senkron tutulur.

| | |
|---|---|
| Dil | <PLACEHOLDER> |
| Kurulum | <PLACEHOLDER> |
| Geliştirme | <PLACEHOLDER> |
| Doğrulama | <PLACEHOLDER: test / lint komutları> |

## Harita — hangi bilgi nerede

| Aradığın şey | Yer |
|---|---|
| Ürünün amacı, kapsam | [docs/canonical/context.md](docs/canonical/context.md) |
| Terimler | [docs/canonical/glossary.md](docs/canonical/glossary.md) |
| Mimari, katmanlar | [docs/canonical/architecture.md](docs/canonical/architecture.md) |
| Yetki, sırlar | [docs/canonical/security.md](docs/canonical/security.md) |
| Dış API gerçekleri | `docs/canonical/integrations/<api>.md` — [şablon](docs/canonical/integrations/_template.md) |
| Verilmiş kararlar ve NEDEN'leri | [docs/decisions/](docs/decisions/) — [şablon](docs/decisions/_template.md) |
| Yapılacak iş spec'leri | [docs/intent/](docs/intent/) — [şablon](docs/intent/_template.md) |
| Tekrarlanabilir prosedür | `skills/<name>/SKILL.md` — [skills/](skills/) |
| Taksonominin kuralları | [docs/README.md](docs/README.md) |

## Yazma kuralları (agent'lar için bağlayıcı)

1. **Önce slot seç, sonra yaz.** Uygun slot yoksa kullanıcıya sor — kök dizine serbest dosya bırakma.
2. **Kod ikizi yazma.** Docs yalnızca koddan okunamayan NEDEN'i tutar.
3. **Canlı durum snapshot'ı yazma.** Sorgula, dosyalama.
4. **Sır yazma.** Token, şifre, connection string asla repoya girmez.
5. **Görev listesi tutma.** Tracker: <PLACEHOLDER>
6. **Toplantı özeti dosyası üretme.** Ham not `docs/inbox/`'a.
7. **Karar verildiğinde ADR yaz.** Birleşmiş ADR düzenlenmez, supersede edilir.
8. **Canonical dosyayı güncellerken `last_reviewed` tarihini güncelle.**

## Dizin sözleşmesi

```
AGENTS.md / CLAUDE.md     router + @AGENTS.md
docs/canonical/           yavaş değişen, doğrulanmış gerçekler
docs/decisions/           ADR'ler — append-only
docs/intent/              onaylı / yapılacak iş spec'leri
docs/inbox/ docs/_scratch/  gitignored
skills/                   çalıştırılabilir prosedürler
assets/                   dosyalar: veri, script
```

## Doğrulama

`bash assets/scripts/doc-guard.sh` — CI'da her PR'da: [.github/workflows/doc-guard.yml](.github/workflows/doc-guard.yml)
