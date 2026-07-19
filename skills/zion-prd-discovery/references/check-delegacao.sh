#!/usr/bin/env bash
# check-delegacao.sh — verificador do bloco de delegação criativa montado (RF-20).
# Verifica; NÃO bloqueia. Exit 0 = limpo, 1 = achados, 2 = erro de uso/ambiente.
# Quem lê o exit é a fase de delegação (discovery/write/decompose), que aconselha
# (RN-01) e corrige os marcadores ausentes antes de invocar o brainstorming.
#
# Lê o bloco de delegação montado (observações classificadas + a rubrica) e confere que ele PEDE
# a distinção diagnóstica×propositiva — no molde tolerante do contrato C1–C3 (grep de marcadores,
# não diff de frase). NÃO confirma que o agente classificou certo cada tensão, que nada foi
# pré-mastigado, nem que a experiência melhorou — isso segue julgamento (ver o limite honesto no
# ADR-017 / design). Fonte única da rubrica: assets/delegacao-criativa.md.
#
# Uso:
#   check-delegacao.sh <arquivo|->    # "-" lê o bloco do stdin (igual ao check-prd.sh specify)
set -u

usage() { echo "uso: check-delegacao.sh <arquivo|->" >&2; exit 2; }

target="${1:-}"
[ -n "$target" ] || usage

# Normaliza o alvo: stdin ("-") vira um arquivo temporário; arquivo real precisa existir.
TMPIN=""
cleanup() { [ -n "$TMPIN" ] && rm -f "$TMPIN"; }
trap cleanup EXIT
if [ "$target" = "-" ]; then
  TMPIN="$(mktemp)"; cat > "$TMPIN"; SRC="$TMPIN"; LABEL="delegacao"
else
  [ -f "$target" ] || { echo "check-delegacao: arquivo não encontrado: $target" >&2; exit 2; }
  SRC="$target"; LABEL="$(basename "$target")"
fi

content="$(cat "$SRC")"
has() { printf '%s' "$content" | grep -qiE -- "$1"; }

findings=""
miss() {  # $1 = achado
  if [ -z "$findings" ]; then findings="$1"; else findings="$findings
$1"; fi
}

# 1. A distinção pedida: diagnóstica ∧ propositiva (tolerante a acento).
{ has 'diagn[óo]stic' && has 'propositiv'; } \
  || miss "$LABEL: distincao-ausente — o bloco não pede a distinção diagnóstica×propositiva (classifique cada tensão)"

# 2. Propositiva → 2–3 abordagens + recomendação explícita.
{ has 'abordagens' && has 'recomenda'; } \
  || miss "$LABEL: propositiva-incompleta — falta \"2–3 abordagens\" e/ou a recomendação explícita da tensão propositiva"

# 3. Os dois previews: preview que ilustra a escolha (liberado) ∧ tela (proibida → plan.md).
{ has 'ilustra' && has 'tela' && has 'plan\.md|proib|banid'; } \
  || miss "$LABEL: previews-ausente — falta a regra dos dois previews (ilustrar a escolha liberado ∧ desenhar tela vai para o plan.md)"

# 4. Condução: uma pergunta / passo a passo / tarefa por passo (satisfaz com QUALQUER um).
has 'uma pergunta|passo a passo|tarefa por passo' \
  || miss "$LABEL: conducao-ausente — o bloco não instrui a condução (uma pergunta por vez / passo a passo / uma tarefa por passo)"

if [ -n "$findings" ]; then
  printf '%s\n' "$findings"
  count="$(printf '%s\n' "$findings" | grep -c .)"
  echo "check-delegacao: $count achado(s)"
  exit 1
else
  echo "check-delegacao: limpo"
  exit 0
fi
