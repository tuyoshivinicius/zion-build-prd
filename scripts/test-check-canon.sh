#!/usr/bin/env bash
# Auto-teste do check-canon.sh contra fixtures. Roda pela camada mecânica (scripts/eval.sh).
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
CHECK="scripts/check-canon.sh"
FIX="scripts/fixtures/canon"
fail=0

assert_exit() {  # desc  exit_esperado  exit_veio
  if [ "$2" != "$3" ]; then echo "FALHOU: $1 (exit esperado $2, veio $3)"; fail=1
  else echo "ok: $1"; fi
}
assert_contains() {  # desc  agulha  palheiro
  if printf '%s' "$3" | grep -qi -- "$2"; then echo "ok: $1"
  else echo "FALHOU: $1 (não achou: $2)"; fail=1; fi
}

# 1. Fixture clean → exit 0 / limpo
out="$(bash "$CHECK" "$FIX/clean")"; rc=$?
assert_exit "clean sai 0" 0 "$rc"
assert_contains "clean reporta limpo" "check-canon: limpo" "$out"

# 2. Fixture dirty → exit 1 + um achado de cada tipo
out="$(bash "$CHECK" "$FIX/dirty")"; rc=$?
assert_exit "dirty sai 1" 1 "$rc"
assert_contains "acha skill-sem-rf"       "skill-sem-rf"       "$out"
assert_contains "acha skill-fantasma"     "skill-fantasma"     "$out"
assert_contains "acha script-sem-doc"     "script-sem-doc"     "$out"
assert_contains "acha asset-sem-doc"      "asset-sem-doc"      "$out"
assert_contains "acha adr-sem-indice"     "adr-sem-indice"     "$out"
assert_contains "acha regra-raiz-sem-sot" "regra-raiz-sem-sot" "$out"
assert_contains "dogfood acha stack (via check-prd)" "stack" "$out"

# 3. ROOT inexistente → exit 2
out="$(bash "$CHECK" /caminho/que/nao/existe 2>&1)"; rc=$?
assert_exit "root inexistente sai 2" 2 "$rc"

if [ "$fail" -eq 0 ]; then echo "test-check-canon: tudo verde"; else echo "test-check-canon: FALHOU"; exit 1; fi
