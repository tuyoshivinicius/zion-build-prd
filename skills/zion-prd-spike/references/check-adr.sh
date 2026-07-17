#!/usr/bin/env bash
# check-adr.sh — verificador de presença de evidência nos ADRs (R3).
# Verifica a PRESENÇA do lastro (não a qualidade), no mesmo molde de
# check-prd.sh (R1) e trace-prd.sh (R2): o script verifica, o humano decide.
# Exit 0 = limpo · 1 = achados · 2 = erro de uso/ambiente.
# Lido pela Fase 4 de /zion-prd-spike, que aconselha (não bloqueia).
#
# Uso:
#   check-adr.sh <dir-de-adrs>     # ex.: check-adr.sh docs/adr
#
# Para cada <dir>/ADR-*.md (glob de filhos diretos → ignora spikes/):
#   1. sem linha **Evidência:** preenchida (vazia ou placeholder <…>) → sem-evidencia
#   2. Evidência aponta docs/adr/spikes/<seg>/ (risco de execução):
#        <dir>/spikes/<seg> ausente        → spike-dir-ausente
#        <dir>/spikes/<seg> vazio          → spike-dir-vazio
#        <dir>/spikes/<seg> sem README.md  → spike-sem-readme
#   3. Evidência de conhecimento sem URL nem caminho → evidencia-sem-lastro
set -u

usage() { echo "uso: check-adr.sh <dir-de-adrs>" >&2; exit 2; }

DIR="${1:-}"
[ -n "$DIR" ] || usage
case "$DIR" in -*) usage ;; esac
[ -d "$DIR" ] || { echo "check-adr: diretório não encontrado: $DIR" >&2; exit 2; }

# Valor da primeira linha `- **Evidência:**`, sem o rótulo. Casa bytes literais
# (a acentuação de "Evidência" é UTF-8 fixa no template e nas fixtures).
evidence_value() {  # $1 arquivo
  sed -n 's/^[[:space:]]*-[[:space:]]*\*\*Evidência:\*\*[[:space:]]*//p' "$1" | head -1
}

findings=""
add() {  # $1 achado
  if [ -z "$findings" ]; then findings="$1"; else findings="$findings
$1"; fi
}

nadr=0
for f in "$DIR"/ADR-*.md; do
  [ -f "$f" ] || continue
  nadr=$((nadr+1))
  label="$(basename "$f")"
  ev="$(evidence_value "$f")"
  ev="$(printf '%s' "$ev" | sed 's/[[:space:]]*$//')"   # trim à direita

  # Vazia ou placeholder <…> → sem evidência.
  if [ -z "$ev" ] || printf '%s' "$ev" | grep -qE '^<.*>$'; then
    add "$label: sem-evidencia — nenhuma linha **Evidência:** preenchida (aponte o spike dir ou a fonte de pesquisa)"
    continue
  fi

  case "$ev" in
    *docs/adr/spikes/*)
      # Risco de execução. Ignora o prefixo citado; resolve <dir>/spikes/<seg>.
      seg="$(printf '%s' "$ev" | grep -oE 'docs/adr/spikes/[^[:space:])]+' | head -1 | sed 's#^docs/adr/spikes/##; s#/*$##')"
      target="$DIR/spikes/$seg"
      if [ ! -d "$target" ]; then
        add "$label: spike-dir-ausente — $ev não existe (crie o spike dir ou corrija o caminho)"
      elif [ -z "$(ls -A "$target" 2>/dev/null)" ]; then
        add "$label: spike-dir-vazio — $target sem artefatos (adicione o spike + README.md)"
      elif [ ! -f "$target/README.md" ]; then
        add "$label: spike-sem-readme — $target sem README.md (documente pergunta/execução/veredito)"
      fi
      ;;
    *)
      # Risco de conhecimento: precisa de URL (http…) ou de um caminho de artefato.
      if ! printf '%s' "$ev" | grep -qE 'https?://|/|\.[A-Za-z0-9]+'; then
        add "$label: evidencia-sem-lastro — \"$ev\" sem URL nem caminho de artefato (aponte a fonte)"
      fi
      ;;
  esac
done

if [ "$nadr" -eq 0 ]; then
  echo "check-adr: nenhum ADR-*.md em $DIR" >&2
  exit 2
fi

if [ -n "$findings" ]; then
  printf '%s\n' "$findings"
  count="$(printf '%s\n' "$findings" | grep -c .)"
  echo "check-adr: $count achado(s)"
  exit 1
else
  echo "check-adr: limpo"
  exit 0
fi
