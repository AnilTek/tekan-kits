#!/usr/bin/env bash
# env-check — yerel ortam sözleşmesinin yapısal kontrolü.
# İçeriği yargılamaz; yalnızca sözleşmenin bozulmadığını doğrular:
#   1. compose dosyası ve .env.example var
#   2. env-up / env-down / db-reset / dev komutları tanımlı (Makefile hedefi ya da package.json script'i)
#   3. Postgres imajı major sürüme sabit (latest / etiketsiz değil) ve veri birimi yolu o major'a uygun
#   4. her *_BASE_URL için ya yerelde yayımlanan bir mock portu var ya da gerçek olduğu açıkça işaretli
#   5. doldurulmamış <PLACEHOLDER yok
# Kaynak: tekan-kits/local-env (managed dosya). Bu dosyayı projede düzenleme; kit'te düzelt.
# Docker gerekmez; bash 3.2 (macOS) ile çalışır. Kullanım: bash assets/scripts/env-check.sh
#
# *_BASE_URL işaretleri (.env.example'da aynı satırın sonuna yorum olarak):
#   # env-check: real      gerçek servis bilerek seçildi (para harcayabilir; yorumda maliyeti yaz)
#   # env-check: process   mock compose dışında ayrı bir süreç (ör. `make dev` başlatıyor)
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

FAILURES=0

fail() { printf '  \033[31mFAIL\033[0m %s\n' "$1"; FAILURES=$((FAILURES + 1)); }
pass() { printf '  \033[32mok\033[0m   %s\n' "$1"; }
note() { printf '  \033[33mnot\033[0m  %s\n' "$1"; }
section() { printf '\n%s\n' "$1"; }

ENV_FILE=".env.example"
COMPOSE_FILE=""
for candidate in compose.yaml compose.yml docker-compose.yaml docker-compose.yml; do
  if [ -f "$candidate" ]; then COMPOSE_FILE="$candidate"; break; fi
done

# --- yardımcılar ---------------------------------------------------------------

# Satır sonu yorumunu ve baştaki/sondaki boşluğu atar.
strip_comment() { sed -e 's/[[:space:]]#.*$//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'; }

# .env.example'dan NAME'in son atanan değeri (tırnaksız, yorumsuz).
env_value() {
  grep -E "^(export[[:space:]]+)?$1=" "$ENV_FILE" 2>/dev/null | tail -n 1 \
    | sed -E "s/^(export[[:space:]]+)?$1=//" | strip_comment | sed -E "s/^[\"']//; s/[\"']\$//"
}

# ${VAR}, ${VAR:-varsayılan}, ${VAR:?hata} ifadelerini .env.example'a göre çözer; çözülemeyen kalır.
resolve_vars() {
  local s="$1" name op rest value full
  local re='\$\{([A-Za-z_][A-Za-z0-9_]*)(:?[-?+])?([^}]*)\}'
  while [[ "$s" =~ $re ]]; do
    full="${BASH_REMATCH[0]}"; name="${BASH_REMATCH[1]}"; op="${BASH_REMATCH[2]}"; rest="${BASH_REMATCH[3]}"
    value="$(env_value "$name")"
    if [ -z "$value" ]; then
      case "$op" in
        :-|-) value="$rest" ;;
        *) value="?" ;;
      esac
    fi
    s="${s/"$full"/$value}"
  done
  printf '%s' "$s"
}

# compose'un host'ta yayımladığı portlar (satır başına bir tane). Yorum satırları sayılmaz.
published_ports() {
  [ -n "$COMPOSE_FILE" ] || return 0
  local line item
  # Kısa sözdizimi: "HOST:CONTAINER", "IP:HOST:CONTAINER"
  grep -vE '^[[:space:]]*#' "$COMPOSE_FILE" | grep -E '^[[:space:]]*-[[:space:]]*["'"'"']?[^"'"'"'#]+:[^"'"'"'#]+["'"'"']?[[:space:]]*(#.*)?$' \
    | while IFS= read -r line; do
        item="$(printf '%s' "$line" | strip_comment | sed -E "s/^-[[:space:]]*//; s/^[\"']//; s/[\"']\$//; s#/(tcp|udp)\$##")"
        item="$(resolve_vars "$item")"
        printf '%s\n' "$item" | grep -E '^([0-9.]+:)?[0-9]+:[0-9]+$' | awk -F: 'NF==2{print $1} NF==3{print $2}'
      done
  # Uzun sözdizimi: published: 9025
  grep -vE '^[[:space:]]*#' "$COMPOSE_FILE" | grep -E '^[[:space:]]*published:' \
    | while IFS= read -r line; do
        item="$(printf '%s' "$line" | strip_comment | sed -E "s/^published:[[:space:]]*//; s/^[\"']//; s/[\"']\$//")"
        item="$(resolve_vars "$item")"
        printf '%s\n' "$item" | grep -E '^[0-9]+$'
      done
}

