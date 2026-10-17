---
name: supabase
description: How to use Supabase from a backend (FastAPI, Flask, Node) without key leaks, auth bugs or migration drift — anon vs service_role vs sb_publishable/sb_secret keys, JWT verification (SUPABASE_JWT_SECRET vs JWKS, aud), RLS and grants, pooler (session vs transaction mode, "Tenant or user not found", prepared statements), Supabase CLI vs Alembic migrations, local stack (supabase start, db reset), storage buckets, free-tier pausing. Use whenever code touches SUPABASE_URL, SUPABASE_KEY, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY, SUPABASE_JWT_SECRET, supabase-py / supabase-js, PGRST301, or a supabase/migrations folder.
---

# supabase

## Ne

Supabase'i (Postgres + Auth + Storage) güvenilir bir backend'den kullanma yöntemi: hangi anahtar nerede yaşar, token nasıl
doğrulanır, erişim kilidi nasıl kurulur, hangi bağlantı adresi hangi iş için, şema değişikliği hangi tek yoldan geçer, yerelde
nasıl denenir.

## Neyi çözer

Daha önceki projelerde yaşanmış hatalar (bu projede değil — kullanıcıya böyle aktar):

- **Anahtar sızıntısı.** Login için "config" döndüren auth'suz bir uç, backend'in tek `SUPABASE_KEY` env'ini (aslında
  service_role) tarayıcıya verdi. Kök neden: env adı rolü söylemiyordu, anon ve service_role aynı adla karışabiliyordu. Başka
  bir projede `.env.example` dosyasına service_role biçiminde bir JWT yazılıp git'e girmişti.
- **Herkese açık anon anahtarla veri okuma/yazma.** `public` şemadaki tablolarda anon'a GRANT ve eski politikalar açık
  kalmıştı: profil tablosu okundu, `usertype` yazılarak yetki yükseltilebildi. İlk kilit yalnız `anon` ile doğrulandığı için
  yarım kaldı; giriş yapmış `authenticated` rolü tüm içerik tablosunu okuyabiliyordu. View'lar da RLS'i atlıyordu.
- **İmzası doğrulanmayan JWT.** Token yalnızca base64 çözülüp `sub` okunuyordu; sahte token kabul edildi.
- **Servis istemcisinin kullanıcı token'ına dönmesi.** supabase-py'de aynı istemciyle `sign_in_with_password` çağrılınca
  sonraki tüm sorgular kullanıcının 1 saatlik JWT'siyle gitti; `PGRST301 JWT expired` ve login döngüsü çıktı.
- **Yetkiyi `user_metadata`'dan okumak.** Kullanıcının kendi değiştirebildiği alandan tablo adı ve admin rolü okundu.
- **İki migration koşucusu.** Aynı repoda hem Alembic iskeleti hem timestamp'li `supabase/migrations` SQL'leri vardı;
  Alembic yalnız ilk iki sürümü biliyordu, README ise 3 dosya sayarken klasörde ~30 vardı, anlatılan deploy betiği yoktu.
  Elle SQL Editor'dan uygulanan başka bir projede de bir dosyanın `insert` bloğu atlandı ve tablo canlıda boş kaldı.
- **Bağlantı adresi tuzakları.** `db.<ref>` adresi çözülmedi; pooler'da düz rol adı "Tenant or user not found" verdi.
- **Yanlış ortama bağlanmak.** Yerel ortam olmadığı için test şeması canlı veritabanının içinde tutuldu; başıboş bir env değişkeni
  canlı servisi boş şemaya yönlendirdi (kredi 0 göründü).

## Doğruluk kaynakları

- Anahtarlar: https://supabase.com/docs/guides/api/api-keys · JWT: https://supabase.com/docs/guides/auth/jwts
- RLS: https://supabase.com/docs/guides/database/postgres/row-level-security
- Bağlantı: https://supabase.com/docs/guides/database/connecting-to-postgres
- Migration: https://supabase.com/docs/guides/deployment/database-migrations · Yerel: https://supabase.com/docs/guides/local-development/overview
- Fiyat ve pause: https://supabase.com/pricing · https://supabase.com/docs/guides/platform/free-project-pausing
- **Sayıları (port, limit, fiyat, süre) bu dosyanın yanındaki `kit.yaml` → `facts`'ten oku** (kaynağı ve kontrol tarihiyle);
  ezberindeki değer eski olabilir. Legacy anahtar modeli 2026 sonunda kalkıyor: anahtar türü söylerken `facts`'e bak.

