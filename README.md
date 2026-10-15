# tekan-kits

Projeden projeye taşınan, uygulanabilir know-how. Her kit bir klasördür; Tekan bu repoyu okur ve kit'i
bir projeye diff → onay → PR olarak uygular. Tekan kullanmayan biri de kit'in `SKILL.md`'sini
([Agent Skills](https://agentskills.io/) formatı) kendi agent'ına verebilir.

## Kit'ler

| Kit | Tür | Sürüm | Ne yapar |
|---|---|---|---|
| [docs-os](kits/docs-os/) | setup | 1.1.0 | AGENTS.md router, docs/ slotları, doc-guard CI |

## Bir kit'in yapısı

```
kits/<id>/
  SKILL.md       agent'ın okuduğu talimat: ne, neyi çözer, kaynaklar, yöntem, araçlar, sınırlar (≤ 150 satır)
  kit.yaml       tür, sürüm, ihtiyaçlar, dosya listesi ve kipleri, kaynaklı olgular
  files/         projeye kopyalanan dosyalar
  CHANGELOG.md   her sürümde ne değişti, neden
```

**Kit türleri:** `knowledge` (bir servisi nasıl kullanırız) · `setup` (projeye dosya ve kural kurar) ·
`workflow` (adımlar; başka kit'leri sırayla uygular).

**Dosya kipleri:**

| Kip | Anlamı | Güncellemede |
|---|---|---|
| `managed` | Kit'in malı; her projede aynı bayt, değişken içermez | Yeni sürüm gelir. Projede elle değiştirildiyse üzerine yazılmaz, fark sorulur |
| `seed` | Bir kez kopyalanır, sonra projenin malıdır | Dokunulmaz |

Projede hangi kit'in hangi sürümünün uygulandığı `.tekan/kits.json`'da durur.

## Katkı

Kit'i projede değil burada düzelt: PR aç, `CHANGELOG.md`'ye yaz, `kit.yaml`'daki `version`'ı artır
(managed dosya değiştiyse minor, kural kaldırıldıysa major).
