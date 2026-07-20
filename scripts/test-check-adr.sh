#!/usr/bin/env bash
# Auto-teste do check-adr.sh contra fixtures. Semente da suíte de avaliação (R7).
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
CHECK="scripts/check-adr.sh"
FIX="scripts/fixtures/adr"
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
assert_contains "clean reporta limpo" "check-adr: limpo" "$out"
assert_contains "clean não acusa area-ausente" "check-adr: limpo" "$out"

# 2. Fixture dirty → exit 1 + um achado de cada tipo.
# spike-dir-vazio precisa de um dir vazio (git não versiona dir vazio) → cria em runtime.
mkdir -p "$FIX/dirty/spikes/ADR-005-vazio"
out="$(bash "$CHECK" "$FIX/dirty")"; rc=$?
rm -rf "$FIX/dirty/spikes/ADR-005-vazio"
assert_exit "dirty sai 1" 1 "$rc"
assert_contains "dirty acha sem-evidencia"        "sem-evidencia" "$out"
assert_contains "dirty acha spike-dir-ausente"    "spike-dir-ausente" "$out"
assert_contains "dirty acha spike-dir-vazio"      "spike-dir-vazio" "$out"
assert_contains "dirty acha spike-sem-readme"     "spike-sem-readme" "$out"
assert_contains "dirty acha evidencia-sem-lastro" "evidencia-sem-lastro" "$out"
assert_contains "dirty acha decisao-dada-sem-racional" "decisao-dada-sem-racional" "$out"
assert_contains "dirty acha area-ausente"             "area-ausente" "$out"

# 3. Erro de uso: dir inexistente → exit 2
out="$(bash "$CHECK" "$FIX/nao-existe" 2>&1)"; rc=$?
assert_exit "dir inexistente sai 2" 2 "$rc"

# 4. Supersessão simétrica → limpa (exit 0)
out="$(bash "$CHECK" "$FIX/superseded-clean")"; rc=$?
assert_exit "supersessão simétrica sai 0" 0 "$rc"
assert_contains "supersessão simétrica reporta limpo" "check-adr: limpo" "$out"

# 5. Supersessão assimétrica (referência unilateral) → exit 1 + achado
out="$(bash "$CHECK" "$FIX/superseded-dirty")"; rc=$?
assert_exit "supersessão assimétrica sai 1" 1 "$rc"
assert_contains "acha supersessao-assimetrica" "supersessao-assimetrica" "$out"

if [ "$fail" -eq 0 ]; then echo "test-check-adr: tudo verde"; else echo "test-check-adr: FALHOU"; exit 1; fi
