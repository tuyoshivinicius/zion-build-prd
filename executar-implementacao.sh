#!/usr/bin/env bash
# Inicia a implementação do harness PRD -> Spec Kit numa sessão do Claude Code.
# Uso:
#   ./executar-implementacao.sh          # roda em master
#   ./executar-implementacao.sh --branch # cria o branch feat/harness-prd antes
set -e
cd /home/tuyoshi/projects/personal/zion-mermaid-editor

if [ "$1" = "--branch" ]; then
  git switch -c feat/harness-prd
fi

claude "Execute o plano em docs/superpowers/plans/2026-07-11-harness-prd-spec-kit.md usando a skill superpowers:executing-plans. Rode as 9 tasks em ordem, com checkpoint para eu revisar entre os lotes. Spec de referência: docs/superpowers/specs/2026-07-11-harness-prd-spec-kit-design.md"
