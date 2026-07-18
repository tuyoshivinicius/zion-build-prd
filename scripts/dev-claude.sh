#!/usr/bin/env bash
# dev-claude.sh — abre uma sessão do Claude Code servindo o working tree deste
# repo via `--plugin-dir`, para dogfooding local das skills (inclusive as ainda
# não publicadas no GitHub). A cópia local sombreia a cópia instalada do
# marketplace de mesmo nome, por sessão (precedência documentada do --plugin-dir).
# Não é verificador (sem contrato exit 0/1/2) e não muta ~/.claude — script de
# dev, no precedente de scripts/setup-hooks.sh.
#
# Uso: scripts/dev-claude.sh [args extras repassados ao claude]
set -euo pipefail

# Raiz do repo a partir do caminho do próprio script — funciona de qualquer dir.
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# É a raiz do harness? (tem o manifesto do plugin)
if [ ! -f "$ROOT/.claude-plugin/plugin.json" ]; then
  echo "dev-claude: $ROOT não é a raiz do harness (.claude-plugin/plugin.json ausente)." >&2
  echo "dev-claude: rode o script a partir de scripts/ do repo zion-build-prd." >&2
  exit 1
fi

# O Claude Code está instalado e no PATH?
if ! command -v claude >/dev/null 2>&1; then
  echo "dev-claude: 'claude' não está no PATH — Claude Code não instalado ou fora do PATH." >&2
  echo "dev-claude: instale o Claude Code e garanta que 'claude' resolve no shell." >&2
  exit 1
fi

# Transparência: esta sessão sombreia a cópia instalada do marketplace de mesmo nome.
echo "dev-claude: servindo o working tree via --plugin-dir=$ROOT (sombreia a cópia do marketplace nesta sessão)."

exec claude --plugin-dir "$ROOT" "$@"
