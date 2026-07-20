#!/usr/bin/env bash
# Auto-teste do trace-arquitetura.sh contra fixtures (NFR-04). Roda pela camada mecânica (scripts/eval.sh).
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
TRACE="scripts/trace-arquitetura.sh"
FIX="scripts/fixtures/arquitetura/trace"
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
assert_file_not_re() {  # desc  arquivo  regex_estendida
  if grep -Eq -- "$3" "$2"; then echo "FALHOU: $1 (regex casou indevido: $3)"; fail=1
  else echo "ok: $1"; fi
}
fresh() {  # copia a fixture $1 para um temp e ecoa o caminho
  local t; t="$(mktemp)"; cp "$1" "$t"; printf '%s' "$t"
}

# 1. Reconciliação: mapa agrupado por área, prosa intacta.
arch="$(fresh "$FIX/architecture.md")"
out="$(bash "$TRACE" "$arch" "$FIX/adr" "$FIX/backlog.md" "$FIX/specs")"; rc=$?
assert_exit "reconciliação sai 0" 0 "$rc"
assert_file_re "mapa abre o grupo da área do ADR-001" "$arch" '^### Persistência$'
assert_file_re "mapa abre o grupo da área do ADR-002" "$arch" '^### Fluxo$'
assert_file_re "mapa tem o grupo Sem área" "$arch" '^### Sem área$'
assert_file_re "mapa linka o ADR-001 em negrito" "$arch" '^- \*\*\[ADR-001 — Banco único\]\(adr/ADR-001-banco-unico\.md\)\*\*$'
assert_file_re "mapa traz o que o ADR-001 fixou" "$arch" '^  fixou: Um banco único\.'
assert_file_re "mapa traz as specs do ADR-001" "$arch" 'specs: `001-walking-skeleton`, `002-historico`'
assert_file_re "mapa traz as specs do ADR-002" "$arch" 'specs: `002-historico`'
assert_file_not_re "ADR substituído sai do mapa" "$arch" 'ADR-004-motor-antigo\.md'
assert_file_re "rodapé conta as substituídas" "$arch" '1 decisão\(ões\) substituída\(s\)'
assert_file_re "visão ganha walking-skeleton com status" "$arch" 'walking-skeleton.*implementada'
assert_file_re "visão ganha historico pendente" "$arch" 'historico.*pendente'
assert_file_re "prosa do Autor preservada" "$arch" 'Prosa que o reconciliador nunca toca'
assert_file_not_re "conteúdo velho dos blocos substituído" "$arch" 'conteúdo velho'
assert_file_re "avisa supersessão na âncora" "$arch" 'narrativa-superseded: ADR-004'
assert_file_re "avisa defasagem da âncora" "$arch" 'narrativa-defasada: ADR-002, ADR-003'
assert_file_re "aviso aponta a cura" "$arch" '/zion-prd-decompose --narrativa'
assert_file_re "prosa da narrativa intocada" "$arch" 'dono único do dado gravado'
assert_file_re "âncora intocada" "$arch" '<!-- zion:narrativa:start adrs=ADR-001,ADR-004 -->'

# 2. Idempotência: rodar de novo não muda o arquivo.
cp "$arch" "$arch.bak"
bash "$TRACE" "$arch" "$FIX/adr" "$FIX/backlog.md" "$FIX/specs" >/dev/null 2>&1
if diff -q "$arch" "$arch.bak" >/dev/null 2>&1; then echo "ok: reconciliação idempotente"
else echo "FALHOU: reconciliação não é idempotente"; fail=1; fi

# 3. --check em dia após reconciliar.
out="$(bash "$TRACE" "$arch" "$FIX/adr" "$FIX/backlog.md" "$FIX/specs" --check)"; rc=$?
assert_exit "--check em dia sai 0" 0 "$rc"
assert_contains "--check diz em dia" "em dia" "$out"
rm -f "$arch" "$arch.bak"

# 4. --check com drift é read-only e sai 1.
arch="$(fresh "$FIX/architecture.md")"; cp "$arch" "$arch.bak"
out="$(bash "$TRACE" "$arch" "$FIX/adr" "$FIX/backlog.md" "$FIX/specs" --check)"; rc=$?
assert_exit "--check com drift sai 1" 1 "$rc"
if diff -q "$arch" "$arch.bak" >/dev/null 2>&1; then echo "ok: --check não escreve"
else echo "FALHOU: --check escreveu no arquivo"; fail=1; fi
rm -f "$arch" "$arch.bak"

# 5. Backlog ausente → semeia "(sem backlog ainda)" e sai 0.
arch="$(fresh "$FIX/architecture.md")"
out="$(bash "$TRACE" "$arch" "$FIX/adr" "$FIX/nao-existe.md")"; rc=$?
assert_exit "backlog ausente sai 0" 0 "$rc"
assert_file_re "backlog ausente semeia o bloco" "$arch" 'sem backlog ainda'
rm -f "$arch"

