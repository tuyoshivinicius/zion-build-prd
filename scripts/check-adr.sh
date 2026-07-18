#!/usr/bin/env bash
# check-adr.sh — verificador de presença de evidência nos ADRs (R3).
# Verifica a PRESENÇA do lastro (não a qualidade), no mesmo molde de
# check-prd.sh (R1) e trace-prd.sh (R2): o script verifica, o humano decide.
# Exit 0 = limpo · 1 = achados · 2 = erro de uso/ambiente.
# Lido pela Fase 4 de /zion-prd-spike, que aconselha (não bloqueia).
#
# Uso:
#   check-adr.sh <dir-de-adrs>     # ex.: check-adr.sh docs/adr
#
# Para cada <dir>/ADR-*.md (glob de filhos diretos → ignora spikes/):
#   1. sem linha **Evidência:** preenchida (vazia ou placeholder <…>) → sem-evidencia
#   2. Evidência "Decisão dada: <racional>" com racional vazio/placeholder → decisao-dada-sem-racional
#   3. Evidência aponta docs/adr/spikes/<seg>/ (risco de execução):
#        <dir>/spikes/<seg> ausente        → spike-dir-ausente
#        <dir>/spikes/<seg> vazio          → spike-dir-vazio
#        <dir>/spikes/<seg> sem README.md  → spike-sem-readme
#   4. Evidência de conhecimento sem URL nem caminho → evidencia-sem-lastro
set -u

usage() { echo "uso: check-adr.sh <dir-de-adrs>" >&2; exit 2; }

DIR="${1:-}"
[ -n "$DIR" ] || usage
case "$DIR" in -*) usage ;; esac
[ -d "$DIR" ] || { echo "check-adr: diretório não encontrado: $DIR" >&2; exit 2; }

# Valor da primeira linha `- **Evidência:**`, sem o rótulo. Casa bytes literais
# (a acentuação de "Evidência" é UTF-8 fixa no template e nas fixtures).
evidence_value() {  # $1 arquivo
  sed -n 's/^[[:space:]]*-[[:space:]]*\*\*Evidência:\*\*[[:space:]]*//p' "$1" | head -1
}

# --- R8: supersessão (referência simétrica Substitui / Status: Substituído por) ---
adr_file_for() {  # $1 id (ADR-002) -> caminho do arquivo em $DIR, ou vazio
  local m; m="$(ls "$DIR/$1-"*.md 2>/dev/null | head -1)"; [ -n "$m" ] && printf '%s' "$m"
}
field_substitui() {  # $1 arquivo -> ADR-<n> que declara substituir (maiúsculo), ou vazio
  sed -n 's/^[[:space:]]*-[[:space:]]*\*\*Substitui:\*\*[[:space:]]*//p' "$1" \
    | grep -oiE 'ADR-[0-9]+' | head -1 | tr '[:lower:]' '[:upper:]'
}
status_superseded_by() {  # $1 arquivo -> ADR-<m> pelo qual foi substituído, ou vazio
  local st; st="$(sed -n 's/^[[:space:]]*-[[:space:]]*\*\*Status:\*\*[[:space:]]*//p' "$1" | head -1)"
  printf '%s' "$st" | grep -qiE 'Substitu[ií]do por' || return 0
  printf '%s' "$st" | grep -oiE 'ADR-[0-9]+' | head -1 | tr '[:lower:]' '[:upper:]'
}

findings=""
add() {  # $1 achado
  if [ -z "$findings" ]; then findings="$1"; else findings="$findings
$1"; fi
}

