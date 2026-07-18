#!/usr/bin/env bash
# check-canon.sh — guard de canonização do próprio repo (RF-13 / D-10).
# Cruza as fontes da verdade (docs/prd.md, docs/architecture.md, CLAUDE.md) com a
# implementação (skills/, scripts/, ASSET_MAP, docs/adr/). Presença/estrutura por
# máquina; a qualidade do texto é dever de quem edita (CLAUDE.md).
# Diferente dos verificadores dos projetos-alvo (aconselham), este BLOQUEIA:
# roda no .githooks/pre-commit e no CI. Exit 0 = limpo · 1 = achados · 2 = uso.
#
# Uso:
#   check-canon.sh [ROOT]   # default: raiz do repo (testável com fixtures)
set -u

usage() { echo "uso: check-canon.sh [ROOT]" >&2; exit 2; }

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="${1:-$(cd "$SCRIPT_DIR/.." && pwd)}"
case "$ROOT" in -*) usage ;; esac
[ -d "$ROOT" ] || { echo "check-canon: diretório não encontrado: $ROOT" >&2; exit 2; }

PRD="$ROOT/docs/prd.md"
ARCH="$ROOT/docs/architecture.md"
RULES="$ROOT/CLAUDE.md"

# As fontes da verdade existem?
check_docs_exist() {
  [ -f "$PRD" ]  || printf 'docs/prd.md: canon-ausente — fonte da verdade de requisitos não existe\n'
  [ -f "$ARCH" ] || printf 'docs/architecture.md: canon-ausente — fonte da verdade de arquitetura não existe\n'
}

# C1: todo dir de skills/ citado na prd.md.
check_skills_prd() {
  [ -d "$ROOT/skills" ] && [ -f "$PRD" ] || return 0
  local d name
  for d in "$ROOT"/skills/*/; do
    [ -d "$d" ] || continue
    name="$(basename "$d")"
    grep -qF "$name" "$PRD" \
      || printf 'skills/%s: skill-sem-rf — não citada em docs/prd.md (dê um RF na §6 e uma linha na §12)\n' "$name"
  done
}

# C2: todo skills/<nome> citado na prd.md existe no disco.
check_prd_skills_exist() {
  [ -f "$PRD" ] || return 0
  local ref
  grep -oE 'skills/[a-z0-9-]+' "$PRD" | sort -u | while read -r ref; do
    [ -d "$ROOT/$ref" ] \
      || printf 'docs/prd.md: skill-fantasma — "%s" citada mas não existe no disco\n' "$ref"
  done
}

# C3: todo scripts/*.sh (top-level) citado no architecture.md.
check_scripts_doc() {
  [ -d "$ROOT/scripts" ] && [ -f "$ARCH" ] || return 0
  local f base
  for f in "$ROOT"/scripts/*.sh; do
    [ -f "$f" ] || continue
    base="$(basename "$f")"
    grep -qF "$base" "$ARCH" \
      || printf 'scripts/%s: script-sem-doc — não citado em docs/architecture.md (tabela de scripts)\n' "$base"
  done
}

# C4: toda fonte assets/ do ASSET_MAP citada no architecture.md (scripts/ já cobertos por C3).
check_assets_doc() {
  local map="$ROOT/scripts/asset-map.sh" entry src
  [ -f "$map" ] && [ -f "$ARCH" ] || return 0
  ASSET_MAP=()
  # shellcheck disable=SC1090
  source "$map"
  for entry in "${ASSET_MAP[@]}"; do
    read -r src _ <<< "$entry"
    case "$src" in assets/*) ;; *) continue ;; esac
    grep -qF "$src" "$ARCH" \
      || printf '%s: asset-sem-doc — fonte do ASSET_MAP não citada em docs/architecture.md\n' "$src"
  done
}

# C5: todo docs/adr/ADR-*.md citado no architecture.md (índice).
check_adr_index() {
  [ -d "$ROOT/docs/adr" ] && [ -f "$ARCH" ] || return 0
  local af base
  for af in "$ROOT"/docs/adr/ADR-*.md; do
    [ -f "$af" ] || continue
    base="$(basename "$af")"
    grep -qF "$base" "$ARCH" \
      || printf 'docs/adr/%s: adr-sem-indice — não citado no índice de docs/architecture.md\n' "$base"
  done
}

# C6: CLAUDE.md existe e cita as duas fontes da verdade.
check_root_rules() {
  if [ ! -f "$RULES" ]; then
    printf 'CLAUDE.md: regra-raiz-sem-sot — arquivo de regras ausente na raiz\n'
    return 0
  fi
  grep -qF 'docs/prd.md' "$RULES" \
    || printf 'CLAUDE.md: regra-raiz-sem-sot — não cita docs/prd.md\n'
  grep -qF 'docs/architecture.md' "$RULES" \
    || printf 'CLAUDE.md: regra-raiz-sem-sot — não cita docs/architecture.md\n'
}

# C7 (dogfood): a própria PRD passa no check-prd.sh do harness.
check_prd_dogfood() {
  [ -f "$PRD" ] || return 0
  local out rc
  out="$(bash "$SCRIPT_DIR/check-prd.sh" prd "$PRD")"; rc=$?
  [ "$rc" -eq 1 ] && printf '%s\n' "$out" | grep -v '^check-prd:'
  return 0
}

findings="$(
  check_docs_exist
  check_skills_prd
  check_prd_skills_exist
  check_scripts_doc
  check_assets_doc
  check_adr_index
  check_root_rules
  check_prd_dogfood
)"

if [ -n "$findings" ]; then
  printf '%s\n' "$findings"
  count="$(printf '%s\n' "$findings" | grep -c .)"
  echo "check-canon: $count achado(s) — canonize (veja CLAUDE.md) e tente de novo"
  exit 1
else
  echo "check-canon: limpo"
  exit 0
fi
