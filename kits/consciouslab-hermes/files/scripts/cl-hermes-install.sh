#!/usr/bin/env bash
# cl-hermes eklentisini BİR Hermes profiline kurar: kopyalar, anahtar üretir, config şablonunu yazdırır.
# Kullanım: bash scripts/cl-hermes-install.sh <profil-dizini> <cl_hermes-kaynak-dizini>
#   profil dizini  varsayılan profil: ~/.hermes ; adlı profil: ~/.hermes/profiles/<ad>
#   kaynak dizini  auth reposunun clients/hermes/cl_hermes klasörü (SKILL.md "Yöntem" 1)
# Profil başına BİR kez, her profil için ayrı çalıştırılır (ayrı anahtar, ayrı agent).
# Özel anahtar ekrana basılmaz; yalnız açık anahtar (JWK) yazdırılır. Var olan anahtarın üstüne yazılmaz.
set -euo pipefail

PROFILE_HOME="${1:?profil dizini gerekli}"
PLUGIN_SRC="${2:?cl_hermes kaynak dizini gerekli}"
PYTHON="${HERMES_PYTHON:-python3}"   # Hermes'in kendi Python'u (httpx, PyJWT, cryptography içinde)

[ -f "$PLUGIN_SRC/plugin.yaml" ] || { echo "HATA: $PLUGIN_SRC/plugin.yaml yok (yanlış dizin)"; exit 1; }
[ -d "$PROFILE_HOME" ] || { echo "HATA: profil dizini yok: $PROFILE_HOME"; exit 1; }

mkdir -p "$PROFILE_HOME/plugins"
rm -rf "$PROFILE_HOME/plugins/cl-hermes"
cp -R "$PLUGIN_SRC" "$PROFILE_HOME/plugins/cl-hermes"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
cp -R "$PLUGIN_SRC" "$WORK/cl_hermes"
PYTHONPATH="$WORK" "$PYTHON" -m cl_hermes keygen --profile-home "$PROFILE_HOME"

echo
echo "Sonraki: panelde agent kaydı (JWK), $PROFILE_HOME/cl-hermes/config.json (chmod 600),"
echo "hermes plugins enable cl-hermes (bu profil için), gateway yeniden başlat."
