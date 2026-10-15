---
last_reviewed: YYYY-MM-DD
owner: <isim>
---

# <API adı>

Dış servisin **davranış gerçekleri**. Client kodunun ne yaptığı buraya yazılmaz —
onu kod anlatır. Buraya, kodu okuyarak öğrenilemeyecek olan yazılır: sürprizler.

## Temel bilgiler

| | |
|---|---|
| Base URL | `<...>` |
| Auth | `<yöntem; anahtarın nerede durduğu — değeri DEĞİL>` |
| Dokümantasyon | `<url>` |
| Sürüm / tarih damgası | `<...>` |

## Limitler

| Limit | Değer | Aşılınca ne olur |
|---|---|---|
| Rate limit | `<...>` | `<hata kodu, backoff davranışı>` |
| Sayfa boyutu | `<...>` | |
| Payload | `<...>` | |

## Quirk'ler

Belgelenmemiş ya da belgeye aykırı davranışlar — bu bölüm dosyanın asıl değeridir.

- `<gözlem>` — nasıl doğrulandı: `<tarih / test>`

## Hata davranışı

| Kod | Anlamı | Bizim tepkimiz |
|---|---|---|
| `<...>` | `<...>` | `<retry / fail / kuyruğa al>` |

## Bilinmeyenler

Henüz doğrulanmamış varsayımlar. Doğrulanınca yukarı taşınır.

- `<...>`
