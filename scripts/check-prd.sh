#!/usr/bin/env bash
# check-prd.sh — verificador mecânico das regras decidíveis do harness (R1).
# Verifica; NÃO bloqueia. Exit 0 = limpo, 1 = achados, 2 = erro de uso/ambiente.
# Quem lê o exit é a Fase 4, que aconselha (não reverte).
#
# Uso:
#   check-prd.sh prd     <arquivo>    # stack + nfr-sem-numero + rf-fora-de-epico
#   check-prd.sh specify <arquivo|->  # só stack (prompt do specify; - lê do stdin)
#
# Denylist: bloco ```denylist do quality-rules.md ao lado do script (references/)
# ou, no repo, em ../assets/quality-rules.md.
set -u

usage() { echo "uso: check-prd.sh <prd|specify> <arquivo|->" >&2; exit 2; }

mode="${1:-}"; target="${2:-}"
[ -n "$mode" ] && [ -n "$target" ] || usage
case "$mode" in prd|specify) ;; *) usage ;; esac

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -f "$SCRIPT_DIR/quality-rules.md" ]; then
  QR="$SCRIPT_DIR/quality-rules.md"                 # caso references/
elif [ -f "$SCRIPT_DIR/../assets/quality-rules.md" ]; then
  QR="$SCRIPT_DIR/../assets/quality-rules.md"       # caso repo
else
  echo "check-prd: quality-rules.md não encontrado (denylist indisponível)" >&2
  exit 2
fi

# Normaliza o alvo para um arquivo real (com line numbers) + rótulo de exibição.
TMPIN=""
cleanup() { [ -n "$TMPIN" ] && rm -f "$TMPIN"; }
trap cleanup EXIT
if [ "$target" = "-" ]; then
  TMPIN="$(mktemp)"; cat > "$TMPIN"; SRC="$TMPIN"; LABEL="specify"
else
  [ -f "$target" ] || { echo "check-prd: arquivo não encontrado: $target" >&2; exit 2; }
  SRC="$target"; LABEL="$(basename "$target")"
fi

# --- checks (preenchidos nas próximas tasks) ---
check_stack() { :; }
check_nfr()   { :; }
check_rf()    { :; }

case "$mode" in
  prd)     findings="$(check_stack; check_nfr; check_rf)" ;;
  specify) findings="$(check_stack)" ;;
esac

if [ -n "$findings" ]; then
  printf '%s\n' "$findings"
  count="$(printf '%s\n' "$findings" | grep -c .)"
  echo "check-prd: $count achado(s)"
  exit 1
else
  echo "check-prd: limpo"
  exit 0
fi
