# Yerel ortam sözleşmesi: env-up, env-down, db-reset, dev. Komut adları her projede aynıdır; Tekan ve agent'lar bunları arar.
# Kaynak: tekan-kits/local-env (seed; sonrası projenin malı). Adları değiştirme; içlerini projenin stack'ine göre doldur.
.PHONY: env-up env-down db-reset db-migrate db-seed dev check

COMPOSE ?= docker compose

# Servisleri başlatır ve sağlıklı olana kadar bekler. Veriye dokunmaz; ilk kurulumda ardından `make db-reset`.
env-up:
	@test -f .env || cp .env.example .env
	$(COMPOSE) up -d --wait

# Servisleri durdurur; veri adlandırılmış birimde kalır.
env-down:
	$(COMPOSE) down

# Tek komutla sıfırlama: sil -> migrate -> seed. Bozmak serbest; geri gelmesi saniyeler sürmeli.
db-reset:
	@test -f .env || cp .env.example .env
	$(COMPOSE) down -v
	$(COMPOSE) up -d --wait
	$(MAKE) db-migrate
	$(MAKE) db-seed

# Şemayı migration dosyalarından kurar (prod şeması kopyalanmaz; migration böylece test edilir).
db-migrate:
	<PLACEHOLDER: stack'in migration komutu>

# Elle yazılmış küçük örnek veri. Seed yöntemi stack'e göre değişirse (script, fixture) bu hedefi değiştir.
db-seed:
	$(COMPOSE) exec -T postgres sh -c 'psql -v ON_ERROR_STOP=1 -U "$$POSTGRES_USER" -d "$$POSTGRES_DB"' < db/seed.sql

# Geliştirme sunucusu; önce ortamı (Postgres + mock'lar) ayağa kaldırır.
dev: env-up
	<PLACEHOLDER: dev sunucusu komutu>

# Sözleşmenin yapısal kontrolü (komut adları, mock'lar, yer tutucular). CI'sız projede asıl kapı budur; PR'dan önce koş.
check:
	bash assets/scripts/env-check.sh
