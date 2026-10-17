// Railway altyapı tanımı ({{PROJECT_NAME}}, {{TODAY}}) — kit: railway.
//
// UYARI: `omit means delete`. Bu dosya ortamın tamamını tanımlar; bir kaynağı buradan
// çıkarmak onu SİLER. `railway config plan` çıktısı okunmadan `railway config apply` çalıştırılmaz.
// Sır değerleri buraya yazılmaz; Railway'de sealed variable olarak durur, burada `preserve()` ile temsil edilir.
//
// <PLACEHOLDER> değerlerini repoyu okuyarak doldur (SKILL.md "Yöntem" adım 3). Doldurulmadan
// plan/apply bilerek hata verir.
import { defineRailway, github, postgres, project, service } from "railway/iac";

const cfg = {
  service: "<PLACEHOLDER: servis adı, ör. api>",
  repo: "<PLACEHOLDER: owner/repo>",
  dockerfile: "<PLACEHOLDER: Dockerfile yolu, ör. Dockerfile>",
  // Monorepo'da bu servisi ilgilendiren yollar; tek servisli repoda bu satırı ve `watchPatterns`'i sil.
  watch: ["<PLACEHOLDER: izlenecek yol, ör. api/**>"],
  migrate: "<PLACEHOLDER: şema komutu, ör. alembic upgrade head>",
  healthPath: "<PLACEHOLDER: sağlık ucu, ör. /health>",
  port: "<PLACEHOLDER: dinlenen port, ör. 8080>",
};

const unfilled = Object.values(cfg).flat().filter((value) => value.startsWith("<PLACEHOLDER"));
if (unfilled.length > 0) {
  throw new Error(`.railway/railway.ts: doldurulmamış yer tutucu var: ${unfilled.join(" | ")}`);
}

export default defineRailway((ctx) => {
  // Üretim yalnız `main`'den çıkar; staging ortamı `dev`'den. Dal, ortam adına bağlı.
  const prod = ctx.isEnvironment("production");

  // Ayrı ortam = ayrı veritabanı (Postgres her ortamda ayrı bir kaynak).
  const db = postgres("postgres");

  const api = service(cfg.service, {
    source: github(cfg.repo, { branch: prod ? "main" : "dev" }),
    // Dockerfile ile build: otomatik derleyici yerine açık ve yerelde doğrulanabilir.
    build: { builder: "DOCKERFILE", dockerfilePath: cfg.dockerfile, watchPatterns: cfg.watch },
    // Şema, uygulama açılmadan önce ayrı kapta koşar; çıkış kodu sıfır değilse deploy durur.
    // Süre sınırı verilir ki takılan migration sessiz beklemesin.
    preDeploy: cfg.migrate,
    // Başlatma komutu burada YOK: imajın CMD'si geçerli (komut tek yerde, kabuk sorunu yok).
    healthcheck: cfg.healthPath,
    // Varsayılan bekleme uzun; açılış süresinin birkaç katı bir değer yaz.
    healthcheckTimeout: 60,
    deploy: {
      preDeployTimeoutSeconds: 300,
      restartPolicyType: "ON_FAILURE",
      restartPolicyMaxRetries: 10,
    },
    // Replika sayısı maliyeti doğrudan çarpar; ihtiyaç ölçülünce artır.
    replicas: 1,
    env: {
      PORT: cfg.port,
      DATABASE_URL: db.env.DATABASE_URL,
    },
  });

  return project("{{PROJECT_NAME}}", { resources: [api, db] });
});
