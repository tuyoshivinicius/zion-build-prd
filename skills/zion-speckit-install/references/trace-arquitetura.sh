#!/usr/bin/env bash
# trace-arquitetura.sh — reconciliador dos blocos derivados do architecture.md do PRODUTO (ADR-015).
# Regenera SÓ o conteúdo entre os marcadores zion:adr-index (§3) e zion:backlog-view (§4);
# a prosa do Autor nunca é tocada. ESCREVE (git é o desfazer); --check é read-only.
#
# Uso:
#   trace-arquitetura.sh <arquitetura> <adr-dir> <backlog-file> [--check]
#     <adr-dir> sem ADRs     → índice "_(nenhum ADR ainda)_".
#     <backlog-file> ausente → visão "_(sem backlog ainda)_".
#     --check → não grava; reporta drift/avisos e sai 1.
#
# Exit: 0 (limpo) · 1 (drift/avisos) · 2 (erro de uso/ambiente).
set -u

usage() { echo "uso: trace-arquitetura.sh <arquitetura> <adr-dir> <backlog-file> [--check]" >&2; exit 2; }

ARCH=""; ADR_DIR=""; BACKLOG=""; MODE_CHECK=0
for a in "$@"; do
  case "$a" in
    --check) MODE_CHECK=1 ;;
    -*) usage ;;
    *) if [ -z "$ARCH" ]; then ARCH="$a"
       elif [ -z "$ADR_DIR" ]; then ADR_DIR="$a"
       elif [ -z "$BACKLOG" ]; then BACKLOG="$a"
       else usage; fi ;;
  esac
done
[ -n "$ARCH" ] && [ -n "$ADR_DIR" ] && [ -n "$BACKLOG" ] || usage
[ -f "$ARCH" ] || { echo "trace-arquitetura: arquivo não encontrado: $ARCH" >&2; exit 2; }

# --- Índice de ADRs: uma linha por <adr-dir>/ADR-*.md, título do primeiro "# ". ---
build_adr_index() {
  local f title found=0
  for f in "$ADR_DIR"/ADR-*.md; do
    [ -f "$f" ] || continue
    found=1
    title="$(sed -n '/^# /{s/^# //;p;q;}' "$f")"
    [ -n "$title" ] || title="$(basename "$f" .md)"
    printf -- '- [%s](%s/%s)\n' "$title" "$(basename "$ADR_DIR")" "$(basename "$f")"
  done
  [ "$found" -eq 1 ] || printf -- '_(nenhum ADR ainda)_\n'
}

# --- Visão do backlog: slug + status da PRIMEIRA tabela do backlog (a canônica). ---
build_backlog_view() {
  if [ ! -f "$BACKLOG" ]; then printf -- '_(sem backlog ainda)_\n'; return; fi
  awk '
    function trim(s){ gsub(/^[[:space:]]+|[[:space:]]+$/,"",s); return s }
    function lc(s){ return tolower(s) }
    done { next }
    /^[[:space:]]*\|/ {
      line=$0; sub(/^[[:space:]]*\|/,"",line); sub(/\|[[:space:]]*$/,"",line)
      nc=split(line, c, /\|/)
      for(i=1;i<=nc;i++) c[i]=trim(c[i])
      if (!intab) {
        for(i=1;i<=nc;i++){ h=lc(c[i]); if (index(h,"slug")) scol=i; else if (index(h,"status")) stcol=i }
        ok=(scol && stcol); intab=1; next
      }
      if (c[1] ~ /^[-:]+$/) next
      if (ok && c[scol] != "") { printf "- `%s` — %s\n", c[scol], c[stcol]; n++ }
      next
    }
    intab { done=1 }
    END { if (!n) print "_(sem specs no backlog ainda)_" }
  ' "$BACKLOG"
}

# --- Substitui o conteúdo entre os marcadores de UM bloco; o resto passa intacto. ---
replace_block() {  # $1 arquivo  $2 nome-do-bloco  $3 arquivo-com-conteudo → stdout
  awk -v start="<!-- zion:$2:start -->" -v end="<!-- zion:$2:end -->" -v cf="$3" '
    $0==start { print; while ((getline l < cf) > 0) print l; skip=1; next }
    $0==end   { skip=0 }
    skip { next }
    { print }
  ' "$1"
}

# --- Orquestração ---
warnings=""
add_warning() { if [ -z "$warnings" ]; then warnings="$1"; else warnings="$warnings
$1"; fi; }

TMPA="$(mktemp)"; TMPB="$(mktemp)"; NEW="$(mktemp)"; CUR="$(mktemp)"
cleanup() { rm -f "$TMPA" "$TMPB" "$NEW" "$CUR" 2>/dev/null; }
trap cleanup EXIT

build_adr_index    > "$TMPA"
build_backlog_view > "$TMPB"

cp "$ARCH" "$CUR"
for pair in "adr-index:$TMPA" "backlog-view:$TMPB"; do
  name="${pair%%:*}"; cf="${pair#*:}"
  if grep -qF "<!-- zion:$name:start -->" "$CUR" && grep -qF "<!-- zion:$name:end -->" "$CUR"; then
    replace_block "$CUR" "$name" "$cf" > "$NEW"
    cp "$NEW" "$CUR"
  else
    add_warning "Marcador ausente: bloco zion:$name sem <!-- zion:$name:start/end --> em $ARCH (bloco não reconciliado; restaure os marcadores do esqueleto)"
  fi
done

wcount=0; [ -n "$warnings" ] && wcount="$(printf '%s\n' "$warnings" | grep -c .)"

if [ "$MODE_CHECK" = "1" ]; then
  drift=""
  if ! diff -q "$ARCH" "$CUR" >/dev/null 2>&1; then
    echo "trace-arquitetura: drift nos blocos derivados (rode sem --check para reconciliar):"
    diff "$ARCH" "$CUR" || true
    drift=1
  fi
  [ -n "$warnings" ] && printf '%s\n' "$warnings"
  if [ -n "$drift" ] || [ "$wcount" -gt 0 ]; then echo "trace-arquitetura: fora de dia"; exit 1; fi
  echo "trace-arquitetura: em dia"; exit 0
fi

changed=0
if ! diff -q "$ARCH" "$CUR" >/dev/null 2>&1; then
  cp "$CUR" "$ARCH"; changed=1
fi
[ -n "$warnings" ] && printf '%s\n' "$warnings"
if [ "$changed" -eq 0 ] && [ "$wcount" -eq 0 ]; then
  echo "trace-arquitetura: em dia"; exit 0
fi
[ "$changed" -eq 1 ] && echo "trace-arquitetura: blocos derivados reconciliados"
if [ "$wcount" -gt 0 ]; then echo "trace-arquitetura: $wcount aviso(s)"; exit 1; fi
exit 0
