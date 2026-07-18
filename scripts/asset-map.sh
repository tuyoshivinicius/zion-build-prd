#!/usr/bin/env bash
# Fonte única do mapeamento: asset canônico → skills que o consomem.
# Sourced por sync-assets.sh, check-assets.sh e .githooks/pre-commit.
# NÃO executar diretamente.
#
# Cada entrada: "CAMINHO_CANONICO_RELATIVO_A_ROOT  skill1 skill2 ..."
# O destino da cópia é: skills/<skill>/references/<basename do canônico>.
ASSET_MAP=(
  "assets/quality-rules.md                zion-prd-discovery zion-prd-spike zion-prd-write zion-prd-decompose zion-prd-constitution-prompt zion-prd-specify-prompt zion-prd-plan-prompt zion-prd-evolve zion-prd-estudo"
  "assets/templates/prd-skeleton.md       zion-prd-write"
  "assets/templates/traceability-table.md zion-prd-decompose"
  "assets/process-context.md              zion-prd-discovery zion-prd-spike zion-prd-write zion-prd-decompose zion-adr-new zion-prd-evolve zion-prd-estudo"
  "assets/superpowers-contract.md         zion-prd-discovery zion-prd-write zion-prd-decompose zion-prd-estudo"
  "scripts/check-prd.sh                   zion-prd-write zion-prd-specify-prompt zion-prd-evolve"
  "scripts/trace-prd.sh                   zion-prd-trace zion-prd-decompose"
  "scripts/trace-backlog.sh               zion-prd-trace zion-prd-decompose"
  "assets/templates/backlog.md            zion-prd-decompose"
  "scripts/check-adr.sh                   zion-prd-spike zion-prd-evolve"
  "scripts/check-estudo.sh                zion-prd-estudo"
  "scripts/check-experiencia.sh           zion-prd-write zion-prd-decompose"
  "assets/templates/regras-speckit.md        zion-speckit-install"
  "assets/templates/architecture-skeleton.md zion-speckit-install"
  "scripts/check-arquitetura.sh              zion-speckit-install zion-prd-trace"
  "scripts/trace-arquitetura.sh              zion-speckit-install zion-prd-trace"
)