## Yöntem

1. **Anahtar rolünü env adı taşısın.** Tek env adı bir rolü anlatır: `SUPABASE_ANON_KEY` (publishable) ve
   `SUPABASE_SERVICE_ROLE_KEY` (secret). Belirsiz `SUPABASE_KEY` açma; varsa hangi rol olduğunu koddan ve panelden doğrula.
2. **Gizli anahtar yalnız backend'de.** İstemciye, log'a, config uç yanıtına, `.env.example`'a girmez. Tarayıcıya yalnız
   publishable/anon gider. Bir config ucu yazarsan yanıtında `service_role` olmadığını test et. Sızma şüphesinde anahtarı
   döndür; JWT secret'i döndürmek legacy modelde anon/service_role anahtarlarını ve tüm oturumları birlikte düşürür.
3. **Tehdit modeli giriş yapmış kullanıcıdır.** Publishable anahtar her tarayıcıda, signup açıksa herkes `authenticated`
   token alabilir. Backend service_role ile çalışıyorsa RLS sana bir şey sağlamaz (service_role, kullanıcı token'ı taşımayan
   istekte RLS'i atlar): her endpoint kaydın isteyene ait olduğunu kendisi kontrol eder.
4. **İstemci veritabanına hiç dokunmayacaksa kilitle.** Her tabloda RLS aç ve politika ekleme (politikasız = hiç kimse),
   `anon` + `authenticated` GRANT'lerini geri al, view'lara `security_invoker = true`, fonksiyonlardan `EXECUTE`'u `PUBLIC`'ten
   al (`SECURITY DEFINER` kilidin yanından geçer). Yeni her tablo/view/fonksiyon aynı migration'da kilitlenir.
5. **Kilidi iki rolle de sına.** Önce anon, sonra kısa ömürlü bir `authenticated` token ile PostgREST'e istek at; ikisi de
   reddedilmeli. Yalnız `postgres` rolüyle ya da yalnız anon ile "doğrulandı" deme. Yeni tablo eklenince tekrarla.
6. **Auth ve veri için ayrı istemci.** `auth.*` çağrıları (sign_in, refresh) ayrı bir anon istemciden; service_role istemcisi
   yalnız sorgular için ve hiç `sign_in` görmez. Paylaşılan istemciyi kilitli (double-checked) tek örnek olarak kur.
7. **JWT'yi imzasıyla doğrula, fail-closed.** `alg` başlığına göre: asimetrik ise JWKS (cache'li istemci), HS256 ise
   `SUPABASE_JWT_SECRET`. `exp` zorunlu, `aud` değeri `facts`'teki ile kontrol edilir, doğrulanamayan token 401. Resmî öneri:
   HS256'yı yerelde sırla doğrulamak yerine Auth sunucusuna sormak ya da asimetrik anahtara geçmek (`facts` →
   `hs256_verification_guidance`); yerel HS256 doğrulaması kullanırsan sırrı sızıntı riskiyle birlikte yönet. Auth Hook / OIDC
   gibi özellikler asimetrik imza isteyebilir ("HS256 is not supported for ID token signing"). Asimetriğe geçişte JWKS
   uç cache'i yüzünden bekleme süresine uy.
8. **Yetkiyi `app_metadata`'dan ya da kendi tablondan oku**, `user_metadata`'dan değil (kullanıcı değiştirebilir). Tablo adı,
   rol, kiracı gibi değerler istemci kontrollü alandan gelmesin.
9. **Bağlantı adresini işe göre seç.** ORM/migration/uzun ömürlü süreç: session mode ya da direct (IPv6/IPv4 add-on
   durumuna bak). Sunucusuz/kısa ömürlü çok bağlantı: transaction mode, ama driver'da prepared statement kapalı
   (`facts` → `transaction_mode_prepared`). Pooler kullanıcı adı `<rol>.<proje_ref>` biçimindedir; düz rol adı "Tenant or user
   not found" verir.
