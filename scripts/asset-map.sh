#!/usr/bin/env bash
# Fonte única do mapeamento: asset canônico → skills que o consomem.
# Sourced por sync-assets.sh, check-assets.sh e .githooks/pre-commit.
# NÃO executar diretamente.
#
# Cada entrada: "CAMINHO_CANONICO_RELATIVO_A_ROOT  skill1 skill2 ..."
# O destino da cópia é: skills/<skill>/references/<basename do canônico>.
ASSET_MAP=(
  "assets/quality-rules.md                prd-discovery prd-spike prd-write prd-decompose prd-constitution-prompt prd-specify-prompt"
  "assets/templates/prd-skeleton.md       prd-write"
  "assets/templates/traceability-table.md prd-decompose"
)
