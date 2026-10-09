#!/usr/bin/env bash
# Headless validation: import project, parse all scripts, instantiate main scene.
# Usage: tools/check.sh [path-to-godot-binary]
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${1:-${GODOT:-godot}}"
echo "== import =="
"$GODOT" --headless --import --path . >/tmp/godot_import.log 2>&1 || true
grep -E "ERROR|SCRIPT ERROR" /tmp/godot_import.log && { echo "import errors"; exit 1; } || echo "import ok"
echo "== scene smoke test =="
"$GODOT" --headless --path . res://tools/smoke_test.tscn 2>&1 | tee /tmp/godot_smoke.log
grep -qE "SMOKE OK" /tmp/godot_smoke.log && ! grep -qE "SCRIPT ERROR|ERROR:" /tmp/godot_smoke.log
