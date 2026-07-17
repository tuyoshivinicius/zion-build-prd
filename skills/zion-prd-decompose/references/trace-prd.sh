#!/usr/bin/env bash
# trace-prd.sh — reconciliador da tabela de rastreabilidade (§12) da PRD (R2).
# Deriva a §12 a partir da §6 da PRD + specs/*/spec.md. ESCREVE (git é o desfazer);
# --check é read-only. Verifica e reconcilia; o humano decide.
#
# Uso:
#   trace-prd.sh <prd-file> <specs-dir> [--check]
#     <specs-dir> ausente/vazio → bootstrap (tudo pendente).
#     --check → não grava; reporta drift/avisos e sai 1.
#
# Exit: 0 (limpo) · 1 (drift/avisos) · 2 (erro de uso/ambiente).
set -u

usage() { echo "uso: trace-prd.sh <prd-file> <specs-dir> [--check]" >&2; exit 2; }

PRD=""; SPECS_DIR=""; MODE_CHECK=0
for a in "$@"; do
  case "$a" in
    --check) MODE_CHECK=1 ;;
    -*) usage ;;
    *) if [ -z "$PRD" ]; then PRD="$a"
       elif [ -z "$SPECS_DIR" ]; then SPECS_DIR="$a"
       else usage; fi ;;
  esac
done
[ -n "$PRD" ] || usage
[ -f "$PRD" ] || { echo "trace-prd: arquivo não encontrado: $PRD" >&2; exit 2; }
grep -qE '^##[[:space:]]*6([^0-9]|$)'  "$PRD" || { echo "trace-prd: PRD sem seção 6"  >&2; exit 2; }
grep -qE '^##[[:space:]]*12([^0-9]|$)' "$PRD" || { echo "trace-prd: PRD sem seção 12" >&2; exit 2; }

TAB="$(printf '\t')"
SEC6=""; RFSPEC=""; UNTRACE=""; SPECSTATUS=""; OLDREL=""; OLDSTATUS=""
cleanup() { rm -f "$SEC6" "$RFSPEC" "$UNTRACE" "$SPECSTATUS" "$OLDREL" "$OLDSTATUS" 2>/dev/null; }
trap cleanup EXIT

# --- §6 da PRD: RF agrupado por Épico E#, com descrição de 1 frase por RF. ---
# Múltiplos RF por linha separados por ';'. Casa "pico E#" (evita o É multibyte).
parse_section6() {
  awk '
    /^## / { n=$2; sub(/\./,"",n); sect=n; next }
    sect=="6" {
      if (match($0, /pico[[:space:]]+E[0-9]+/)) { e=substr($0,RSTART,RLENGTH); sub(/.*[[:space:]]/,"",e); cur=e }
      line=$0
      while (match(line, /RF-[0-9]+/)) {
        rf=substr(line,RSTART,RLENGTH); rest=substr(line,RSTART+RLENGTH); desc=rest
        if (match(desc,/RF-[0-9]+/)) desc=substr(desc,1,RSTART-1)
        if (match(desc,/;/))         desc=substr(desc,1,RSTART-1)
        gsub(/\*/,"",desc); gsub(/^[[:space:]:]+/,"",desc); gsub(/[[:space:];.]+$/,"",desc)
        print rf "\t" cur "\t" desc
        line=rest
      }
    }
  ' "$1"
}

# --- Uma coluna da tabela §12 existente, indexada pelo cabeçalho (RF\tvalor). ---
table_col() {  # $1 prd  $2 nome-da-coluna
  awk -v want="$2" '
    function lc(s){ return tolower(s) }
    /^##[[:space:]]*12([^0-9]|$)/ { in12=1; next }
    in12 && /^## / { in12=0 }
    in12 && /^[[:space:]]*\|/ {
      line=$0; sub(/^[[:space:]]*\|/,"",line); sub(/\|[[:space:]]*$/,"",line)
      nc=split(line, c, /\|/)
      for(i=1;i<=nc;i++){ gsub(/^[[:space:]]+|[[:space:]]+$/,"",c[i]) }
      if (!hdr) {
        for(i=1;i<=nc;i++) if (lc(c[i])=="rf") rfcol=i
        if (rfcol) { for(i=1;i<=nc;i++) if (index(lc(c[i]), lc(want))) wcol=i; hdr=1 }
        next
      }
      if (c[1] ~ /^[-:]+$/) next
      if (rfcol && wcol && match(c[rfcol],/RF-[0-9]+/))
        print substr(c[rfcol],RSTART,RLENGTH) "\t" c[wcol]
    }
  ' "$1"
}

