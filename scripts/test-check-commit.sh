#!/usr/bin/env bash
# Auto-teste do check-commit.sh contra fixtures. Roda pela camada mecânica (scripts/eval.sh).
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
CHECK="scripts/check-commit.sh"
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

# 1. Mensagem conforme → exit 0.
out="$(bash "$CHECK" "$FIX/commit-clean.txt")"; rc=$?
assert_exit "commit conforme sai 0" 0 "$rc"
assert_contains "reporta conforme" "conforme" "$out"

# 2. Mensagem fora da convenção → exit 1 + achado.
out="$(bash "$CHECK" "$FIX/commit-dirty.txt")"; rc=$?
assert_exit "commit fora da convenção sai 1" 1 "$rc"
assert_contains "acha fora-da-convencao" "fora-da-convencao" "$out"

# 3. Sem argumento → exit 2 (erro de uso).
out="$(bash "$CHECK" 2>/dev/null)"; rc=$?
assert_exit "sem argumento sai 2" 2 "$rc"

# 4. Arquivo inexistente → exit 2.
out="$(bash "$CHECK" /caminho/que/nao/existe 2>/dev/null)"; rc=$?
assert_exit "arquivo inexistente sai 2" 2 "$rc"

if [ "$fail" -eq 0 ]; then echo "test-check-commit: tudo verde"; else echo "test-check-commit: FALHOU"; exit 1; fi
