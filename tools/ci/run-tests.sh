#!/usr/bin/env bash
# Steppeborn — GDUnit4 birim testlerini headless çalıştırır.
#
# Kullanım:
#   GODOT=/path/to/Godot tools/ci/run-tests.sh [test_yolu]
#
# GODOT ayarlı değilse yaygın macOS konumu denenir.
# Test yolu verilmezse tüm birim testleri çalışır (res://tests/unit).
#
# Not: Godot 4.7 + GDUnit4 v6.x. Headless'ta InputEvent gerektiren testler
# çalışmaz; saf mantık testleri için --ignoreHeadlessMode kullanılır.

set -euo pipefail

GODOT="${GODOT:-/Users/$USER/Downloads/Applications/Godot.app/Contents/MacOS/Godot}"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../game" && pwd)"
TEST_PATH="${1:-res://tests/unit}"

if [[ ! -x "$GODOT" ]]; then
  echo "HATA: Godot bulunamadı: $GODOT (GODOT ortam değişkenini ayarla)" >&2
  exit 1
fi

cd "$PROJECT_DIR"

# Class cache'in güncel olması için önce import (ilk çalıştırmada gerekli).
"$GODOT" --headless --import >/dev/null 2>&1 || true

"$GODOT" --headless \
  -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd \
  --ignoreHeadlessMode \
  -a "$TEST_PATH"
