#!/usr/bin/env bash
# Fonte única do mapeamento: asset canônico → skills que o consomem.
# Sourced por sync-assets.sh, check-assets.sh e .githooks/pre-commit.
# NÃO executar diretamente.
#
# Cada entrada: "CAMINHO_CANONICO_RELATIVO_A_ROOT  skill1 skill2 ..."
# O destino da cópia é: skills/<skill>/references/<basename do canônico>.
ASSET_MAP=(
  "assets/quality-rules.md                zion-prd-discovery zion-prd-spike zion-prd-write zion-prd-decompose zion-prd-constitution-prompt zion-prd-specify-prompt zion-prd-plan-prompt zion-prd-evolve"
  "assets/templates/prd-skeleton.md       zion-prd-write"
  "assets/templates/traceability-table.md zion-prd-decompose"
  "assets/process-context.md              zion-prd-discovery zion-prd-spike zion-prd-write zion-prd-decompose zion-adr-new zion-prd-evolve"
  "assets/superpowers-contract.md         zion-prd-discovery zion-prd-write zion-prd-decompose"
  "scripts/check-prd.sh                   zion-prd-write zion-prd-specify-prompt zion-prd-evolve"
  "scripts/trace-prd.sh                   zion-prd-trace zion-prd-decompose"
  "scripts/trace-backlog.sh               zion-prd-trace zion-prd-decompose"
  "assets/templates/backlog.md            zion-prd-decompose"
  "scripts/check-adr.sh                   zion-prd-spike zion-prd-evolve"
)
