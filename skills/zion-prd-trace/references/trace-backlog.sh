#!/usr/bin/env bash
# trace-backlog.sh — reconciliador do backlog de fatias (docs/backlog.md).
# Espelho do trace-prd.sh no grão da FATIA. Preserva as colunas humanas
# (Fatia/Demo/RFs/Release) e a ordem das linhas; recomputa as colunas de
# máquina (Spec, Status) casando specs/###-<slug> ⇔ slug por sufixo.
# ESCREVE (git é o desfazer); --check é read-only.
#
# Uso:
#   trace-backlog.sh <backlog-file> <specs-dir> [--check]
#     <specs-dir> ausente/vazio → bootstrap (Spec —, tudo ☐).
#     --check → não grava; reporta drift/avisos e sai 1.
#
# Exit: 0 (limpo) · 1 (drift/avisos) · 2 (erro de uso/ambiente).
set -u

usage() { echo "uso: trace-backlog.sh <backlog-file> <specs-dir> [--check]" >&2; exit 2; }

BACKLOG=""; SPECS_DIR=""; MODE_CHECK=0
for a in "$@"; do
  case "$a" in
    --check) MODE_CHECK=1 ;;
    -*) usage ;;
    *) if [ -z "$BACKLOG" ]; then BACKLOG="$a"
       elif [ -z "$SPECS_DIR" ]; then SPECS_DIR="$a"
       else usage; fi ;;
  esac
done
[ -n "$BACKLOG" ] || usage
[ -f "$BACKLOG" ] || { echo "trace-backlog: arquivo não encontrado: $BACKLOG" >&2; exit 2; }

TAB="$(printf '\t')"
ROWS=""; NEWCOLS=""; SPECDIRS=""
cleanup() { rm -f "$ROWS" "$NEWCOLS" "$SPECDIRS" 2>/dev/null; }
trap cleanup EXIT

# --- Lê a PRIMEIRA tabela do arquivo (a canônica). Emite uma linha por fatia:
#     slug \t demo \t rfs \t release \t spec-antiga \t status-antigo.
#     Só emite se o cabeçalho tiver as 6 colunas esperadas. ---
parse_table() {
  awk '
    function trim(s){ gsub(/^[[:space:]]+|[[:space:]]+$/,"",s); return s }
    function lc(s){ return tolower(s) }
    done { next }
    /^[[:space:]]*\|/ {
      line=$0; sub(/^[[:space:]]*\|/,"",line); sub(/\|[[:space:]]*$/,"",line)
      nc=split(line, c, /\|/)
      for(i=1;i<=nc;i++) c[i]=trim(c[i])
      if (!intab) {
        for(i=1;i<=nc;i++){
          h=lc(c[i])
          if      (index(h,"fatia"))   scol=i
          else if (index(h,"demo"))    dcol=i
          else if (index(h,"rfs"))     rcol=i
          else if (index(h,"release")) relcol=i
          else if (index(h,"spec"))    spcol=i
          else if (index(h,"status"))  stcol=i
        }
        ok = (scol && dcol && rcol && relcol && spcol && stcol)
        intab=1; next
      }
      if (c[1] ~ /^[-:]+$/) next
      if (ok) printf "%s\t%s\t%s\t%s\t%s\t%s\n", c[scol], c[dcol], c[rcol], c[relcol], c[spcol], c[stcol]
      next
    }
    intab { done=1 }
  ' "$1"
}