# --- Status de UMA spec a partir do tasks.md ---
#   ausente ou com ao menos um "- [ ]" aberto → spec;  senão → impl.
spec_status() {  # $1 spec-dir
  local tasks="$1/tasks.md"
  [ -f "$tasks" ] || { printf 'spec'; return; }
  if grep -qE '^[[:space:]]*- \[ \]' "$tasks"; then printf 'spec'; return; fi
  printf 'impl'
}

# --- Varre specs/*/spec.md → $RFSPEC (RF\tnome), $UNTRACE (nome), $SPECSTATUS (nome\tstatus). ---
scan_specs() {
  local dir="$1" spec name line rf
  : > "$RFSPEC"; : > "$UNTRACE"; : > "$SPECSTATUS"
  [ -n "$dir" ] && [ -d "$dir" ] || return 0
  for spec in "$dir"/*/spec.md; do
    [ -f "$spec" ] || continue
    name="$(basename "$(dirname "$spec")")"
    printf '%s\t%s\n' "$name" "$(spec_status "$(dirname "$spec")")" >> "$SPECSTATUS"
    line="$(grep -iE 'RF cobertos:' "$spec" | head -1)"
    if [ -z "$line" ]; then printf '%s\n' "$name" >> "$UNTRACE"; continue; fi
    for rf in $(printf '%s' "$line" | grep -oE 'RF-[0-9]+'); do
      printf '%s\t%s\n' "$rf" "$name" >> "$RFSPEC"
    done
  done
}

# --- Avisos: RF órfão (spec cita RF fora da §6), spec intraçável, RF descoberto. ---
compute_warnings() {
  # RF órfão: RF em $RFSPEC ausente da §6.
  awk -F'\t' 'NR==FNR{ins[$1]=1; next}
    { if(!($1 in ins)) print "RF órfão: specs/" $2 " declara " $1 " (fora da seção 6 da PRD)" }' \
    "$SEC6" "$RFSPEC" | sort -u
  # Spec intraçável: sem a linha **RF cobertos:**.
  while read -r name; do
    [ -n "$name" ] && echo "Spec intraçável: specs/$name sem linha **RF cobertos:**"
  done < "$UNTRACE"
  # RF descoberto: RF in-scope na §6 sem nenhuma spec (permanece pendente).
  awk -F'\t' 'NR==FNR{cov[$1]=1; next}
    { if(!($1 in cov)) print "RF descoberto: " $1 " sem spec (permanece pendente)" }' \
    "$RFSPEC" "$SEC6" | sort -u
}

specs_for_rf() {  # $1 rf → `specs/a`, `specs/b`  (vazio se nenhuma)
  local rf="$1" out="" r name
  while IFS="$TAB" read -r r name; do
    [ "$r" = "$rf" ] || continue
    if [ -z "$out" ]; then out="\`specs/$name\`"; else out="$out, \`specs/$name\`"; fi
  done < "$RFSPEC"
  printf '%s' "$out"
}

status_for_rf() {  # $1 rf → glifo (menos avançado entre as specs; ☐ se nenhuma)
  local rf="$1" rank=-1 r name st v
  while IFS="$TAB" read -r r name; do
    [ "$r" = "$rf" ] || continue
    st="$(awk -F'\t' -v n="$name" '$1==n{print $2; exit}' "$SPECSTATUS")"
    case "$st" in impl) v=2 ;; *) v=1 ;; esac
    if [ "$rank" -eq -1 ] || [ "$v" -lt "$rank" ]; then rank="$v"; fi
  done < "$RFSPEC"
  case "$rank" in 2) printf '● implementada' ;; 1) printf '◐ em spec' ;; *) printf '☐ pendente' ;; esac
}

release_for_rf() { awk -F'\t' -v r="$1" '$1==r{print $2; exit}' "$OLDREL"; }

# --- Monta o bloco completo da §12 (nota + tabela + legenda). ---
build_table() {
  printf '> Tabela derivada — regenerada por `/zion-prd-trace`. Não edite Status/Feature/Spec à mão.\n\n'
  printf '| RF | Descrição | Épico | Feature / Spec | Release | Status |\n'
  printf '|----|-----------|-------|----------------|---------|--------|\n'
  while IFS="$TAB" read -r rf epic desc; do
    [ -n "$rf" ] || continue
    printf '| %s | %s | %s | %s | %s | %s |\n' \
      "$rf" "$desc" "$epic" "$(specs_for_rf "$rf")" "$(release_for_rf "$rf")" "$(status_for_rf "$rf")"
  done < "$SEC6"
  printf '\nLegenda de status: ☐ pendente · ◐ em spec · ● implementada.\n'
}

# --- Reescreve a §12 in-place: preserva o cabeçalho e as seções vizinhas. ---
write_section12() {  # $1 prd  $2 arquivo-com-a-tabela
  local prd="$1" tf="$2" tmp; tmp="$(mktemp)"
  awk -v tf="$tf" '
    BEGIN { while ((getline l < tf) > 0) body = body l "\n" }
    /^##[[:space:]]*12([^0-9]|$)/ && !done { print; print ""; printf "%s", body; print ""; done=1; skip=1; next }
    skip && /^## / { skip=0 }
    skip { next }
    { print }
  ' "$prd" > "$tmp" && mv "$tmp" "$prd"
}

# --- Modo read-only: escreve numa cópia e diffa contra o original. ---
run_check() {  # $1 avisos  $2 tabela
  local warnings="$1" table="$2" tmpprd tf drift=""
  tmpprd="$(mktemp)"; cp "$PRD" "$tmpprd"
  tf="$(mktemp)"; printf '%s\n' "$table" > "$tf"
  write_section12 "$tmpprd" "$tf"
  if ! diff -q "$PRD" "$tmpprd" >/dev/null 2>&1; then
    echo "trace-prd: drift na seção 12 (rode sem --check para reconciliar):"
    diff "$PRD" "$tmpprd" || true
    drift=1
  fi
  [ -n "$warnings" ] && printf '%s\n' "$warnings"
  rm -f "$tmpprd" "$tf"
  if [ -n "$drift" ] || [ -n "$warnings" ]; then echo "trace-prd: fora de dia"; return 1; fi
  echo "trace-prd: em dia"; return 0
}

# --- Orquestração ---
SEC6="$(mktemp)"; RFSPEC="$(mktemp)"; UNTRACE="$(mktemp)"
SPECSTATUS="$(mktemp)"; OLDREL="$(mktemp)"; OLDSTATUS="$(mktemp)"

parse_section6 "$PRD" > "$SEC6"
[ -s "$SEC6" ] || { echo "trace-prd: nenhum RF-xx na seção 6 de $PRD" >&2; exit 2; }
table_col "$PRD" Release > "$OLDREL"
table_col "$PRD" Status  > "$OLDSTATUS"
scan_specs "$SPECS_DIR"
warnings="$(compute_warnings)"
wcount=0; [ -n "$warnings" ] && wcount="$(printf '%s\n' "$warnings" | grep -c .)"
table="$(build_table)"

if [ "$MODE_CHECK" = "1" ]; then
  run_check "$warnings" "$table"; exit $?
fi

tf="$(mktemp)"; printf '%s\n' "$table" > "$tf"
write_section12 "$PRD" "$tf"; rm -f "$tf"

updated=0
while IFS="$TAB" read -r rf epic desc; do
  [ -n "$rf" ] || continue
  newst="$(status_for_rf "$rf")"
  oldst="$(awk -F'\t' -v r="$rf" '$1==r{print $2; exit}' "$OLDSTATUS")"
  if [ "$oldst" != "$newst" ]; then
    echo "  $rf: ${oldst:-☐ (nova)} → $newst"
    updated=$((updated+1))
  fi
done < "$SEC6"

[ -n "$warnings" ] && printf '%s\n' "$warnings"

if [ "$updated" -eq 0 ] && [ "$wcount" -eq 0 ]; then
  echo "trace-prd: em dia"; exit 0
fi
echo "trace-prd: $updated linha(s) atualizada(s), $wcount aviso(s)"
[ "$wcount" -gt 0 ] && exit 1 || exit 0