10. **Tek migration koşucusu.** Ya Supabase CLI (`supabase migration new`, `db push`) ya Alembic; ikisi aynı veritabanında
    olmaz. Supabase'e özgü şeyler (RLS, GRANT/REVOKE, rol, trigger) ancak SQL'de rahat yazılır: Alembic seçilirse bunlar da
    Alembic sürümlerinde `op.execute` ile gider. Panelden (SQL Editor/Table Editor) şema değiştirme; olduysa `supabase db pull`
    ile içeri al. Uygulanmış dosya değiştirilmez, düzeltme yeni dosyayla gelir.
11. **Migration'ı teslim etmeden önce koştur.** Dosyanın tamamını `begin; ... rollback;` içinde gerçek veriye karşı dene
    (DDL işlemseldir). Uygulandıktan sonra yalnız DDL'i değil yazdığı satırları da doğrula; panelin "Failed to fetch" hatası
    SQL'in koşmadığı anlamına gelmez. Kancaları/fonksiyonları onları çağıracak rolle dene (Auth hook'u `public`'i
    `search_path`'inde görmez: nesneleri şema-nitelikli yaz).
12. **Yerel ortam: Supabase CLI stack'i.** `supabase start`, `supabase db reset` (migration'lar + `seed.sql`; sıfırlama tek
    komut). Boş bir Postgres'te `anon`/`authenticated`/`service_role` rolleri yoktur; CLI stack'i bunları getirir, kilit
    migration'ları böyle sınanır. Uygulama adresi `SUPABASE_URL`'den okunur: yerel adres → yerel stack, dış adres → gerçek proje
    (`SUPABASE_URL` bu servisin `<SERVICE>_BASE_URL`'idir). Prod koduna mock dalı girmez. Yerel anahtarlar `supabase start`
    çıktısından gelir. Test şemasını canlı veritabanında tutma; ortam değişkeninin yanlış şemaya bağlanmasına karşı
    başlangıçta şema/ortam kontrolü yap.
13. **Storage.** Bucket varsayılanı private; özel dosya için `create_signed_url` (public URL çalışmaz). Boyut ve mime
    sınırını bucket'ta tanımla; bucket erişimi `storage.objects` politikalarıdır (kilidi buradan da sına).
14. **Free plan canlı veriye uygun değil.** Pause kuralı, plan limitleri ve fiyat `facts`'te. Önceki bir projede Free, yedek yok
    ve trafiksizlikte pause yüzünden canlı için reddedildi. Pause'dan çıkış süresi de `facts`'te; ikinci kaynak çelişirse
    resmî sayfayı al.

## Araçlar

Supabase CLI (`supabase`), Docker (yerel stack), `psql`; backend'de `supabase-py` / `supabase-js` ve JWT için `PyJWT[crypto]`
(`PyJWKClient`) ya da `jose`. Env adları: `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`,
`SUPABASE_JWT_SECRET`. Doğrudan Postgres gerekiyorsa ayrı bir `DATABASE_URL`.

## Sınırlar

- Yalnız backend tarafı. Frontend auth akışı, Realtime, Edge Functions ve OAuth sunucusu kapsam dışı.
- RLS politika yazımı (kullanıcı başına satır erişimi) burada işlenmedi; yöntem "backend service_role + istemciye kapalı"
  modeline dayanır. İstemcinin tabloya doğrudan eriştiği bir mimaride politikaları resmî RLS dokümanından yaz ve test et.
- JWT'nin yerel HS256 doğrulamasının önceki projelerde çalıştığı ölçüldü, ama resmî doküman bunu önermiyor; karar proje
  sahibinin. Yeni projede asimetrik imza anahtarı tercih edilir.
- Hiçbir kaynak projede Supabase CLI yerel stack'i kullanılmadı; madde 12 resmî dokümana ve yerel ortam sözleşmesine dayanır,
  önceki bir projenin düz Postgres imajıyla elle rol kurarak migration sınamasından da desteklenir.
- Alembic'in Supabase ile birlikte kullanımı için resmî rehber yok; "tek koşucu" kuralı önceki projelerde görülen kaymadan gelir.