# 6. Sem ADRs → índice "(nenhum ADR ainda)".
arch="$(fresh "$FIX/architecture.md")"
bash "$TRACE" "$arch" "$FIX/nao-existe" "$FIX/backlog.md" >/dev/null 2>&1
assert_file_re "sem ADRs semeia nenhum ADR ainda" "$arch" 'nenhum ADR ainda'
rm -f "$arch"

# 7. Marcadores ausentes → aviso, exit 1, arquivo intacto.
arch="$(fresh "$FIX/sem-marcadores.md")"; cp "$arch" "$arch.bak"
out="$(bash "$TRACE" "$arch" "$FIX/adr" "$FIX/backlog.md")"; rc=$?
assert_exit "sem marcadores sai 1" 1 "$rc"
assert_contains "avisa marcador ausente" "Marcador ausente" "$out"
if diff -q "$arch" "$arch.bak" >/dev/null 2>&1; then echo "ok: sem marcadores não toca o arquivo"
else echo "FALHOU: escreveu num arquivo sem marcadores"; fail=1; fi
rm -f "$arch" "$arch.bak"

# 8. Arquitetura inexistente → exit 2.
out="$(bash "$TRACE" nao/existe.md "$FIX/adr" "$FIX/backlog.md" 2>&1)"; rc=$?
assert_exit "arquitetura inexistente sai 2" 2 "$rc"

# 9. Sem argumentos → exit 2.
out="$(bash "$TRACE" 2>/dev/null)"; rc=$?
assert_exit "sem argumentos sai 2" 2 "$rc"

# 10. Ordem estável das áreas: Persistência (ADR-001) antes de Fluxo (ADR-002); "Sem área" por último.
arch="$(fresh "$FIX/architecture.md")"
bash "$TRACE" "$arch" "$FIX/adr" "$FIX/backlog.md" "$FIX/specs" >/dev/null 2>&1
ordem="$(grep -n '^### ' "$arch" | sed 's/:.*### /:/' | tr '\n' ' ')"
case "$ordem" in
  *Persistência*Fluxo*Sem\ área*) echo "ok: ordem das áreas estável" ;;
  *) echo "FALHOU: ordem das áreas inesperada ($ordem)"; fail=1 ;;
esac
rm -f "$arch"

# 11. Sem specs-dir → mapa sai sem a parte de specs, e nada quebra.
arch="$(fresh "$FIX/architecture.md")"
out="$(bash "$TRACE" "$arch" "$FIX/adr" "$FIX/backlog.md")"; rc=$?
assert_exit "sem specs-dir sai 0" 0 "$rc"
assert_file_re "sem specs-dir ainda traz o fixou" "$arch" '^  fixou: Um banco único\.'
assert_file_not_re "sem specs-dir não inventa specs" "$arch" 'specs: `'
rm -f "$arch"

# 12. Narrativa em dia: âncora com todos os ADRs vigentes aceitos → "_(narrativa em dia)_".
arch="$(fresh "$FIX/architecture.md")"
sed -i 's/adrs=ADR-001,ADR-004/adrs=ADR-001,ADR-002,ADR-003/' "$arch"
bash "$TRACE" "$arch" "$FIX/adr" "$FIX/backlog.md" "$FIX/specs" >/dev/null 2>&1
assert_file_re "âncora completa vira narrativa em dia" "$arch" '_\(narrativa em dia\)_'
rm -f "$arch"

# 13. Sem prosa na narrativa → "_(sem narrativa ainda)_", sem acusar defasagem.
arch="$(fresh "$FIX/architecture.md")"
awk '/<!-- zion:narrativa:start/ { print "<!-- zion:narrativa:start -->"; skip=1; next }
     /<!-- zion:narrativa:end -->/ { skip=0 }
     !skip { print }' "$FIX/architecture.md" > "$arch"
bash "$TRACE" "$arch" "$FIX/adr" "$FIX/backlog.md" "$FIX/specs" >/dev/null 2>&1
assert_file_re "sem prosa vira sem narrativa ainda" "$arch" '_\(sem narrativa ainda\)_'
assert_file_not_re "sem prosa não acusa defasagem" "$arch" 'narrativa-defasada'
rm -f "$arch"

# 14. Documento sem o bloco de avisos → aviso com a cura certa, arquivo intacto nesse bloco.
arch="$(fresh "$FIX/sem-marcadores.md")"
out="$(bash "$TRACE" "$arch" "$FIX/adr" "$FIX/backlog.md" "$FIX/specs")"; rc=$?
assert_exit "sem bloco de avisos sai 1" 1 "$rc"
assert_contains "avisa a ausência do bloco de avisos" "zion:narrativa-avisos" "$out"
rm -f "$arch"

if [ "$fail" -eq 0 ]; then echo "test-trace-arquitetura: tudo verde"; else echo "test-trace-arquitetura: FALHOU"; exit 1; fi