# --- Lista os diretórios (basename) sob <specs-dir>. Bootstrap → vazio. ---
scan_specs_dirs() {
  : > "$SPECDIRS"
  [ -n "$SPECS_DIR" ] && [ -d "$SPECS_DIR" ] || return 0
  local d
  for d in "$SPECS_DIR"/*/; do
    [ -d "$d" ] || continue
    basename "$d" >> "$SPECDIRS"
  done
}

# --- Diretório casado para um slug: D==slug (prefixo -1) ou D=~^[0-9]+-slug$.
#     Menor prefixo numérico vence. Define MATCH_DIR e MATCH_COUNT (sem subshell). ---
match_dir_for_slug() {  # $1 slug
  local slug="$1" d num bestnum=""
  MATCH_DIR=""; MATCH_COUNT=0
  while read -r d; do
    [ -n "$d" ] || continue
    if [ "$d" = "$slug" ]; then
      num=-1
    elif printf '%s' "$d" | grep -qE "^[0-9]+-$slug$"; then
      num="${d%%-*}"; num=$((10#$num))
    else
      continue
    fi
    MATCH_COUNT=$((MATCH_COUNT+1))
    if [ -z "$MATCH_DIR" ] || [ "$num" -lt "$bestnum" ]; then MATCH_DIR="$d"; bestnum="$num"; fi
  done < "$SPECDIRS"
}

# --- Status de UMA spec pelo tasks.md: ausente/com "- [ ]" aberto → spec; senão impl. ---
spec_status() {  # $1 spec-dir
  local tasks="$1/tasks.md"
  [ -f "$tasks" ] || { printf 'spec'; return; }
  if grep -qE '^[[:space:]]*- \[ \]' "$tasks"; then printf 'spec'; return; fi
  printf 'impl'
}

# --- Reescreve a PRIMEIRA tabela in-place: troca só as células Spec/Status
#     das linhas cujo slug está em $NEWCOLS; preserva o resto do arquivo. ---
rewrite_table() {  # imprime o backlog reconciliado no stdout
  awk -v cols="$NEWCOLS" '
    function trim(s){ gsub(/^[[:space:]]+|[[:space:]]+$/,"",s); return s }
    function lc(s){ return tolower(s) }
    BEGIN {
      while ((getline l < cols) > 0) {
        n=split(l, a, "\t"); newspec[a[1]]=a[2]; newstat[a[1]]=a[3]
      }
    }
    tabdone { print; next }
    /^[[:space:]]*\|/ {
      raw=$0
      line=$0; sub(/^[[:space:]]*\|/,"",line); sub(/\|[[:space:]]*$/,"",line)
      nc=split(line, c, /\|/)
      for(i=1;i<=nc;i++) c[i]=trim(c[i])
      if (!intab) {
        for(i=1;i<=nc;i++){
          h=lc(c[i])
          if      (index(h,"fatia"))  scol=i
          else if (index(h,"spec"))   spcol=i
          else if (index(h,"status")) stcol=i
        }
        intab=1; print raw; next
      }
      if (c[1] ~ /^[-:]+$/) { print raw; next }
      slug=c[scol]
      if (slug in newspec) { c[spcol]=newspec[slug]; c[stcol]=newstat[slug] }
      out="|"
      for(i=1;i<=nc;i++) out=out " " c[i] " |"
      print out
      next
    }
    { if (intab) tabdone=1; print }
  ' "$BACKLOG"
}

# --- Orquestração ---
ROWS="$(mktemp)"; NEWCOLS="$(mktemp)"; SPECDIRS="$(mktemp)"
parse_table "$BACKLOG" > "$ROWS"
[ -s "$ROWS" ] || { echo "trace-backlog: $BACKLOG sem tabela canônica de fatias (veja assets/templates/backlog.md)" >&2; exit 2; }

scan_specs_dirs
SPEC_COUNT=$(grep -c . "$SPECDIRS")
: > "$NEWCOLS"

declare -A SEEN USEDDIR
warnings=""; transitions=""
impl=0; inspec=0; pend=0; firstpending=""

while IFS="$TAB" read -r slug demo rfs release oldspec oldstatus; do
  [ -n "$slug" ] || continue
  if [ -n "${SEEN[$slug]:-}" ]; then
    warnings="${warnings}Slug duplicado: \`$slug\` aparece mais de uma vez no backlog (a primeira linha vence; as demais são ignoradas).
"
    continue
  fi
  SEEN[$slug]=1

  match_dir_for_slug "$slug"; dir="$MATCH_DIR"; matched="$MATCH_COUNT"
  if [ -n "$dir" ]; then
    USEDDIR[$dir]=1
    [ "$matched" -gt 1 ] && warnings="${warnings}Colisão de casamento: mais de um diretório casa \`$slug\`; \`specs/$dir\` (menor prefixo) vence.
"
    st="$(spec_status "$SPECS_DIR/$dir")"
    case "$st" in impl) glyph="● implementada" ;; *) glyph="◐ em spec" ;; esac
    speccell="\`specs/$dir\`"
    decl="$(printf '%s' "$rfs" | grep -oE 'RF-[0-9]+' | sort -u | tr '\n' ' ')"
    covline="$(grep -iE 'RF cobertos:' "$SPECS_DIR/$dir/spec.md" 2>/dev/null | head -1)"
    cov="$(printf '%s' "$covline" | grep -oE 'RF-[0-9]+' | sort -u | tr '\n' ' ')"
    if [ -n "$covline" ] && [ "$decl" != "$cov" ]; then
      warnings="${warnings}Divergência de escopo: \`$slug\` declara [${decl% }] mas specs/$dir cobre [${cov% }] — corrija a spec ou o backlog.
"
    fi
  else
    glyph="☐ pendente"; speccell="—"
    [ "$SPEC_COUNT" -gt 0 ] && warnings="${warnings}Fatia sem spec: \`$slug\` ainda não tem spec (permanece ☐ pendente).
"
  fi

  printf '%s\t%s\t%s\n' "$slug" "$speccell" "$glyph" >> "$NEWCOLS"

  if [ "$(printf '%s' "$oldstatus" | tr -d ' ')" != "$(printf '%s' "$glyph" | tr -d ' ')" ]; then
    transitions="${transitions}  $slug: ${oldstatus:-—} → $glyph
"
  fi

  case "$glyph" in
    "● implementada") impl=$((impl+1)) ;;
    "◐ em spec")      inspec=$((inspec+1)) ;;
    *)                pend=$((pend+1)); [ -z "$firstpending" ] && firstpending="$slug" ;;
  esac
done < "$ROWS"

# spec órfã: diretório que não casou com nenhum slug
if [ "$SPEC_COUNT" -gt 0 ]; then
  while read -r d; do
    [ -n "$d" ] || continue
    [ -n "${USEDDIR[$d]:-}" ] || warnings="${warnings}Spec órfã: \`specs/$d\` não casa com nenhum slug do backlog (registre a fatia ou renomeie).
"
  done < "$SPECDIRS"
fi

wcount=0; [ -n "$warnings" ] && wcount="$(printf '%s' "$warnings" | grep -c .)"

quadro() {
  printf 'Quadro de fatias: ● %s · ◐ %s · ☐ %s' "$impl" "$inspec" "$pend"
  if [ -n "$firstpending" ]; then printf ' · próxima ☐: %s\n' "$firstpending"; else printf '\n'; fi
}

if [ "$MODE_CHECK" = "1" ]; then
  tmp="$(mktemp)"; rewrite_table > "$tmp"; drift=""
  if ! diff -q "$BACKLOG" "$tmp" >/dev/null 2>&1; then
    echo "trace-backlog: drift no backlog (rode sem --check para reconciliar):"
    diff "$BACKLOG" "$tmp" || true
    drift=1
  fi
  rm -f "$tmp"
  [ -n "$warnings" ] && printf '%s' "$warnings"
  quadro
  if [ -n "$drift" ] || [ "$wcount" -gt 0 ]; then echo "trace-backlog: fora de dia"; exit 1; fi
  echo "trace-backlog: em dia"; exit 0
fi

tmp="$(mktemp)"; rewrite_table > "$tmp"; mv "$tmp" "$BACKLOG"

[ -n "$transitions" ] && printf '%s' "$transitions"
[ -n "$warnings" ] && printf '%s' "$warnings"
quadro

updated=0; [ -n "$transitions" ] && updated="$(printf '%s' "$transitions" | grep -c .)"
if [ "$updated" -eq 0 ] && [ "$wcount" -eq 0 ]; then
  echo "trace-backlog: em dia"; exit 0
fi
echo "trace-backlog: $updated linha(s) atualizada(s), $wcount aviso(s)"
[ "$wcount" -gt 0 ] && exit 1 || exit 0
