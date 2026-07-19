#!/usr/bin/env bash
# Auto-teste do check-delegacao.sh contra fixtures. Roda pela camada mecânica (scripts/eval.sh).
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
CHECK="scripts/check-delegacao.sh"
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

# 1. Bloco limpo (com a distinção + rubrica) → exit 0 / limpo.
out="$(bash "$CHECK" "$FIX/delegacao-clean.md")"; rc=$?
assert_exit "bloco limpo sai 0" 0 "$rc"
assert_contains "bloco limpo reporta limpo" "check-delegacao: limpo" "$out"

# 2. Bloco limpo via stdin (-) → exit 0 (é como as skills invocam).
out="$(bash "$CHECK" - < "$FIX/delegacao-clean.md")"; rc=$?
assert_exit "bloco limpo via stdin sai 0" 0 "$rc"

# 3. Bloco sujo (sem a distinção) → exit 1 citando cada marcador ausente.
out="$(bash "$CHECK" "$FIX/delegacao-dirty.md")"; rc=$?
assert_exit "bloco sujo sai 1" 1 "$rc"
assert_contains "acha distincao-ausente"      "distincao-ausente"      "$out"
assert_contains "acha propositiva-incompleta" "propositiva-incompleta" "$out"
assert_contains "acha previews-ausente"       "previews-ausente"       "$out"
assert_contains "acha conducao-ausente"       "conducao-ausente"       "$out"

# 4. Sem argumento → exit 2 (erro de uso).
out="$(bash "$CHECK" 2>/dev/null)"; rc=$?
assert_exit "sem argumento sai 2" 2 "$rc"

# 5. Arquivo inexistente → exit 2.
out="$(bash "$CHECK" /caminho/que/nao/existe.md 2>/dev/null)"; rc=$?
assert_exit "arquivo inexistente sai 2" 2 "$rc"

if [ "$fail" -eq 0 ]; then echo "test-check-delegacao: tudo verde"; else echo "test-check-delegacao: FALHOU"; exit 1; fi
