#!/usr/bin/env bash
# ULUS — GDUnit4 birim testlerini headless çalıştırır.
#
# Kullanım:
#   GODOT=/path/to/Godot tools/ci/run-tests.sh [test_yolu]
#
# GODOT ayarlı değilse sırayla denenir: /Applications, ~/Applications,
# ~/Downloads/Applications (macOS), ardından PATH'teki `godot`.
# Test yolu verilmezse birim ve entegrasyon testleri çalışır (res://tests/unit, res://tests/integration).
# Testlerden sonra palet doğrulayıcı çalışır (tools/asset-pipeline/validate_palette.gd)
# ve GameState.modifiers erişim denetimi (ADR-0006) yapılır.
#
# Not: Godot 4.7 + GDUnit4 v6.x. Headless'ta InputEvent gerektiren testler
# çalışmaz; saf mantık testleri için --ignoreHeadlessMode kullanılır.

set -euo pipefail

if [[ -z "${GODOT:-}" ]]; then
  for candidate in \
    "/Applications/Godot.app/Contents/MacOS/Godot" \
    "$HOME/Applications/Godot.app/Contents/MacOS/Godot" \
    "$HOME/Downloads/Applications/Godot.app/Contents/MacOS/Godot" \
    "$(command -v godot || true)"; do
    if [[ -n "$candidate" && -x "$candidate" ]]; then
      GODOT="$candidate"
      break
    fi
  done
fi
GODOT="${GODOT:-}"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../game" && pwd)"
# Yol verilmezse birim + entegrasyon testleri (entegrasyon: gerçek user:// dosyaları — C-56).
if [[ -n "${1:-}" ]]; then
  TEST_ARGS=(-a "$1")
else
  TEST_ARGS=(-a res://tests/unit -a res://tests/integration)
fi

if [[ ! -x "$GODOT" ]]; then
  echo "HATA: Godot bulunamadı${GODOT:+: $GODOT} (GODOT ortam değişkenini ayarla)" >&2
  exit 1
fi

cd "$PROJECT_DIR"

# Runner eksikse Godot "script bulunamadı" deyip yine 0 döner — sessizce geçmesin.
if [[ ! -f addons/gdUnit4/bin/GdUnitCmdTool.gd ]]; then
  echo "HATA: GDUnit4 runner yok: addons/gdUnit4/bin/GdUnitCmdTool.gd" >&2
  exit 1
fi

# Class cache'in güncel olması için önce import (ilk çalıştırmada gerekli).
"$GODOT" --headless --import >/dev/null 2>&1 || true

# Her iki adım da çalışır; biri başarısızsa betik sıfır olmayan kodla biter.
set +e
"$GODOT" --headless \
  -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd \
  --ignoreHeadlessMode \
  "${TEST_ARGS[@]}"
TEST_EXIT=$?

# Palet doğrulama (art bible §8): game/assets/art altındaki PNG'ler global palette uymalı.
"$GODOT" --headless --path . \
  --script ../tools/asset-pipeline/validate_palette.gd \
  -- "$PROJECT_DIR/../art-source/global_palette_ulus.gpl" res://assets/art
PALETTE_EXIT=$?

# ADR-0006: GameState.modifiers yalnızca features/modifiers/ içinden okunur/yazılır —
# tüketiciler StatResolver kullanır (çift sayım engeli). Testler ve addon'lar hariç.
MODIFIER_EXIT=0
MODIFIER_HITS="$(grep -rnE '\.modifiers([^A-Za-z0-9_]|$)' --include='*.gd' . \
  | grep -vE '^\./(features/modifiers|tests|addons)/' || true)"
if [[ -n "$MODIFIER_HITS" ]]; then
  echo "HATA: GameState.modifiers features/modifiers/ dışında kullanılıyor (ADR-0006):" >&2
  echo "$MODIFIER_HITS" >&2
  MODIFIER_EXIT=1
fi

# ADR-0007: kayıt kodu kullanıcı dosyasını asla nesne/kaynak olarak yüklemez (kod çalıştırma riski).
SAVE_EXIT=0
SAVE_HITS="$(grep -rnE '(^|[^_.A-Za-z])load\(|ResourceLoader|str_to_var|bytes_to_var|get_var\(' \
  --include='*.gd' features/save | grep -vE '^[^:]+:[0-9]+:[[:space:]]*#' || true)"
if [[ -n "$SAVE_HITS" ]]; then
  echo "HATA: features/save/ içinde yasak yükleme çağrısı (ADR-0007):" >&2
  echo "$SAVE_HITS" >&2
  SAVE_EXIT=1
fi
# scene-flow AC27 / art bible §7: anlatı ve sahne akışı ekranlarında alfa fade yok
# (modulate / self_modulate tween'i ya da alfa ataması).
FADE_EXIT=0
FADE_HITS="$(grep -rnE '(self_)?modulate' --include='*.gd' features/campaign contexts/narrative_context \
  contexts/chapter_select_context | grep -vE '^[^:]+:[0-9]+:[[:space:]]*#' || true)"
if [[ -n "$FADE_HITS" ]]; then
  echo "HATA: sahne akışı ekranlarında modulate kullanımı (alfa fade yasak, scene-flow AC27):" >&2
  echo "$FADE_HITS" >&2
  FADE_EXIT=1
fi
# C-42: kaynakta çıplak U+FEFF (BOM) dışa aktarmada silinir → sabit boş string olur ve kayıt /
# ayar ayrıştırması export'ta bozulur. Görünmez karakter yerine "\uFEFF" kaçışı kullanılır.
BOM_EXIT=0
BOM_HITS="$(LC_ALL=C.UTF-8 grep -rlP '\x{FEFF}' --include='*.gd' --include='*.tscn' --include='*.tres' . \
  | grep -vE '^\./addons/' || true)"
if [[ -n "$BOM_HITS" ]]; then
  echo "HATA: kaynakta çıplak U+FEFF (dışa aktarmada silinir; \\uFEFF kaçışı kullan):" >&2
  echo "$BOM_HITS" >&2
  BOM_EXIT=1
fi
set -e

if [[ $TEST_EXIT -ne 0 ]]; then
  echo "HATA: testler başarısız (exit $TEST_EXIT)" >&2
  exit "$TEST_EXIT"
fi
if [[ $PALETTE_EXIT -ne 0 ]]; then
  echo "HATA: palet doğrulama başarısız (exit $PALETTE_EXIT)" >&2
  exit "$PALETTE_EXIT"
fi
if [[ $FADE_EXIT -ne 0 ]]; then
  exit "$FADE_EXIT"
fi
if [[ $MODIFIER_EXIT -ne 0 ]]; then
  exit "$MODIFIER_EXIT"
fi
if [[ $SAVE_EXIT -ne 0 ]]; then
  exit "$SAVE_EXIT"
fi
if [[ $BOM_EXIT -ne 0 ]]; then
  exit "$BOM_EXIT"
fi
