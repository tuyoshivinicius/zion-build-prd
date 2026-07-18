#!/usr/bin/env bash
# Auto-teste do check-experiencia.sh contra fixtures. Roda pela camada mecânica (scripts/eval.sh).
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
CHECK="scripts/check-experiencia.sh"
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

# 1. surface=não → gate fechado: exit 0 / limpo, mesmo sem NFR de experiência.
out="$(bash "$CHECK" "$FIX/prd-exp-nao.md")"; rc=$?
assert_exit "surface=não sai 0" 0 "$rc"
assert_contains "surface=não reporta limpo" "check-experiencia: limpo" "$out"

# 2. surface=sim com NFR tagueado, sem backlog → exit 0 / limpo (limb-backlog pulado).
out="$(bash "$CHECK" "$FIX/prd-exp-sim-clean.md")"; rc=$?
assert_exit "surface=sim + tag sai 0" 0 "$rc"
assert_contains "surface=sim + tag reporta limpo" "check-experiencia: limpo" "$out"

# 3. surface=sim sem NFR tagueado, sem backlog → exit 1 + limb-PRD.
out="$(bash "$CHECK" "$FIX/prd-exp-sim-dirty.md")"; rc=$?
assert_exit "limb-PRD sai 1" 1 "$rc"
assert_contains "acha limb-PRD" "limb-PRD" "$out"
assert_not_contains "sem backlog não acusa limb-backlog" "limb-backlog" "$out"

# 4. surface=sim + tag + backlog com âncora preenchida → exit 0 / limpo.
out="$(bash "$CHECK" "$FIX/prd-exp-sim-clean.md" "$FIX/backlog-exp-clean.md")"; rc=$?
assert_exit "PRD+backlog limpos saem 0" 0 "$rc"
assert_contains "PRD+backlog limpos reporta limpo" "check-experiencia: limpo" "$out"

# 5. surface=sim + tag + backlog sem âncora → exit 1 + limb-backlog (só).
out="$(bash "$CHECK" "$FIX/prd-exp-sim-clean.md" "$FIX/backlog-exp-dirty.md")"; rc=$?
assert_exit "limb-backlog sai 1" 1 "$rc"
assert_contains "acha limb-backlog" "limb-backlog" "$out"
assert_not_contains "PRD com tag não acusa limb-PRD" "limb-PRD" "$out"

# 6. surface=sim sem tag + backlog sem âncora → exit 1 + os dois limbs.
out="$(bash "$CHECK" "$FIX/prd-exp-sim-dirty.md" "$FIX/backlog-exp-dirty.md")"; rc=$?
assert_exit "dois achados sai 1" 1 "$rc"
assert_contains "acha limb-PRD (duplo)" "limb-PRD" "$out"
assert_contains "acha limb-backlog (duplo)" "limb-backlog" "$out"

# 7. sem argumento → exit 2.
out="$(bash "$CHECK" 2>/dev/null)"; rc=$?
assert_exit "sem argumento sai 2" 2 "$rc"

# 8. PRD inexistente → exit 2.
out="$(bash "$CHECK" /caminho/que/nao/existe.md 2>/dev/null)"; rc=$?
assert_exit "PRD inexistente sai 2" 2 "$rc"

# 9. backlog inexistente → exit 2.
out="$(bash "$CHECK" "$FIX/prd-exp-sim-clean.md" /nao/existe-backlog.md 2>/dev/null)"; rc=$?
assert_exit "backlog inexistente sai 2" 2 "$rc"

if [ "$fail" -eq 0 ]; then echo "test-check-experiencia: tudo verde"; else echo "test-check-experiencia: FALHOU"; exit 1; fi
