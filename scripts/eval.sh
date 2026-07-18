#!/usr/bin/env bash
# eval.sh — runner único da camada mecânica da suíte de avaliação (R7).
# Roda os três auto-testes (check-prd, check-adr, trace-prd) e emite veredito
# agregado. Exit 0 = todos verdes; exit 1 = qualquer um falhou; exit 2 = uso.
#
# Uso:
#   eval.sh              # roda os três, na ordem prd → adr → trace
#   eval.sh prd          # roda só um (conveniência de dev)
#   eval.sh adr
#   eval.sh trace
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

declare -A TESTS=(
  [prd]="scripts/test-check-prd.sh"
  [adr]="scripts/test-check-adr.sh"
  [trace]="scripts/test-trace-prd.sh"
)
ORDER=(prd adr trace)

sel="${1:-}"
if [ -n "$sel" ]; then
  case "$sel" in
    prd|adr|trace) ORDER=("$sel") ;;
    *) echo "uso: eval.sh [prd|adr|trace]" >&2; exit 2 ;;
  esac
fi

fail=0
for name in "${ORDER[@]}"; do
  echo "=== eval: $name ==="
  if ! bash "${TESTS[$name]}"; then fail=1; fi
done

if [ "$fail" -eq 0 ]; then
  echo "eval: tudo verde"
else
  echo "eval: FALHOU"
  exit 1
fi
