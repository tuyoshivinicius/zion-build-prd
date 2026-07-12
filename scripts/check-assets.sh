#!/usr/bin/env bash
# Falha se qualquer references/ de skill divergir do asset canônico em assets/.
# Guard contra drift silencioso da autocontenção.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail=0
check() { # $1=canônico  $2=cópia na skill
  if ! diff -q "$1" "$2" >/dev/null 2>&1; then
    echo "DRIFT: $2 difere de $1"
    fail=1
  fi
}

for s in prd-discovery prd-spike prd-write prd-decompose prd-constitution-prompt prd-specify-prompt; do
  check "assets/quality-rules.md" "skills/$s/references/quality-rules.md"
done
check "assets/templates/prd-skeleton.md" "skills/prd-write/references/prd-skeleton.md"
check "assets/templates/traceability-table.md" "skills/prd-decompose/references/traceability-table.md"

if [ "$fail" -eq 0 ]; then
  echo "check-assets: sem drift"
else
  echo "check-assets: FALHOU — rode scripts/sync-assets.sh"
  exit 1
fi
