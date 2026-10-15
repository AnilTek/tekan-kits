#!/usr/bin/env bash
# doc-guard — dokümantasyon taksonomisinin yapısal kontrolü.
# İçeriği yargılamaz; yalnızca sözleşmenin bozulmadığını doğrular.
# Kaynak: tekan-kits/docs-os (managed dosya). Bu dosyayı projede düzenleme; kit'te düzelt.
# Projeye özgü kontrol: assets/scripts/doc-guard.local.sh (varsa en sonda çalışır).
# Kullanım: bash assets/scripts/doc-guard.sh
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

FAILURES=0

fail() { printf '  \033[31mFAIL\033[0m %s\n' "$1"; FAILURES=$((FAILURES + 1)); }
pass() { printf '  \033[32mok\033[0m   %s\n' "$1"; }
section() { printf '\n%s\n' "$1"; }

in_git() { command -v git >/dev/null 2>&1 && git rev-parse --git-dir >/dev/null 2>&1; }

# --- 1. Router sözleşmesi ------------------------------------------------------
# Neden: iki yerde yönlendirici tutmak ikisinin ayrışmasıyla biter; uzayan router okunmaz.
section "router"

if [ ! -f AGENTS.md ]; then
  fail "AGENTS.md yok"
else
  lines=$(wc -l < AGENTS.md | tr -d ' ')
  if [ "$lines" -gt 150 ]; then
    fail "AGENTS.md $lines satır (limit 150) — router içerik tutmaya başlamış, slot dosyalarına taşı"
  else
    pass "AGENTS.md $lines satır (limit 150)"
  fi
fi

if [ ! -f CLAUDE.md ]; then
  fail "CLAUDE.md yok"
elif [ "$(head -n 1 CLAUDE.md)" != "@AGENTS.md" ]; then
  fail "CLAUDE.md ilk satırı '@AGENTS.md' olmalı (bulunan: '$(head -n 1 CLAUDE.md)')"
else
  pass "CLAUDE.md → @AGENTS.md"
fi

# --- 2. Slotlar ----------------------------------------------------------------
# Neden: şablon ya da stub silinince bir sonraki belge biçimi baştan uydurulur.
section "slotlar"

for slot in docs/canonical docs/canonical/integrations docs/decisions docs/intent \
            docs/inbox docs/_scratch skills assets; do
  if [ -d "$slot" ]; then pass "$slot"; else fail "$slot dizini yok"; fi
done

for f in docs/README.md docs/canonical/context.md docs/canonical/glossary.md \
         docs/canonical/architecture.md docs/canonical/security.md \
         docs/canonical/integrations/_template.md docs/decisions/_template.md \
         docs/intent/_template.md; do
  if [ -f "$f" ]; then pass "$f"; else fail "$f yok"; fi
done

