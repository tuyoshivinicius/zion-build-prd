#!/usr/bin/env bash
# Auto-teste do check-prd.sh contra fixtures. Roda pela camada mecânica (scripts/eval.sh).
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

# 4. specify limpo (com o pedido de **RF cobertos:**) via stdin → exit 0
out="$(printf 'O usuário edita o diagrama e vê a prévia atualizar ao digitar.\nPeça que o spec.md inclua a linha **RF cobertos:** RF-01 com os RF que a spec cobre.\n' | bash "$CHECK" specify -)"; rc=$?
assert_exit "specify limpo sai 0" 0 "$rc"

# 5. specify sem o pedido de **RF cobertos:** → exit 1 + rf-cobertos-ausente
out="$(bash "$CHECK" specify - < "$FIX/specify-sem-rf.txt")"; rc=$?
assert_exit "specify sem RF sai 1" 1 "$rc"
assert_contains "specify sem RF acha rf-cobertos-ausente" "rf-cobertos-ausente" "$out"

# 6. PRD dia-2 limpa (§13 + §8 coerentes com docs/adr/ vizinho) → exit 0
out="$(bash "$CHECK" prd "$FIX/prd-evolve/clean/PRD.md")"; rc=$?
assert_exit "prd dia-2 limpa sai 0" 0 "$rc"
assert_contains "prd dia-2 limpa reporta limpo" "check-prd: limpo" "$out"

# 7. PRD dia-2 suja → exit 1 + um achado de cada tipo novo
out="$(bash "$CHECK" prd "$FIX/prd-evolve/dirty/PRD.md")"; rc=$?
assert_exit "prd dia-2 suja sai 1" 1 "$rc"
assert_contains "acha changelog-rf-inexistente"   "changelog-rf-inexistente"   "$out"
assert_contains "acha changelog-cenario-invalido" "changelog-cenario-invalido" "$out"
assert_contains "acha changelog-adr-inexistente"  "changelog-adr-inexistente"  "$out"
assert_contains "acha restricao-morta"            "restricao-morta"            "$out"

if [ "$fail" -eq 0 ]; then echo "test-check-prd: tudo verde"; else echo "test-check-prd: FALHOU"; exit 1; fi
