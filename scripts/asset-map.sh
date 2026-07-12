#!/usr/bin/env bash
# Fonte única do mapeamento: asset canônico → skills que o consomem.
# Sourced por sync-assets.sh, check-assets.sh e .githooks/pre-commit.
# NÃO executar diretamente.
#
# Cada entrada: "CAMINHO_CANONICO_RELATIVO_A_ROOT  skill1 skill2 ..."
# O destino da cópia é: skills/<skill>/references/<basename do canônico>.
ASSET_MAP=(
  "assets/quality-rules.md                zion-prd-discovery zion-prd-spike zion-prd-write zion-prd-decompose zion-prd-constitution-prompt zion-prd-specify-prompt"
  "assets/templates/prd-skeleton.md       zion-prd-write"
  "assets/templates/traceability-table.md zion-prd-decompose"
  "assets/process-context.md              zion-prd-discovery zion-prd-spike zion-prd-write zion-prd-decompose zion-adr-new"
)