# Neden: docs/ altında yeni klasör ya da serbest dosya taksonomiyi çatallar; ne konacağı belirsizleşir.
allowed_slots=" canonical decisions intent inbox _scratch _legacy "
slot_errors=0
for d in docs/*/; do
  [ -d "$d" ] || continue
  name="$(basename "$d")"
  case "$allowed_slots" in
    *" $name "*) ;;
    *) fail "docs/$name/ tanımlı bir slot değil (izinli:$allowed_slots)"; slot_errors=$((slot_errors + 1)) ;;
  esac
done
for f in docs/*; do
  [ -f "$f" ] || continue
  [ "$(basename "$f")" = "README.md" ] && continue
  fail "docs/ kökünde serbest dosya: $f — bir slota taşı"
  slot_errors=$((slot_errors + 1))
done
[ "$slot_errors" -eq 0 ] && pass "docs/ altında yalnız tanımlı slotlar"

# --- 3. Link bütünlüğü ---------------------------------------------------------
# Neden: kırık link agent'ı "dosya yok" diye özet uydurmaya iter.
# Şablonlar (yer tutucu link taşır) ve _legacy (donmuş, bakımı yapılmaz) atlanır.
section "linkler"

link_errors=0
link_sources=$(printf '%s\n' AGENTS.md; find docs -name '*.md' -type f -not -path 'docs/_legacy/*' -not -name '_template*.md' | sort)
for src in $link_sources; do
  [ -f "$src" ] || continue
  base="$(dirname "$src")"
  # Markdown link hedeflerini çıkar; dış URL, mailto ve saf anchor'ları atla.
  while IFS= read -r target; do
    case "$target" in
      http://*|https://*|mailto:*|"#"*|"") continue ;;
    esac
    target="${target%%#*}"
    [ -n "$target" ] || continue
    if [ ! -e "$base/$target" ]; then
      fail "$src → $target (hedef yok)"
      link_errors=$((link_errors + 1))
    fi
  done < <(grep -oE '\]\([^)]+\)' "$src" | sed -E 's/^\]\(//; s/\)$//')
done
[ "$link_errors" -eq 0 ] && pass "tüm göreli linkler çözülüyor"

# --- 4. ADR sözleşmesi ---------------------------------------------------------
# Neden: ADR'lere numarayla atıf yapılır; numarasız, durumsuz ya da kopuk zincirli ADR atıfı kırar.
section "decisions"

adr_count=0
for adr in docs/decisions/*.md; do
  [ -e "$adr" ] || continue
  name="$(basename "$adr")"
  case "$name" in _*) continue ;; esac
  adr_count=$((adr_count + 1))
  if ! printf '%s' "$name" | grep -qE '^[0-9]{4}-[a-z0-9]+(-[a-z0-9]+)*\.md$'; then
    fail "$adr — ad NNNN-<slug>.md biçiminde değil"
  fi
  # Birleşmiş ADR düzenlenmez; bu yüzden yerleşik yazımların hepsi kabul edilir:
  # `**Status**:`, `- **Durum:**`, `Durum: **Kabul**` (aynısı Date/Tarih için).
  grep -qE '^(- )?\**(Status|Durum)\**:' "$adr" || fail "$adr — Status (Durum) satırı yok"
  grep -qE '^(- )?\**(Date|Tarih)\**:'   "$adr" || fail "$adr — Date (Tarih) satırı yok"
  # Supersede zinciri kopuk olmamalı: işaret edilen ADR gerçekten var olmalı.
  superseder=$(grep -oE '^\*\*Status\*\*: Superseded by [0-9]{4}' "$adr" | grep -oE '[0-9]{4}$' || true)
  if [ -n "$superseder" ] && ! ls docs/decisions/"$superseder"-*.md >/dev/null 2>&1; then
    fail "$adr — 'Superseded by $superseder' ama $superseder numaralı ADR yok"
  fi
done
pass "$adr_count ADR kontrol edildi"

# --- 5. Canonical tazelik alanı ------------------------------------------------
# Neden: ne zaman doğrulandığı bilinmeyen "gerçek" sessizce eskir.
section "canonical"

for doc in docs/canonical/*.md docs/canonical/integrations/*.md; do
  [ -e "$doc" ] || continue
  case "$(basename "$doc")" in _*|README.md) continue ;; esac
  if ! head -n 5 "$doc" | grep -q '^last_reviewed:'; then
    fail "$doc — frontmatter'da last_reviewed yok"
  fi
done
pass "last_reviewed alanları kontrol edildi"

# --- 6. Commit edilmemesi gerekenler -------------------------------------------
# Neden: inbox/_scratch "işlenip silinir" alanıdır; git'e giren ham not canonical'la çelişir.
# .env'de sır durur; .gitignore'u `git add -f` ile aşmak sessiz sızıntıdır, burada gürültülü olur.
section "commit edilmemesi gerekenler"

if in_git; then
  stray="$(git ls-files docs/_scratch docs/inbox | grep -v '/\.gitkeep$' || true)"
  if [ -n "$stray" ]; then
    fail "geçici slotlarda commit edilmiş dosya var:"
    printf '       %s\n' $stray
  else
    pass "docs/_scratch ve docs/inbox temiz"
  fi

  # Yalnızca .env.example izlenir.
  env_leak="$(git ls-files | grep -E '(^|/)\.env($|\.)' | grep -v '\.env\.example$' || true)"
  if [ -n "$env_leak" ]; then
    fail "commit edilmiş .env dosyası var — sır sızmış olabilir:"
    printf '       %s\n' $env_leak
  else
    pass "commit edilmiş .env yok"
  fi
else
  pass "git yok — commit kontrolleri atlandı"
fi

# --- 7. Projeye özgü kontroller ------------------------------------------------
# Neden: kit'in dosyası her projede aynı kalmalı; projeye özgü kural ayrı dosyada yaşar ve güncellemede ezilmez.
if [ -f assets/scripts/doc-guard.local.sh ]; then
  section "projeye özgü (doc-guard.local.sh)"
  # shellcheck source=/dev/null
  . assets/scripts/doc-guard.local.sh
fi

# --- Sonuç ---------------------------------------------------------------------
printf '\n'
if [ "$FAILURES" -eq 0 ]; then
  printf '\033[32mdoc-guard: geçti\033[0m\n'
  exit 0
fi
printf '\033[31mdoc-guard: %d hata\033[0m\n' "$FAILURES"
exit 1
