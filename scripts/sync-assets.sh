#!/usr/bin/env bash
# Copia os assets canônicos de assets/ para o references/ de cada skill que os consome.
# Fonte única de verdade: assets/. Rode este script após editar qualquer asset.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

QR="assets/quality-rules.md"
SKELETON="assets/templates/prd-skeleton.md"
TRACE="assets/templates/traceability-table.md"

# quality-rules.md → todas as skills prd-* que a citam
for s in prd-discovery prd-spike prd-write prd-decompose prd-constitution-prompt prd-specify-prompt; do
  mkdir -p "skills/$s/references"
  cp "$QR" "skills/$s/references/quality-rules.md"
done

# templates específicos por skill
mkdir -p skills/prd-write/references skills/prd-decompose/references
cp "$SKELETON" "skills/prd-write/references/prd-skeleton.md"
cp "$TRACE" "skills/prd-decompose/references/traceability-table.md"

echo "sync-assets: ok"
