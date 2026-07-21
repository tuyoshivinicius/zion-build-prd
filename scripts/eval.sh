#!/usr/bin/env bash
# eval.sh — runner único da camada mecânica da suíte de avaliação (R7).
# Roda os auto-testes (check-prd, check-adr, trace-prd, contract) e emite veredito
# agregado. Exit 0 = todos verdes; exit 1 = qualquer um falhou; exit 2 = uso.
#
# Uso:
#   eval.sh              # roda todos, na ordem prd → estudo → adr → trace → contract
#   eval.sh prd          # roda só um (conveniência de dev)
#   eval.sh adr
#   eval.sh trace
#   eval.sh contract
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

declare -A TESTS=(
  [prd]="scripts/test-check-prd.sh"
  [estudo]="scripts/test-check-estudo.sh"
  [experiencia]="scripts/test-check-experiencia.sh"
  [delegacao]="scripts/test-check-delegacao.sh"
  [adr]="scripts/test-check-adr.sh"
  [trace]="scripts/test-trace-prd.sh"
  [backlog]="scripts/test-trace-backlog.sh"
  [arquitetura]="scripts/test-check-arquitetura.sh"
  [trace-arquitetura]="scripts/test-trace-arquitetura.sh"
  [contract]="scripts/test-check-superpowers-contract.sh"
  [canon]="scripts/test-check-canon.sh"
  [commit]="scripts/test-check-commit.sh"
)
ORDER=(prd estudo experiencia delegacao adr trace backlog arquitetura trace-arquitetura contract canon commit)

sel="${1:-}"
if [ -n "$sel" ]; then
  case "$sel" in
    prd|estudo|experiencia|delegacao|adr|trace|backlog|arquitetura|trace-arquitetura|contract|canon|commit) ORDER=("$sel") ;;
    *) echo "uso: eval.sh [prd|estudo|experiencia|delegacao|adr|trace|backlog|arquitetura|trace-arquitetura|contract|canon|commit]" >&2; exit 2 ;;
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
