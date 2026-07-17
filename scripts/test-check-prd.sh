#!/usr/bin/env bash
# Auto-teste do check-prd.sh contra fixtures. Semente da suíte de avaliação (R7).
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
CHECK="scripts/check-prd.sh"
FIX="scripts/fixtures"
fail=0

assert_exit() {  # desc  exit_esperado  exit_veio
  if [ "$2" != "$3" ]; then echo "FALHOU: $1 (exit esperado $2, veio $3)"; fail=1
  else echo "ok: $1"; fi
}
assert_contains() {  # desc  agulha  palheiro
  if printf '%s' "$3" | grep -qi -- "$2"; then echo "ok: $1"
  else echo "FALHOU: $1 (não achou: $2)"; fail=1; fi
}

# 1. PRD limpa → exit 0 / limpo
out="$(bash "$CHECK" prd "$FIX/prd-clean.md")"; rc=$?
assert_exit "prd limpa sai 0" 0 "$rc"
assert_contains "prd limpa reporta limpo" "check-prd: limpo" "$out"

if [ "$fail" -eq 0 ]; then echo "test-check-prd: tudo verde"; else echo "test-check-prd: FALHOU"; exit 1; fi
