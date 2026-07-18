#!/usr/bin/env bash
# Auto-teste do check-estudo.sh contra fixtures. Roda pela camada mecânica (scripts/eval.sh).
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
CHECK="scripts/check-estudo.sh"
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
assert_not_contains() {  # desc  agulha  palheiro
  if printf '%s' "$3" | grep -qi -- "$2"; then echo "FALHOU: $1 (achou indevido: $2)"; fail=1
  else echo "ok: $1"; fi
}

# 1. Estudo limpo → exit 0 / limpo. O termo "typescript" no Contexto NÃO pode ser achado
#    (a denylist só varre Alternativas e ROI).
out="$(bash "$CHECK" "$FIX/estudo-clean.md")"; rc=$?
assert_exit "estudo limpo sai 0" 0 "$rc"
assert_contains "estudo limpo reporta limpo" "check-estudo: limpo" "$out"
assert_not_contains "denylist não vaza para o Contexto" "typescript" "$out"

# 2. Estudo sujo → exit 1 + um achado de cada tipo.
out="$(bash "$CHECK" "$FIX/estudo-dirty.md")"; rc=$?
assert_exit "estudo sujo sai 1" 1 "$rc"
assert_contains "acha secao-ausente"      "secao-ausente"      "$out"
assert_contains "aponta a Recomendação"   "Recomenda"          "$out"
assert_contains "acha nao-fazer-ausente"  "nao-fazer-ausente"  "$out"
assert_contains "acha stack nas Alternativas" "react"          "$out"
assert_contains "acha stack no ROI"       "redis"              "$out"

# 3. Sem argumento → exit 2 (erro de uso).
out="$(bash "$CHECK" 2>/dev/null)"; rc=$?
assert_exit "sem argumento sai 2" 2 "$rc"

# 4. Arquivo inexistente → exit 2.
out="$(bash "$CHECK" /caminho/que/nao/existe.md 2>/dev/null)"; rc=$?
assert_exit "arquivo inexistente sai 2" 2 "$rc"

if [ "$fail" -eq 0 ]; then echo "test-check-estudo: tudo verde"; else echo "test-check-estudo: FALHOU"; exit 1; fi
