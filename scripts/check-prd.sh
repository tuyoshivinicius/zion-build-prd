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
# Extrai os termos do bloco ```denylist do quality-rules.md (um por linha, minúsculo).
extract_denylist() {
  awk '
    /^```denylist[[:space:]]*$/ { inblock=1; next }
    inblock && /^```/           { inblock=0; next }
    inblock && NF               { print tolower($0) }
  ' "$QR"
}

check_stack() {
  local denyfile; denyfile="$(mktemp)"
  extract_denylist > "$denyfile"

  # Denylist: palavra inteira, case-insensitive; -o imprime o termo casado, -n a linha.
  if [ -s "$denyfile" ]; then
    grep -niwoF -f "$denyfile" "$SRC" 2>/dev/null | while IFS=: read -r n term; do
      printf '%s:%s: stack — "%s" (mova para o plan.md da feature)\n' "$LABEL" "$n" "$term"
    done
  fi
  rm -f "$denyfile"

  # Sinais estruturais de alta precisão.
  grep -niEo 'npm install|pip install|yarn add' "$SRC" 2>/dev/null | while IFS=: read -r n m; do
    printf '%s:%s: stack — "%s" (comando de instalação; vai no plan.md)\n' "$LABEL" "$n" "$m"
  done
  grep -nE '^[[:space:]]*(import |from [^ ]+ import )' "$SRC" 2>/dev/null | while IFS=: read -r n rest; do
    printf '%s:%s: stack — "%s" (código; vai no plan.md)\n' "$LABEL" "$n" "$(printf '%s' "$rest" | sed 's/^[[:space:]]*//')"
  done
  grep -nE '^[[:space:]]*```' "$SRC" 2>/dev/null | while IFS=: read -r n _; do
    printf '%s:%s: stack — "bloco de código" (detalhe técnico; vai no plan.md)\n' "$LABEL" "$n"
  done
  grep -niEo '[A-Za-z][A-Za-z0-9._-]*[[:space:]]+v?[0-9]+\.[0-9]+\.[0-9]+' "$SRC" 2>/dev/null | while IFS=: read -r n m; do
    printf '%s:%s: stack — "%s" (versão de dependência; vai no plan.md)\n' "$LABEL" "$n" "$m"
  done
}
# Seção 7: item de NFR (bullet ou id NFR-) sem nenhum dígito → achado.
check_nfr() {
  awk -v label="$LABEL" '
    /^## / { n=$2; sub(/\./,"",n); sect=(n=="7"); next }
    sect && /^[[:space:]]*([-*]|NFR-)/ && $0 !~ /[0-9]/ {
      line=$0
      sub(/^[[:space:]]*[-*][[:space:]]*/,"",line)
      printf "%s:%d: nfr-sem-numero — \"%s\" (dê um número)\n", label, NR, line
    }
  ' "$SRC"
}
# Seção 6: RF-xx antes do primeiro "Épico E#" → solto. Fora da seção 6: RF-xx
# em bullet não-tabela → definição fora do lugar. (match 2-arg = POSIX, portável.)
check_rf() {
  awk -v label="$LABEL" '
    /^## / { n=$2; sub(/\./,"",n); sect=n; if (n=="6") epic=0; next }
    {
      if (sect=="6" && $0 ~ /pico[[:space:]]+[Ee][0-9]/) epic=1
      if ($0 ~ /RF-[0-9]+/) {
        match($0, /RF-[0-9]+/); rf=substr($0, RSTART, RLENGTH)
        if (sect=="6") {
          if (epic==0)
            printf "%s:%d: rf-fora-de-epico — \"%s\" (agrupe sob um Épico E#)\n", label, NR, rf
        } else if ($0 ~ /^[[:space:]]*[-*]/ && $0 !~ /^[[:space:]]*\|/) {
          printf "%s:%d: rf-fora-de-epico — \"%s\" (definido fora da seção 6)\n", label, NR, rf
        }
      }
    }
  ' "$SRC"
}

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
