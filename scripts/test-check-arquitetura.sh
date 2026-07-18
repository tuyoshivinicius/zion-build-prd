#!/usr/bin/env bash
# Auto-teste do check-arquitetura.sh contra fixtures limpa/suja (NFR-04). Roda pela camada mecânica (scripts/eval.sh).
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
CHECK="scripts/check-arquitetura.sh"
FIX="scripts/fixtures/arquitetura"
fail=0

assert_exit() {  # desc  exit_esperado  exit_veio
  if [ "$2" != "$3" ]; then echo "FALHOU: $1 (exit esperado $2, veio $3)"; fail=1
  else echo "ok: $1"; fi
}
assert_contains() {  # desc  agulha  palheiro
  if printf '%s' "$3" | grep -qi -- "$2"; then echo "ok: $1"
  else echo "FALHOU: $1 (não achou: $2)"; fail=1; fi
}
assert_not_contains() {  # desc  agulha  palheiro
  if printf '%s' "$3" | grep -qi -- "$2"; then echo "FALHOU: $1 (achou indevido: $2)"; fail=1
  else echo "ok: $1"; fi
}

# 1. Fixture limpa → exit 0, sem achados.
out="$(bash "$CHECK" "$FIX/clean")"; rc=$?
assert_exit "clean sai 0" 0 "$rc"
assert_contains "clean reporta limpo" "check-arquitetura: limpo" "$out"
assert_not_contains "clean não acusa defasado" "defasad" "$out"

# 2. Fixture suja → exit 1 com os cinco achados.
out="$(bash "$CHECK" "$FIX/dirty")"; rc=$?
assert_exit "dirty sai 1" 1 "$rc"
assert_contains "acha secao-ausente" "secao-ausente" "$out"
assert_contains "acha visao-vazia" "visao-vazia" "$out"
assert_contains "acha adr-index-defasado" "adr-index-defasado" "$out"
assert_contains "acha backlog-view-defasada" "backlog-view-defasada" "$out"
assert_contains "acha regras-defasadas" "regras-defasadas" "$out"

# 3. Repo vazio → arquitetura-ausente + regras-ausentes (e nada de erro).
empty="$(mktemp -d)"
out="$(bash "$CHECK" "$empty")"; rc=$?
assert_exit "repo vazio sai 1" 1 "$rc"
assert_contains "acha arquitetura-ausente" "arquitetura-ausente" "$out"
assert_contains "acha regras-ausentes" "regras-ausentes" "$out"
rmdir "$empty"

# 4. ROOT inexistente → exit 2.
out="$(bash "$CHECK" nao/existe 2>/dev/null)"; rc=$?
assert_exit "ROOT inexistente sai 2" 2 "$rc"

if [ "$fail" -eq 0 ]; then echo "test-check-arquitetura: tudo verde"; else echo "test-check-arquitetura: FALHOU"; exit 1; fi
