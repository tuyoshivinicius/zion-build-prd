#!/usr/bin/env bash
# Auto-teste do trace-prd.sh contra fixtures. Semente da suíte de avaliação (R7).
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
TRACE="scripts/trace-prd.sh"
FIX="scripts/fixtures/trace"
fail=0

assert_exit() {  # desc  exit_esperado  exit_veio
  if [ "$2" != "$3" ]; then echo "FALHOU: $1 (exit esperado $2, veio $3)"; fail=1
  else echo "ok: $1"; fi
}
assert_contains() {  # desc  agulha  palheiro
  if printf '%s' "$3" | grep -qi -- "$2"; then echo "ok: $1"
  else echo "FALHOU: $1 (não achou: $2)"; fail=1; fi
}
assert_file_re() {  # desc  arquivo  regex_estendida
  if grep -Eq -- "$3" "$2"; then echo "ok: $1"
  else echo "FALHOU: $1 (regex não casou: $3)"; fail=1; fi
}
fresh_prd() {  # copia a fixture $1 para um temp e ecoa o caminho
  local t; t="$(mktemp)"; cp "$1" "$t"; printf '%s' "$t"
}

# --- Task 2: bootstrap (sem specs) ---
prd="$(fresh_prd "$FIX/PRD.md")"
out="$(bash "$TRACE" "$prd" "$FIX/nao-existe")"; rc=$?
assert_exit "bootstrap sai 0" 0 "$rc"
assert_file_re "bootstrap: RF-01 vira linha pendente" "$prd" 'RF-01.*☐ pendente'
assert_file_re "bootstrap: descrição regenerada da §6" "$prd" 'o usuário faz a ação principal'
assert_file_re "bootstrap: Release R0 preservado" "$prd" 'RF-01.*R0.*pendente'
assert_file_re "bootstrap: §13 preservada" "$prd" '## 13\. Apêndice'
rm -f "$prd"

# erro de uso: PRD inexistente → exit 2
out="$(bash "$TRACE" nao/existe.md specs 2>&1)"; rc=$?
assert_exit "PRD inexistente sai 2" 2 "$rc"

# --- Task 3: specs varridas (status + Feature/Spec + idempotência) ---
prd="$(fresh_prd "$FIX/PRD.md")"
bash "$TRACE" "$prd" "$FIX/specs" >/dev/null 2>&1
assert_file_re "RF-01 implementada c/ spec" "$prd" 'RF-01.*specs/001-acao.*● implementada'
assert_file_re "RF-02 em spec c/ spec"      "$prd" 'RF-02.*specs/002-historico.*◐ em spec'
assert_file_re "RF-03 permanece pendente"   "$prd" 'RF-03.*☐ pendente'
# idempotência: rodar de novo não muda o arquivo
cp "$prd" "$prd.bak"
bash "$TRACE" "$prd" "$FIX/specs" >/dev/null 2>&1
if diff -q "$prd" "$prd.bak" >/dev/null 2>&1; then echo "ok: reconciliação idempotente"
else echo "FALHOU: reconciliação não é idempotente"; fail=1; fi
rm -f "$prd" "$prd.bak"

# --- Task 4: avisos + exit codes + --check ---
prd="$(fresh_prd "$FIX/PRD.md")"
out="$(bash "$TRACE" "$prd" "$FIX/specs")"; rc=$?
assert_exit "modo padrão com avisos sai 1" 1 "$rc"
assert_contains "aviso RF órfão (RF-99)"       "RF órfão" "$out"
assert_contains "aviso spec intraçável (004)"  "intraçável" "$out"
assert_contains "aviso RF descoberto (RF-03)"  "RF descoberto" "$out"
rm -f "$prd"

# --check é read-only e sinaliza drift
prd="$(fresh_prd "$FIX/PRD.md")"; cp "$prd" "$prd.bak"
out="$(bash "$TRACE" "$prd" "$FIX/specs" --check)"; rc=$?
assert_exit "--check com drift sai 1" 1 "$rc"
if diff -q "$prd" "$prd.bak" >/dev/null 2>&1; then echo "ok: --check não escreve"
else echo "FALHOU: --check escreveu no arquivo"; fail=1; fi
rm -f "$prd" "$prd.bak"

# fixture clean: reconcilia (exit 0, sem avisos) e depois --check diz "em dia" (exit 0)
prd="$(fresh_prd "$FIX/clean/PRD.md")"
out="$(bash "$TRACE" "$prd" "$FIX/clean/specs")"; rc=$?
assert_exit "clean reconcilia sem avisos sai 0" 0 "$rc"
assert_file_re "clean: RF-01 implementada" "$prd" 'RF-01.*specs/001-unica.*● implementada'
out="$(bash "$TRACE" "$prd" "$FIX/clean/specs" --check)"; rc=$?
assert_exit "clean --check em dia sai 0" 0 "$rc"
assert_contains "clean --check diz em dia" "em dia" "$out"
rm -f "$prd"

if [ "$fail" -eq 0 ]; then echo "test-trace-prd: tudo verde"; else echo "test-trace-prd: FALHOU"; exit 1; fi
