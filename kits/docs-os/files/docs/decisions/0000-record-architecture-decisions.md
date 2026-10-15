# 0000 — Kararları ADR olarak kaydet

**Status**: Accepted
**Date**: {{TODAY}}

## Context

Bir "X mi Y mi" tartışması sonuçlandığında geriye kalan tek şey seçilen seçenek
oluyor; seçilmeyenlerin **neden** elendiği kayboluyor. Aylar sonra aynı tartışma
baştan açılıyor, ya da elenmiş bir seçenek farkında olmadan yeniden deneniyor.
Sohbet geçmişi bu bilgiyi teknik olarak tutuyor ama aranabilir ve okunabilir değil.

## Decision

Yapıyı, bağımlılıkları ya da çalışma biçimini etkileyen her karar
`docs/decisions/NNNN-<slug>.md` altında yarım sayfalık bir ADR olarak kaydedilir.
ADR'ler append-only'dir: birleşmiş bir ADR düzenlenmez, yenisiyle supersede edilir
ve eskisinin yalnızca `Status` satırı `Superseded by NNNN` olarak güncellenir.

## Alternatives considered

- Karar kaydı tutmamak — reddedildi: aynı tartışma tekrar açılıyor, elenen seçenek yeniden deneniyor.
- Kararları canonical dokümanlara gömmek — reddedildi: canonical "şu an doğru olan"ı anlatır, tarihçe tutamaz; güncelleme NEDEN'i siler.
- Tek bir `decisions.md` dosyası — reddedildi: çakışan düzenlemeler, numaralandırma ve supersede zinciri izlenemez hale gelir.
- Sohbet/toplantı kaydına güvenmek — reddedildi: aranabilir değil, dış sisteme bağımlı, repoyla birlikte taşınmaz.

## Consequences

- Karar içeren her tartışma `distill-to-adr` ile kapatılır; ham döküm dosyaya yazılmaz.
- ADR dosya adları `NNNN-<slug>.md` biçimini korur; `doc-guard` bunu ve `Status`/`Date`
  alanlarının varlığını kontrol eder.
- Yeni karar eski bir kararı değiştiriyorsa supersede zinciri kurulması zorunludur.
