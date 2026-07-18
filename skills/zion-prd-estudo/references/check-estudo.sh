#!/usr/bin/env bash
# check-estudo.sh — verificador mecânico do documento de estudo (Estágio 0 / RF-17).
# Verifica; NÃO bloqueia. Exit 0 = limpo, 1 = achados, 2 = erro de uso/ambiente.
# Quem lê o exit é a Fase 4 do /zion-prd-estudo, que aconselha (não reverte).
#
# Uso:
#   check-estudo.sh <arquivo>
#
# Verifica o decidível:
#   - as 6 seções obrigatórias presentes (## Contexto, ## Edge cases e incertezas,
#     ## Alternativas, ## ROI, ## Recomendação, ## Próximo passo sugerido; numeração
#     "N. " opcional);
#   - alternativa "não fazer" presente na seção Alternativas;
#   - denylist de stack (bloco ```denylist do quality-rules.md, mesmo mecanismo do
#     check-prd.sh) aplicada SÓ às seções Alternativas e ROI.
# Fica em prosa na Fase 4 (indecidível): citação de fonte em toda afirmação.
#
# Denylist: quality-rules.md ao lado do script (references/) ou, no repo,
# em ../assets/quality-rules.md.
set -u

usage() { echo "uso: check-estudo.sh <arquivo>" >&2; exit 2; }

target="${1:-}"
[ -n "$target" ] || usage
[ -f "$target" ] || { echo "check-estudo: arquivo não encontrado: $target" >&2; exit 2; }

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -f "$SCRIPT_DIR/quality-rules.md" ]; then
  QR="$SCRIPT_DIR/quality-rules.md"                 # caso references/
elif [ -f "$SCRIPT_DIR/../assets/quality-rules.md" ]; then
  QR="$SCRIPT_DIR/../assets/quality-rules.md"       # caso repo
else
  echo "check-estudo: quality-rules.md não encontrado (denylist indisponível)" >&2
  exit 2
fi

LABEL="$(basename "$target")"

SECTIONS=("Contexto" "Edge cases e incertezas" "Alternativas" "ROI" "Recomendação" "Próximo passo sugerido")

# Cabeçalho de seção: "## Nome" ou "## N. Nome" (numeração opcional, nada além do nome).
has_section() {
  grep -qiE "^##[[:space:]]+([0-9]+\.[[:space:]]+)?$1[[:space:]]*$" "$target"
}

# Corpo de uma seção (nome ASCII — usado só para Alternativas e ROI): imprime "NR:linha"
# do cabeçalho ao próximo "## ". Case-insensitive via tolower (POSIX awk, sem IGNORECASE).
section_body() {
  awk -v name="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')" '
    /^##[[:space:]]/ {
      line=tolower($0)
      sub(/^##[[:space:]]+/,"",line)
      sub(/^[0-9]+\.[[:space:]]+/,"",line)
      sub(/[[:space:]]+$/,"",line)
      inside=(line==name)
      next
    }
    inside { printf "%d:%s\n", NR, $0 }
  ' "$target"
}

check_sections() {
  local s
  for s in "${SECTIONS[@]}"; do
    has_section "$s" \
      || printf '%s: secao-ausente — falta a seção "## %s" (as 6 seções do estudo são obrigatórias)\n' "$LABEL" "$s"
  done
}

# A alternativa "não fazer" é obrigatória DENTRO da seção Alternativas.
check_nao_fazer() {
  has_section "Alternativas" || return 0
  section_body "Alternativas" | grep -qiE 'n[aã]o fazer' \
    || printf '%s: nao-fazer-ausente — a seção Alternativas não inclui a alternativa "não fazer"\n' "$LABEL"
}

# Extrai os termos do bloco ```denylist do quality-rules.md (um por linha, minúsculo).
extract_denylist() {
  awk '
    /^```denylist[[:space:]]*$/ { inblock=1; next }
    inblock && /^```/           { inblock=0; next }
    inblock && NF               { print tolower($0) }
  ' "$QR"
}

# Denylist (palavra inteira, case-insensitive) só nas seções Alternativas e ROI —
# as alternativas ficam em nível de o-quê; o Contexto pode citar a stack vigente.
check_stack() {
  local denyfile; denyfile="$(mktemp)"
  extract_denylist > "$denyfile"
  if [ -s "$denyfile" ]; then
    { section_body "Alternativas"; section_body "ROI"; } | while IFS=: read -r n text; do
      printf '%s\n' "$text" | grep -iwoF -f "$denyfile" | while read -r term; do
        printf '%s:%s: stack — "%s" (alternativa em nível de o-quê; stack fica para o plan.md)\n' "$LABEL" "$n" "$term"
      done
    done
  fi
  rm -f "$denyfile"
}

findings="$(check_sections; check_nao_fazer; check_stack)"

if [ -n "$findings" ]; then
  printf '%s\n' "$findings"
  count="$(printf '%s\n' "$findings" | grep -c .)"
  echo "check-estudo: $count achado(s)"
  exit 1
else
  echo "check-estudo: limpo"
  exit 0
fi
