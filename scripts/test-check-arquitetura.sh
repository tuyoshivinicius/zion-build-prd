#!/usr/bin/env bash
# Auto-teste do check-arquitetura.sh contra fixtures limpa/suja (NFR-04). Roda pela camada mecânica (scripts/eval.sh).
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
CHECK="scripts/check-arquitetura.sh"
FIX="scripts/fixtures/arquitetura"
fail=0

assert_exit() {  # desc  exit_esperado  exit_veio
  if [ "$2" != "$3" ]; then echo "FALHOU: $1 (exit esperado $2, veio $3)"; fail=1
  else echo "ok: $1"; fi
}
assert_contains() {  # desc  agulha  palheiro
  if printf '%s' "$3" | grep -qi -- "$2"; then echo "ok: $1"
  else echo "FALHOU: $1 (não achou: $2)"; fail=1; fi
}
assert_not_contains() {  # desc  agulha  palheiro
  if printf '%s' "$3" | grep -qi -- "$2"; then echo "FALHOU: $1 (achou indevido: $2)"; fail=1
  else echo "ok: $1"; fi
}

# 1. Fixture limpa → exit 0, sem achados.
out="$(bash "$CHECK" "$FIX/clean")"; rc=$?
assert_exit "clean sai 0" 0 "$rc"
assert_contains "clean reporta limpo" "check-arquitetura: limpo" "$out"
assert_not_contains "clean não acusa defasado" "defasad" "$out"

# 2. Fixture suja → exit 1 com os seis achados (índice defasado nos dois sentidos).
out="$(bash "$CHECK" "$FIX/dirty")"; rc=$?
assert_exit "dirty sai 1" 1 "$rc"
assert_contains "acha secao-ausente" "secao-ausente" "$out"
assert_contains "acha visao-vazia" "visao-vazia" "$out"
assert_contains "acha adr-index-defasado" "adr-index-defasado" "$out"
assert_contains "acha ADR citado mas ausente do disco" "ADR-099-fantasma.md citado no bloco mas ausente" "$out"
assert_contains "acha backlog-view-defasada" "backlog-view-defasada" "$out"
assert_contains "acha regras-defasadas" "regras-defasadas" "$out"

# 3. Repo vazio → arquitetura-ausente + regras-ausentes (e nada de erro).
empty="$(mktemp -d)"
out="$(bash "$CHECK" "$empty")"; rc=$?
assert_exit "repo vazio sai 1" 1 "$rc"
assert_contains "acha arquitetura-ausente" "arquitetura-ausente" "$out"
assert_contains "acha regras-ausentes" "regras-ausentes" "$out"
rmdir "$empty"

# 4. ROOT inexistente → exit 2.
out="$(bash "$CHECK" nao/existe 2>/dev/null)"; rc=$?
assert_exit "ROOT inexistente sai 2" 2 "$rc"

# 5. Índice cita ADR mas docs/adr/ foi deletado por inteiro → o guard não engole a citação fantasma.
semadr="$(mktemp -d)"; mkdir -p "$semadr/docs"
cp "$FIX/clean/CLAUDE.md" "$semadr/CLAUDE.md"
cp "$FIX/clean/docs/architecture.md" "$semadr/docs/architecture.md"
cp "$FIX/clean/docs/backlog.md" "$semadr/docs/backlog.md"
out="$(bash "$CHECK" "$semadr")"; rc=$?
assert_exit "docs/adr ausente com citação sai 1" 1 "$rc"
assert_contains "acusa citado mas ausente sem docs/adr" "citado no bloco mas ausente" "$out"
rm -rf "$semadr"

# 6. ADR substituído no disco não é cobrado como ausente do bloco (o mapa é o vigente).
sup="$(mktemp -d)"; mkdir -p "$sup/docs/adr"
cp "$FIX/clean/CLAUDE.md" "$sup/CLAUDE.md"
cp "$FIX/clean/docs/architecture.md" "$sup/docs/architecture.md"
cp "$FIX/clean/docs/backlog.md" "$sup/docs/backlog.md"
cp "$FIX/clean/docs/adr/ADR-001-banco-unico.md" "$sup/docs/adr/"
cat > "$sup/docs/adr/ADR-009-aposentado.md" <<'EOF'
# ADR-009 — Aposentado

- **Status:** Substituído por ADR-001
- **Área:** Persistência
- **Data:** 2026-07-20
- **Evidência:** Decisão dada: racional registrado (fixture).

## Decisão

Decisão aposentada.
EOF
out="$(bash "$CHECK" "$sup")"; rc=$?
assert_exit "ADR substituído fora do bloco não acusa" 0 "$rc"
assert_not_contains "não acusa o substituído como defasado" "ADR-009" "$out"
rm -rf "$sup"

if [ "$fail" -eq 0 ]; then echo "test-check-arquitetura: tudo verde"; else echo "test-check-arquitetura: FALHOU"; exit 1; fi
