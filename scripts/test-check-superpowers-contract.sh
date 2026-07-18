#!/usr/bin/env bash
# Auto-teste do check-superpowers-contract.sh contra fixtures (R9). Portável no CI:
# usa --skill apontando para fixtures, sem depender do superpowers instalado.
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
CHECK="scripts/check-superpowers-contract.sh"
FIX="scripts/fixtures/superpowers"
fail=0

assert_exit() {  # desc  esperado  veio
  if [ "$2" != "$3" ]; then echo "FALHOU: $1 (exit esperado $2, veio $3)"; fail=1
  else echo "ok: $1"; fi
}
assert_contains() {  # desc  agulha  palheiro
  if printf '%s' "$3" | grep -qi -- "$2"; then echo "ok: $1"
  else echo "FALHOU: $1 (não achou: $2)"; fail=1; fi
}

# 1. Fixture clean → contrato intacto (exit 0)
out="$(bash "$CHECK" --skill "$FIX/clean/SKILL.md")"; rc=$?
assert_exit "clean sai 0" 0 "$rc"
assert_contains "clean reporta intacto" "contrato intacto" "$out"

# 2. Fixture drift-c2 → drift (exit 1) citando C2
out="$(bash "$CHECK" --skill "$FIX/drift-c2/SKILL.md")"; rc=$?
assert_exit "drift-c2 sai 1" 1 "$rc"
assert_contains "drift-c2 cita C2" "C2" "$out"
# e NÃO deve citar C1/C3 (a fixture isola só o C2)
if printf '%s' "$out" | grep -qE 'C1|C3'; then
  echo "FALHOU: drift-c2 citou C1/C3 (fixture deveria isolar C2)"; fail=1
else
  echo "ok: drift-c2 isola só C2"
fi

# 3. --skill para arquivo inexistente → erro de ambiente (exit 2)
out="$(bash "$CHECK" --skill "$FIX/nao-existe/SKILL.md" 2>&1)"; rc=$?
assert_exit "--skill inexistente sai 2" 2 "$rc"

if [ "$fail" -eq 0 ]; then echo "test-check-superpowers-contract: tudo verde"; else echo "test-check-superpowers-contract: FALHOU"; exit 1; fi
