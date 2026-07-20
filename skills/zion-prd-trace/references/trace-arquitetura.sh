#!/usr/bin/env bash
# trace-arquitetura.sh — reconciliador dos blocos derivados do architecture.md do PRODUTO (ADR-015).
# Regenera SÓ o conteúdo entre os marcadores zion:adr-index (§3) e zion:backlog-view (§4);
# a prosa do Autor nunca é tocada. ESCREVE (git é o desfazer); --check é read-only.
#
# Uso:
#   trace-arquitetura.sh <arquitetura> <adr-dir> <backlog-file> [<specs-dir>] [--check]
#     <adr-dir> sem ADRs     → índice "_(nenhum ADR ainda)_".
#     <backlog-file> ausente → visão "_(sem backlog ainda)_".
#     <specs-dir> ausente    → o mapa sai sem a coluna de specs (derivação best-effort).
#     --check → não grava; reporta drift/avisos e sai 1.
#
# Exit: 0 (limpo) · 1 (drift/avisos) · 2 (erro de uso/ambiente).
set -u

usage() { echo "uso: trace-arquitetura.sh <arquitetura> <adr-dir> <backlog-file> [<specs-dir>] [--check]" >&2; exit 2; }

ARCH=""; ADR_DIR=""; BACKLOG=""; SPECS_DIR=""; MODE_CHECK=0
for a in "$@"; do
  case "$a" in
    --check) MODE_CHECK=1 ;;
    -*) usage ;;
    *) if [ -z "$ARCH" ]; then ARCH="$a"
       elif [ -z "$ADR_DIR" ]; then ADR_DIR="$a"
       elif [ -z "$BACKLOG" ]; then BACKLOG="$a"
       elif [ -z "$SPECS_DIR" ]; then SPECS_DIR="$a"
       else usage; fi ;;
  esac
done
[ -n "$ARCH" ] && [ -n "$ADR_DIR" ] && [ -n "$BACKLOG" ] || usage
[ -f "$ARCH" ] || { echo "trace-arquitetura: arquivo não encontrado: $ARCH" >&2; exit 2; }

# --- Leitura de metadados do ADR (rótulos do template do /zion-adr-new). ---
adr_field() {  # $1 arquivo  $2 rótulo (Status, Área, …) → valor da 1ª ocorrência, trimado
  sed -n "s/^[[:space:]]*-[[:space:]]*\*\*$2:\*\*[[:space:]]*//p" "$1" | head -1 | sed 's/[[:space:]]*$//'
}
adr_superseded() {  # $1 arquivo → 0 (verdadeiro) se o Status declara supersessão
  adr_field "$1" Status | grep -qiE 'Substitu[ií]do por'
}
adr_title() {  # $1 arquivo → título do 1º "# ", ou o basename
  local t; t="$(sed -n '/^# /{s/^# //;p;q;}' "$1")"
  [ -n "$t" ] || t="$(basename "$1" .md)"
  printf '%s' "$t"
}
adr_fixou() {  # $1 arquivo → 1ª linha não-vazia da seção "## Decisão" (derivação best-effort)
  awk '/^## Decisão/ { ins=1; next } ins && /^## / { exit } ins && NF { print; exit }' "$1"
}
adr_specs() {  # $1 id (ADR-002) → "`slug`, `slug`" das specs que o honram, ou vazio
  [ -n "$SPECS_DIR" ] && [ -d "$SPECS_DIR" ] || return 0
  local d slug out=""
  for d in "$SPECS_DIR"/*/; do
    [ -f "$d/spec.md" ] || continue
    sed -n 's/^[[:space:]]*\*\*ADRs honrados:\*\*[[:space:]]*//p' "$d/spec.md" \
      | grep -qE "(^|[^0-9A-Za-z-])$1([^0-9]|$)" || continue
    slug="$(basename "$d")"
    if [ -z "$out" ]; then out="\`$slug\`"; else out="$out, \`$slug\`"; fi
  done
  printf '%s' "$out"
}

# --- Mapa de decisões (§3): decisões VIGENTES agrupadas por área (ADR-018).
#     Área ausente → grupo "Sem área", sempre por último. Substituída sai do mapa e vira rodapé.
build_adr_index() {
  local f id num area title fixou specs tsv nfiles=0 sup=0
  tsv="$(mktemp)"
  for f in "$ADR_DIR"/ADR-*.md; do
    [ -f "$f" ] || continue
    nfiles=$((nfiles+1))
    if adr_superseded "$f"; then sup=$((sup+1)); continue; fi
    id="$(basename "$f" | grep -oE '^ADR-[0-9]+')"
    num="$(printf '%s' "$id" | grep -oE '[0-9]+' | sed 's/^0*//')"
    [ -n "$num" ] || num=0
    area="$(adr_field "$f" 'Área')"
    case "$area" in ''|'<'*'>') area='Sem área' ;; esac
    title="$(adr_title "$f")"
    fixou="$(adr_fixou "$f")"
    specs="$(adr_specs "$id")"
    printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
      "$area" "$num" "$title" "$(basename "$ADR_DIR")/$(basename "$f")" "$fixou" "$specs" >> "$tsv"
  done

  if [ "$nfiles" -eq 0 ]; then
    printf -- '_(nenhum ADR ainda)_\n'; rm -f "$tsv"; return
  fi
  if [ ! -s "$tsv" ]; then
    printf -- '_(nenhuma decisão vigente)_\n'
  else
    awk -F'\t' '
      { a=$1
        if (!(a in minnum) || $2+0 < minnum[a]) minnum[a]=$2+0
        rows[a]=rows[a] $0 "\n" }
      END {
        n=0; for (a in minnum) order[++n]=a
        # áreas pelo menor ADR-n que contêm; "Sem área" sempre por último
        for (i=1;i<=n;i++) for (j=i+1;j<=n;j++) {
          ai=order[i]; aj=order[j]
          ki=(ai=="Sem área")?999999:minnum[ai]
          kj=(aj=="Sem área")?999999:minnum[aj]
          if (kj<ki) { order[i]=aj; order[j]=ai }
        }
        for (i=1;i<=n;i++) {
          a=order[i]; printf "### %s\n", a
          m=split(rows[a], rr, "\n"); cnt=0
          for (k=1;k<=m;k++) if (rr[k]!="") arr[++cnt]=rr[k]
          for (x=1;x<=cnt;x++) for (y=x+1;y<=cnt;y++) {
            split(arr[x],cx,"\t"); split(arr[y],cy,"\t")
            if (cy[2]+0 < cx[2]+0) { t=arr[x]; arr[x]=arr[y]; arr[y]=t }
          }
          for (x=1;x<=cnt;x++) {
            split(arr[x], c, "\t")
            printf "- **[%s](%s)**\n", c[3], c[4]
            det=""
            if (c[5] != "") det = "fixou: " c[5]
            if (c[6] != "") det = (det=="" ? "specs: " c[6] : det " · specs: " c[6])
            if (det != "") printf "  %s\n", det
          }
          for (x=1;x<=cnt;x++) delete arr[x]
        }
      }
    ' "$tsv"
  fi
  [ "$sup" -gt 0 ] && printf -- '_(%d decisão(ões) substituída(s) — veja `%s/`)_\n' "$sup" "$(basename "$ADR_DIR")"
  rm -f "$tsv"
  return 0
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