nadr=0
for f in "$DIR"/ADR-*.md; do
  [ -f "$f" ] || continue
  nadr=$((nadr+1))
  label="$(basename "$f")"
  ev="$(evidence_value "$f")"
  ev="$(printf '%s' "$ev" | sed 's/[[:space:]]*$//')"   # trim à direita

  # Vazia ou placeholder <…> → sem evidência.
  if [ -z "$ev" ] || printf '%s' "$ev" | grep -qE '^<.*>$'; then
    add "$label: sem-evidencia — nenhuma linha **Evidência:** preenchida (aponte o spike dir ou a fonte de pesquisa)"
    continue
  fi

  # Decisão dada: o lastro é o racional escrito no próprio ADR (quem/que autoridade decidiu e por
  # quê). Casa ANTES dos ramos de spike/conhecimento para que um racional em prosa não seja
  # mal-acusado como evidencia-sem-lastro. O rótulo "Decisão dada" é bytes UTF-8 fixos do template.
  if printf '%s' "$ev" | grep -qiE '^decisão dada[[:space:]]*:'; then
    rac="$(printf '%s' "$ev" | sed 's/^[^:]*:[[:space:]]*//')"
    rac="$(printf '%s' "$rac" | sed 's/[[:space:]]*$//')"
    if [ -z "$rac" ] || printf '%s' "$rac" | grep -qE '^<.*>$'; then
      add "$label: decisao-dada-sem-racional — marcador \"Decisão dada:\" sem racional (aponte a autoridade/racional — quem decidiu e por quê)"
    fi
    continue
  fi

  case "$ev" in
    *docs/adr/spikes/*)
      # Risco de execução. Ignora o prefixo citado; resolve <dir>/spikes/<seg>.
      seg="$(printf '%s' "$ev" | grep -oE 'docs/adr/spikes/[^[:space:])]+' | head -1 | sed 's#^docs/adr/spikes/##; s#/*$##')"
      target="$DIR/spikes/$seg"
      if [ ! -d "$target" ]; then
        add "$label: spike-dir-ausente — $ev não existe (crie o spike dir ou corrija o caminho)"
      elif [ -z "$(ls -A "$target" 2>/dev/null)" ]; then
        add "$label: spike-dir-vazio — $target sem artefatos (adicione o spike + README.md)"
      elif [ ! -f "$target/README.md" ]; then
        add "$label: spike-sem-readme — $target sem README.md (documente pergunta/execução/veredito)"
      fi
      ;;
    *)
      # Risco de conhecimento: precisa de URL (http…) ou de um caminho de artefato.
      if ! printf '%s' "$ev" | grep -qE 'https?://|/|\.[A-Za-z0-9]+'; then
        add "$label: evidencia-sem-lastro — \"$ev\" sem URL nem caminho de artefato (aponte a fonte)"
      fi
      ;;
  esac
done

# Simetria da supersessão: cada elo Substitui / Status-substituído-por exige o par recíproco.
for f in "$DIR"/ADR-*.md; do
  [ -f "$f" ] || continue
  id="$(basename "$f" | grep -oE '^ADR-[0-9]+')"
  label="$(basename "$f")"
  sub="$(field_substitui "$f")"
  if [ -n "$sub" ]; then
    tf="$(adr_file_for "$sub")"
    if [ -z "$tf" ]; then
      add "$label: supersessao-assimetrica — declara Substitui: $sub, mas $sub não existe em $DIR"
    else
      back="$(status_superseded_by "$tf")"
      [ "$back" = "$id" ] || add "$label: supersessao-assimetrica — Substitui: $sub, mas $sub não tem Status \"Substituído por $id\" (unilateral)"
    fi
  fi
  supby="$(status_superseded_by "$f")"
  if [ -n "$supby" ]; then
    tf="$(adr_file_for "$supby")"
    if [ -z "$tf" ]; then
      add "$label: supersessao-assimetrica — Status aponta $supby, mas $supby não existe em $DIR"
    else
      fwd="$(field_substitui "$tf")"
      [ "$fwd" = "$id" ] || add "$label: supersessao-assimetrica — Status: Substituído por $supby, mas $supby não declara Substitui: $id (unilateral)"
    fi
  fi
done

if [ "$nadr" -eq 0 ]; then
  echo "check-adr: nenhum ADR-*.md em $DIR" >&2
  exit 2
fi

if [ -n "$findings" ]; then
  printf '%s\n' "$findings"
  count="$(printf '%s\n' "$findings" | grep -c .)"
  echo "check-adr: $count achado(s)"
  exit 1
else
  echo "check-adr: limpo"
  exit 0
fi
