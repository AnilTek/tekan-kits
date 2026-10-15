# skills/

Repoya özel, **tekrarlanabilir prosedürler**. Doküman değil, çalıştırılan talimat:
bir agent bunu okuyup adımları uygular.

Bir prosedür buraya girer (docs/ yerine) eğer: birden fazla kez yapılacaksa, sırası
önemliyse ve çıktısı doğrulanabilirse. Ör: release, migration, veri yükleme, deploy.

```
skills/<name>/SKILL.md
```

`SKILL.md` frontmatter:

```yaml
---
name: <kebab-case>
description: Ne yaptığı + NE ZAMAN tetiklenmesi gerektiği (tetikleyici kelimelerle)
---
```

`description` alanı prosedürün ne zaman kullanılacağını anlatmalı — agent skill'i
bu satıra bakarak seçer. Sadece "ne yaptığı" yazılırsa skill hiç tetiklenmez.