# --- 1. Dosyalar ---------------------------------------------------------------
# Neden: compose ya da .env.example olmadan "make env-up" kullanıcının makinesinde tekrarlanamaz.
section "dosyalar"

if [ -z "$COMPOSE_FILE" ]; then
  fail "compose dosyası yok (compose.yaml, compose.yml, docker-compose.yaml ya da docker-compose.yml)"
else
  pass "$COMPOSE_FILE"
  # Neden: ikisi de varsa Compose compose.yaml'ı seçer; eski dosyadaki servisler sessizce yok sayılır.
  compose_count=0
  for candidate in compose.yaml compose.yml docker-compose.yaml docker-compose.yml; do
    [ -f "$candidate" ] && compose_count=$((compose_count + 1))
  done
  [ "$compose_count" -gt 1 ] && fail "birden çok compose dosyası var — Compose yalnız ilkini okur ($COMPOSE_FILE); birleştir, fazlasını sil"
fi

if [ ! -f "$ENV_FILE" ]; then
  fail "$ENV_FILE yok — yerel varsayılanlar (mock adresleri dahil) burada tutulur"
else
  pass "$ENV_FILE"
fi

# --- 2. Komut adları -----------------------------------------------------------
# Neden: Tekan ve agent'lar bu dört adı arar; her projede aynı olmazsa "ortamı kaldır" her seferinde keşif gerektirir.
section "komutlar"

has_command() {
  local name="$1"
  if [ -f Makefile ] && grep -qE "^$name[[:space:]]*:" Makefile; then return 0; fi
  if [ -f package.json ] && grep -qE "\"$name\"[[:space:]]*:" package.json; then return 0; fi
  return 1
}

if [ ! -f Makefile ] && [ ! -f package.json ]; then
  fail "Makefile ya da package.json yok — env-up, env-down, db-reset, dev komutları tanımlanamaz"
else
  for command_name in env-up env-down db-reset dev; do
    if has_command "$command_name"; then
      pass "$command_name"
    else
      fail "'$command_name' tanımlı değil (Makefile hedefi ya da package.json script'i) — adlar her projede aynı olmalı"
    fi
  done
fi

# --- 3. Postgres major sürümü --------------------------------------------------
# Neden: prod'la aynı major sürüm yerelde de kullanılır; `latest` sessizce major atlatır ve migration farklı davranır.
section "postgres"

if [ -n "$COMPOSE_FILE" ]; then
  postgres_images=0
  while IFS= read -r image; do
    [ -n "$image" ] || continue
    postgres_images=$((postgres_images + 1))
    tag="${image#*:}"
    if [ "$tag" = "$image" ] || ! printf '%s' "$tag" | grep -qE '^(pg)?[0-9]+'; then
      fail "Postgres imajı major sürüme sabit değil: '$image' (prod'la aynı major'ı yaz, ör. postgres:<major>)"
    else
      pass "Postgres imajı sabit: $image"
    fi
  done < <(grep -vE '^[[:space:]]*#' "$COMPOSE_FILE" | grep -E '^[[:space:]]*image:' \
             | sed -E "s/^[[:space:]]*image:[[:space:]]*//" | strip_comment | sed -E "s/^[\"']//; s/[\"']\$//" \
             | grep -E '(^|/)(postgres|pgvector)(:|$)')
  if [ "$postgres_images" -eq 0 ]; then
    note "compose'ta Postgres imajı yok (başka veritabanı kullanılıyor olabilir)"
  fi

  # Veri birimi yolu major'a göre değişir (resmî imaj dokümanı); yanlış yola bağlanan birim veriyi kalıcı tutmaz.
  # Neden: yanlış yolda Postgres anonim birime yazar; `down` sonrası veri sessizce kaybolur.
  major="$(grep -vE '^[[:space:]]*#' "$COMPOSE_FILE" | grep -E '^[[:space:]]*image:' | grep -E '(^|/|["'"'"' ])(postgres|pgvector)' \
            | head -n 1 | sed -nE 's/.*:(pg)?([0-9]+).*/\2/p')"
  mount="$(grep -vE '^[[:space:]]*#' "$COMPOSE_FILE" | grep -oE ':/var/lib/postgresql(/data)?["'"'"']?[[:space:]]*$' | head -n 1 | sed -E "s/^://; s/[\"']//g; s/[[:space:]]+\$//")"
  if [ -n "$major" ] && [ -n "$mount" ]; then
    if [ "$major" -ge 18 ] && [ "$mount" = "/var/lib/postgresql/data" ]; then
      fail "Postgres $major için veri birimi /var/lib/postgresql yoluna bağlanmalı (bulunan: $mount)"
    elif [ "$major" -le 17 ] && [ "$mount" = "/var/lib/postgresql" ]; then
      fail "Postgres $major için veri birimi /var/lib/postgresql/data yoluna bağlanmalı (bulunan: $mount) — aksi halde veri kalıcı olmaz"
    else
      pass "veri birimi yolu major ile uyumlu ($mount)"
    fi
  fi
