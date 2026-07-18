#!/usr/bin/env bash
# Auto-teste do trace-backlog.sh contra fixtures. Camada mecânica (R7).
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
TRACE="scripts/trace-backlog.sh"
FIX="scripts/fixtures/backlog"
fail=0

assert_exit() {  # desc  esperado  veio
  if [ "$2" != "$3" ]; then echo "FALHOU: $1 (exit esperado $2, veio $3)"; fail=1
  else echo "ok: $1"; fi
}
assert_contains() {  # desc  agulha  palheiro
  if printf '%s' "$3" | grep -qi -- "$2"; then echo "ok: $1"
  else echo "FALHOU: $1 (não achou: $2)"; fail=1; fi
}
assert_file_re() {  # desc  arquivo  regex-estendida
  if grep -Eq -- "$3" "$2"; then echo "ok: $1"
  else echo "FALHOU: $1 (regex não casou: $3)"; fail=1; fi
}
fresh() {  # copia a fixture $1 para um temp e ecoa o caminho
  local t; t="$(mktemp)"; cp "$1" "$t"; printf '%s' "$t"
}

# --- bootstrap: sem specs → Spec —, tudo ☐, exit 0 ---
bl="$(fresh "$FIX/bootstrap.md")"
out="$(bash "$TRACE" "$bl" "$FIX/nao-existe")"; rc=$?
assert_exit "bootstrap sai 0" 0 "$rc"
assert_file_re "bootstrap: spec vira ☐ pendente"  "$bl" 'walking-skeleton .*\| — \| ☐ pendente'
rm -f "$bl"

# erro de uso: backlog inexistente → exit 2
out="$(bash "$TRACE" nao/existe.md "$FIX/specs" 2>&1)"; rc=$?
assert_exit "backlog inexistente sai 2" 2 "$rc"

# backlog sem tabela canônica → exit 2 com mensagem acionável
out="$(bash "$TRACE" "$FIX/no-table.md" "$FIX/specs" 2>&1)"; rc=$?
assert_exit "sem tabela canônica sai 2" 2 "$rc"
assert_contains "sem tabela: mensagem aponta o template" "assets/templates/backlog.md" "$out"

# --- casamento por sufixo + status + substring NÃO casa ---
bl="$(fresh "$FIX/backlog.md")"
bash "$TRACE" "$bl" "$FIX/specs" >/dev/null 2>&1
assert_file_re "casa por sufixo → ● implementada" "$bl" 'preview-ao-vivo .*specs/003-preview-ao-vivo.*● implementada'
assert_file_re "tasks aberto → ◐ em especificação" "$bl" 'erros-sintaxe .*specs/004-erros-sintaxe.*◐ em especificação'
assert_file_re "sem spec → ☐ pendente"             "$bl" 'exportar-svg .*\| — \| ☐ pendente'
assert_file_re "substring não casa (vivo)"         "$bl" 'vivo .*\| — \| ☐ pendente'
# idempotência
cp "$bl" "$bl.bak"; bash "$TRACE" "$bl" "$FIX/specs" >/dev/null 2>&1
if diff -q "$bl" "$bl.bak" >/dev/null 2>&1; then echo "ok: reconciliação idempotente"
else echo "FALHOU: reconciliação não é idempotente"; fail=1; fi
rm -f "$bl" "$bl.bak"

# --- avisos + exit 1 + quadro ---
bl="$(fresh "$FIX/backlog.md")"
out="$(bash "$TRACE" "$bl" "$FIX/specs")"; rc=$?
assert_exit "modo padrão com avisos sai 1" 1 "$rc"
assert_contains "aviso divergência de escopo" "Divergência de escopo" "$out"
assert_contains "aviso slug duplicado"        "Slug duplicado" "$out"
assert_contains "aviso spec órfã"             "Spec órfã" "$out"
assert_contains "aviso spec sem pasta"        "Spec sem pasta" "$out"
assert_contains "quadro de specs"             "Quadro de specs" "$out"
rm -f "$bl"

# --- preservação: colunas humanas, ordem das linhas, texto fora da tabela ---
bl="$(fresh "$FIX/backlog.md")"
bash "$TRACE" "$bl" "$FIX/specs" >/dev/null 2>&1
assert_file_re "demo humana preservada"          "$bl" 'Digitar mermaid, ver prévia'
assert_file_re "ordem preservada (1ª linha)"     "$bl" '^\| preview-ao-vivo '
assert_file_re "texto fora da tabela preservado" "$bl" 'tabela secundária que deve sobreviver'
rm -f "$bl"

# --- colisão de casamento: 001 (menor prefixo) vence ---
bl="$(fresh "$FIX/collision/backlog.md")"
out="$(bash "$TRACE" "$bl" "$FIX/collision/specs")"; rc=$?
assert_contains "aviso colisão de casamento" "Colisão de casamento" "$out"
assert_file_re "colisão: menor prefixo (001) vence" "$bl" 'preview-ao-vivo .*specs/001-preview-ao-vivo'
rm -f "$bl"

# --- --check: drift sai 1 e NÃO escreve ---
bl="$(fresh "$FIX/backlog.md")"; cp "$bl" "$bl.bak"
out="$(bash "$TRACE" "$bl" "$FIX/specs" --check)"; rc=$?
assert_exit "--check com drift sai 1" 1 "$rc"
if diff -q "$bl" "$bl.bak" >/dev/null 2>&1; then echo "ok: --check não escreve"
else echo "FALHOU: --check escreveu no arquivo"; fail=1; fi
rm -f "$bl" "$bl.bak"

# --- clean: reconcilia sem avisos (exit 0) e --check diz "em dia" (exit 0) ---
bl="$(fresh "$FIX/clean/backlog.md")"
out="$(bash "$TRACE" "$bl" "$FIX/clean/specs")"; rc=$?
assert_exit "clean reconcilia sem avisos sai 0" 0 "$rc"
out="$(bash "$TRACE" "$bl" "$FIX/clean/specs" --check)"; rc=$?
assert_exit "clean --check em dia sai 0" 0 "$rc"
assert_contains "clean --check diz em dia" "em dia" "$out"
rm -f "$bl"

if [ "$fail" -eq 0 ]; then echo "test-trace-backlog: tudo verde"; else echo "test-trace-backlog: FALHOU"; exit 1; fi
