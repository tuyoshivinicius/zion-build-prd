#!/usr/bin/env bash
# check-commit.sh — verificador de Conventional Commits de UMA mensagem (RF-21 / ADR-019).
# Guard de GOVERNANÇA: lido pelo .githooks/commit-msg e pela CI (commit-lint.yml) — BLOQUEIA.
# (Diferente dos verificadores dos projetos-alvo, que aconselham — RN-01/ADR-004.)
# Exit 0 = conforme · 1 = fora da convenção · 2 = erro de uso/ambiente.
#
# Uso:
#   check-commit.sh <arquivo-de-mensagem>   # 1ª linha não-comentário = header
#
# Convenção (tabela de bump do ADR-019):
#   <tipo>(<escopo>)?!?: <assunto>
#   tipos: feat fix docs test chore ci refactor style perf build revert
set -u

usage() { echo "uso: check-commit.sh <arquivo-de-mensagem>" >&2; exit 2; }

target="${1:-}"
[ -n "$target" ] || usage
case "$target" in -*) usage ;; esac
[ -f "$target" ] || { echo "check-commit: arquivo não encontrado: $target" >&2; exit 2; }

TYPES='feat|fix|docs|test|chore|ci|refactor|style|perf|build|revert'

# Header = 1ª linha não-vazia que não seja comentário (# …) — ignora o template do
# editor e o corpo/diff do modo verbose.
header="$(grep -vE '^[[:space:]]*#' "$target" | grep -vE '^[[:space:]]*$' | head -1)"

if [ -z "$header" ]; then
  echo "check-commit: mensagem-vazia — nenhuma linha de assunto encontrada"
  exit 1
fi

# Commits de merge/revert automáticos do git não são autoria de convenção — aceitos.
case "$header" in
  "Merge "*|"Revert \""*) echo "check-commit: conforme (merge/revert)"; exit 0 ;;
esac

if printf '%s\n' "$header" | grep -qE "^(${TYPES})(\([a-z0-9._-]+\))?!?: .+"; then
  echo "check-commit: conforme"
  exit 0
else
  printf 'check-commit: fora-da-convencao — "%s"\n' "$header"
  printf '  esperado: <tipo>(<escopo>)?!?: <assunto>  (tipos: %s)\n' "$TYPES"
  exit 1
fi