fi

# --- 4. *_BASE_URL → mock ------------------------------------------------------
# Neden: mock'u olmayan yeni bir dış bağlantı yerelde sessizce gerçek API'ye gider ve para harcar.
section "dış bağlantılar (*_BASE_URL)"

if [ -f "$ENV_FILE" ]; then
  published="$(published_ports | sort -u)"
  urls=0
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    urls=$((urls + 1))
    name="$(printf '%s' "$line" | sed -E 's/^(export[[:space:]]+)?([A-Za-z0-9_]+)=.*/\2/')"
    value="$(env_value "$name")"
    if printf '%s' "$line" | grep -qE '#[[:space:]]*env-check:[[:space:]]*real'; then
      note "$name gerçek servise işaretli (env-check: real) — maliyeti .env.example yorumunda yazılı mı?"
      continue
    fi
    if printf '%s' "$line" | grep -qE '#[[:space:]]*env-check:[[:space:]]*process'; then
      pass "$name mock ayrı süreçte (env-check: process): $value"
      continue
    fi
    if [ -z "$value" ]; then
      fail "$name boş — yerel mock adresini yaz (http://localhost:<port>) ya da gerçekse '# env-check: real' ekle"
      continue
    fi
    host="$(printf '%s' "$value" | sed -E 's#^[a-zA-Z][a-zA-Z0-9+.-]*://([^/:]+).*#\1#')"
    port="$(printf '%s' "$value" | sed -nE 's#^[a-zA-Z][a-zA-Z0-9+.-]*://[^/:]+:([0-9]+).*#\1#p')"
    case "$host" in
      localhost|127.0.0.1|0.0.0.0)
        if [ -z "$port" ]; then
          fail "$name=$value yerel ama port yok — mock'un yayımlanan portunu yaz"
        elif printf '%s\n' "$published" | grep -qx "$port"; then
          pass "$name → localhost:$port (compose mock)"
        else
          fail "$name=$value ama compose '$port' portunu yayımlamıyor — mock servisini $COMPOSE_FILE'a ekle (ya da mock compose dışındaysa '# env-check: process')"
        fi
        ;;
      *)
        fail "$name=$value yerel değil — yerelde sessizce gerçek servise gider. Mock adresi yaz ya da bilerek gerçekse '# env-check: real' ekle"
        ;;
    esac
  done < <(grep -E '^(export[[:space:]]+)?[A-Za-z0-9_]*_BASE_URL=' "$ENV_FILE")
  if [ "$urls" -eq 0 ]; then
    note "$ENV_FILE'da *_BASE_URL yok (dış bağlantı yoksa normal)"
  fi
fi

# --- 5. Yer tutucular ----------------------------------------------------------
# Neden: kurulumdan kalan <PLACEHOLDER ... > ile CI yeşil görünür ama ortam çalışmaz.
section "yer tutucular"

placeholder_files=0
for file in "$COMPOSE_FILE" Makefile "$ENV_FILE" .github/workflows/db-reset.yml; do
  [ -n "$file" ] && [ -f "$file" ] || continue
  if grep -qE '<PLACEHOLDER' "$file"; then
    fail "$file: doldurulmamış <PLACEHOLDER ...> var"
    placeholder_files=$((placeholder_files + 1))
  fi
done
[ "$placeholder_files" -eq 0 ] && pass "doldurulmamış yer tutucu yok"

# --- sonuç ---------------------------------------------------------------------
printf '\n'
if [ "$FAILURES" -gt 0 ]; then
  printf '\033[31m%s kontrol başarısız\033[0m\n' "$FAILURES"
  exit 1
fi
printf '\033[32mtüm kontroller geçti\033[0m\n'
