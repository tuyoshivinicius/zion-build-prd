#!/usr/bin/env bash
# check-superpowers-contract.sh — checagem estática do contrato harness↔brainstorming (R9).
# NÃO exercita a skill (ela é interativa/socrática): faz grep de marcadores de CAPACIDADE no
# SKILL.md instalado, análogo a check-assets. Detecta quebra de contrato num upgrade do
# superpowers — não diff de frase. Fonte da verdade das capacidades e runbook de drift:
# assets/superpowers-contract.md.
#
# Uso:
#   check-superpowers-contract.sh                 # auto-localiza o brainstorming instalado
#   check-superpowers-contract.sh --skill <path>  # aponta um SKILL.md (usado pelo auto-teste)
#
# Exit: 0 = contrato intacto OU não verificável (superpowers ausente) ·
#       1 = encontrado mas ≥1 capacidade sumiu (drift real) · 2 = erro de uso/ambiente.
set -u

usage() { echo "uso: check-superpowers-contract.sh [--skill <path-para-SKILL.md>]" >&2; exit 2; }

skill_arg=""
while [ $# -gt 0 ]; do
  case "$1" in
    --skill) shift; skill_arg="${1:-}"; [ -n "$skill_arg" ] || usage ;;
    -h|--help) usage ;;
    *) usage ;;
  esac
  shift
done

# --- Localização do brainstorming/SKILL.md (primeira que existir vence) ---
SKILL=""
if [ -n "$skill_arg" ]; then
  [ -f "$skill_arg" ] || { echo "check-superpowers-contract: --skill não encontrado: $skill_arg" >&2; exit 2; }
  SKILL="$skill_arg"
else
  # Plugin cache: havendo várias versões, a maior vence (sort -V), coerente com o load-time.
  cache_hit="$(ls -1 "$HOME"/.claude/plugins/cache/superpowers-marketplace/superpowers/*/skills/brainstorming/SKILL.md 2>/dev/null | sort -V | tail -1)"
  if [ -n "$cache_hit" ]; then
    SKILL="$cache_hit"
  elif [ -f "$HOME/.claude/skills/brainstorming/SKILL.md" ]; then
    SKILL="$HOME/.claude/skills/brainstorming/SKILL.md"   # fallback npx skills
  fi
fi

# --- Degradação graciosa: nada localizado → não verificável, sai 0 (ok em CI) ---
if [ -z "$SKILL" ]; then
  echo "∅ superpowers não instalado localmente — contrato não verificável aqui (ok em CI)"
  exit 0
fi

# Versão só para a mensagem (extraída do caminho do cache; "?" nas fixtures).
ver="$(printf '%s' "$SKILL" | grep -oE '/superpowers/[0-9][^/]*/' | head -1 | sed 's#/superpowers/##; s#/##')"
[ -n "$ver" ] || ver="?"

content="$(cat "$SKILL")"
has() { printf '%s' "$content" | grep -qiE -- "$1"; }

findings=""
drift() {  # $1 = "Cx: descrição da capacidade"
  local msg="⚠ $1 sumiu do brainstorming v$ver — revalidar o contrato (ver superpowers-contract.md)"
  if [ -z "$findings" ]; then findings="$msg"; else findings="$findings
$msg"; fi
}

# C1 — aceita enquadramento fixo e refina ideia → design (satisfaz com QUALQUER marcador)
has 'turn ideas into.*designs' || has 'refine the idea' \
  || drift "C1: aceitar enquadramento e refinar ideia→design"

# C2 — grava o resultado num arquivo sob docs/ (satisfaz só com os DOIS marcadores)
{ has 'Write design doc' && has 'save to.*docs/'; } \
  || drift "C2: gravar o design num arquivo sob docs/"

# C3 — diálogo uma pergunta / uma seção por vez (satisfaz com QUALQUER marcador)
has 'one question at a time' || has 'Present design.*section' \
  || drift "C3: conduzir diálogo uma pergunta/seção por vez"

if [ -n "$findings" ]; then
  printf '%s\n' "$findings"
  echo "check-superpowers-contract: drift no contrato (brainstorming v$ver)"
  exit 1
else
  echo "check-superpowers-contract: contrato intacto (brainstorming v$ver)"
  exit 0
fi
