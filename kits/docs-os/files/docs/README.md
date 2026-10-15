# docs/ — taksonomi

Her dokümanın **tek** bir yeri vardır. Yeri, üç soruya verilen cevapla belirlenir:
gerçeğin sahibi kim, ne sıklıkla değişiyor, nasıl tüketiliyor.

## Slotlar

| Slot | Ne girer | Ne GİRMEZ |
|---|---|---|
| `canonical/` | Yavaş değişen, doğrulanmış gerçekler: amaç, terimler, mimari, güvenlik, dış API davranışı | Kod ikizi, canlı durum, tartışma |
| `decisions/` | ADR: verilmiş karar + neden + reddedilen alternatifler | Sonuçlanmamış tartışma, görev listesi |
| `intent/` | Henüz yapılmamış işin spec'i; onaylanınca uygulanır | Yapılmış işin anlatımı (o ADR ya da canonical) |
| `inbox/` | Ham girdi: toplantı notu, transkript, brain-dump. Kuyruk, arşiv değil | Kalıcı hiçbir şey |
| `_scratch/` | Geçici analiz çıktısı, ara notlar | Referans verilen hiçbir şey |
| `_legacy/` | Donmuş eski dokümanlar; sadece triage ile boşaltılır | Yeni yazılan hiçbir şey |

`inbox/` ve `_scratch/` gitignored'dır — commit edilmezler.

## Slotta olmayanlar

- **Tekrarlanabilir prosedür** → `skills/<name>/SKILL.md` (doküman değil, çalıştırılır)
- **Veri / SQL / export / script** → `assets/` (dosyadır, doküman değil)
- **Görevler** → task tracker (repoda görev listesi dosyası tutulmaz)
- **Sırlar** → vault (repoda asla)

## Yaşam döngüsü

```
ham girdi → docs/inbox/
    ├── karar        → docs/decisions/NNNN-<slug>.md   (distill-to-adr)
    ├── aksiyon      → task tracker
    ├── kalıcı gerçek → docs/canonical/*.md            (last_reviewed güncellenir)
    └── açık soru    → docs/intent/<feature>.md
ham girdi silinir
```

## Kurallar

- **ADR'ler append-only.** Birleşmiş bir ADR'de izin verilen tek düzenleme
  `Status: Superseded by NNNN` satırıdır.
- **Canonical dosyalar `last_reviewed` taşır.** Güncellemeden tarihi değiştir.
- **Boş "ihtimalen lazım olur" dosyası açma.** Slot şablonları dışında dosya,
  ancak yazılacak içerik varken oluşturulur.
- **Bir gerçek iki dosyada duruyorsa biri yanlıştır.** Çelişki bulursan kod ya da
  canlı sistem üzerinden doğrula, kaybedeni sil.

## Doğrulama

`bash assets/scripts/doc-guard.sh` — yapı ve link kontrolü. CI'da her PR'da koşar.
