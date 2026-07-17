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

# 2. PRD suja → exit 1 + achado de stack
out="$(bash "$CHECK" prd "$FIX/prd-dirty.md")"; rc=$?
assert_exit "prd suja sai 1" 1 "$rc"
assert_contains "prd suja acha stack" "stack" "$out"
assert_contains "prd suja acha termo react" "react" "$out"
assert_contains "prd suja acha nfr sem numero" "nfr-sem-numero" "$out"
assert_contains "prd suja acha rf fora de epico" "rf-fora-de-epico" "$out"

# 3. specify sujo via stdin → exit 1 + stack
out="$(bash "$CHECK" specify - < "$FIX/specify-dirty.txt")"; rc=$?
assert_exit "specify sujo sai 1" 1 "$rc"
assert_contains "specify sujo acha stack" "stack" "$out"

# 4. specify limpo via stdin → exit 0
out="$(printf 'O usuário edita o diagrama e vê a prévia atualizar ao digitar.\n' | bash "$CHECK" specify -)"; rc=$?
assert_exit "specify limpo sai 0" 0 "$rc"

if [ "$fail" -eq 0 ]; then echo "test-check-prd: tudo verde"; else echo "test-check-prd: FALHOU"; exit 1; fi
