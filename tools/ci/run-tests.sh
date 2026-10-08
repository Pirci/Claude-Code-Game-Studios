#!/usr/bin/env bash
# ULUS — GDUnit4 birim testlerini headless çalıştırır.
#
# Kullanım:
#   GODOT=/path/to/Godot tools/ci/run-tests.sh [test_yolu]
#
# GODOT ayarlı değilse sırayla denenir: /Applications, ~/Applications,
# ~/Downloads/Applications (macOS), ardından PATH'teki `godot`.
# Test yolu verilmezse tüm birim testleri çalışır (res://tests/unit).
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
TEST_PATH="${1:-res://tests/unit}"

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

"$GODOT" --headless \
  -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd \
  --ignoreHeadlessMode \
  -a "$TEST_PATH"
