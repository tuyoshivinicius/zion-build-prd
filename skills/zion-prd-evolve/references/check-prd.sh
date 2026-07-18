#!/usr/bin/env bash
# check-prd.sh — verificador mecânico das regras decidíveis do harness (R1).
# Verifica; NÃO bloqueia. Exit 0 = limpo, 1 = achados, 2 = erro de uso/ambiente.
# Quem lê o exit é a Fase 4, que aconselha (não reverte).
#
# Uso:
#   check-prd.sh prd     <arquivo>    # stack + nfr-sem-numero + rf-fora-de-epico
#   check-prd.sh specify <arquivo|->  # stack + rf-cobertos-ausente (prompt do specify; - lê do stdin)
#
# Denylist: bloco ```denylist do quality-rules.md ao lado do script (references/)
# ou, no repo, em ../assets/quality-rules.md.
set -u

usage() { echo "uso: check-prd.sh <prd|specify> <arquivo|->" >&2; exit 2; }

mode="${1:-}"; target="${2:-}"
[ -n "$mode" ] && [ -n "$target" ] || usage
case "$mode" in prd|specify) ;; *) usage ;; esac

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -f "$SCRIPT_DIR/quality-rules.md" ]; then
  QR="$SCRIPT_DIR/quality-rules.md"                 # caso references/
elif [ -f "$SCRIPT_DIR/../assets/quality-rules.md" ]; then
  QR="$SCRIPT_DIR/../assets/quality-rules.md"       # caso repo
else
  echo "check-prd: quality-rules.md não encontrado (denylist indisponível)" >&2
  exit 2
fi

# Normaliza o alvo para um arquivo real (com line numbers) + rótulo de exibição.
TMPIN=""
cleanup() { [ -n "$TMPIN" ] && rm -f "$TMPIN"; }
trap cleanup EXIT
if [ "$target" = "-" ]; then
  TMPIN="$(mktemp)"; cat > "$TMPIN"; SRC="$TMPIN"; LABEL="specify"
else
  [ -f "$target" ] || { echo "check-prd: arquivo não encontrado: $target" >&2; exit 2; }
  SRC="$target"; LABEL="$(basename "$target")"
fi

# --- R8: descobre os ADRs vizinhos da PRD (docs/adr/ ao lado do arquivo) para os checks §13/§8. ---
# Só para arquivo real (não stdin); degrada em silêncio se docs/adr/ não existir.
ADR_DIR="$(dirname "$SRC")/adr"
adr_ids=""; superseded_ids=""
if [ "$target" != "-" ] && [ -d "$ADR_DIR" ]; then
  for af in "$ADR_DIR"/ADR-*.md; do
    [ -f "$af" ] || continue
    aid="$(basename "$af" | grep -oE '^ADR-[0-9]+')"
    [ -n "$aid" ] || continue
    adr_ids="$adr_ids $aid"
    ast="$(sed -n 's/^[[:space:]]*-[[:space:]]*\*\*Status:\*\*[[:space:]]*//p' "$af" | head -1)"
    if printf '%s' "$ast" | grep -qiE 'Substitu[ií]do por[[:space:]]+ADR-[0-9]+'; then
      superseded_ids="$superseded_ids $aid"
    fi
  done
fi

# --- checks (preenchidos nas próximas tasks) ---
# Extrai os termos do bloco ```denylist do quality-rules.md (um por linha, minúsculo).
extract_denylist() {
  awk '
    /^```denylist[[:space:]]*$/ { inblock=1; next }
    inblock && /^```/           { inblock=0; next }
    inblock && NF               { print tolower($0) }
  ' "$QR"
}

check_stack() {
  local denyfile; denyfile="$(mktemp)"
  extract_denylist > "$denyfile"

  # Denylist: palavra inteira, case-insensitive; -o imprime o termo casado, -n a linha.
  if [ -s "$denyfile" ]; then
    grep -niwoF -f "$denyfile" "$SRC" 2>/dev/null | while IFS=: read -r n term; do
      printf '%s:%s: stack — "%s" (mova para o plan.md da feature)\n' "$LABEL" "$n" "$term"
    done
  fi
  rm -f "$denyfile"

  # Sinais estruturais de alta precisão.
  grep -niEo 'npm install|pip install|yarn add' "$SRC" 2>/dev/null | while IFS=: read -r n m; do
    printf '%s:%s: stack — "%s" (comando de instalação; vai no plan.md)\n' "$LABEL" "$n" "$m"
  done
  grep -nE '^[[:space:]]*(import |from [^ ]+ import )' "$SRC" 2>/dev/null | while IFS=: read -r n rest; do
    printf '%s:%s: stack — "%s" (código; vai no plan.md)\n' "$LABEL" "$n" "$(printf '%s' "$rest" | sed 's/^[[:space:]]*//')"
  done
  grep -nE '^[[:space:]]*```' "$SRC" 2>/dev/null | while IFS=: read -r n _; do
    printf '%s:%s: stack — "bloco de código" (detalhe técnico; vai no plan.md)\n' "$LABEL" "$n"
  done
  grep -niEo '[A-Za-z][A-Za-z0-9._-]*[[:space:]]+v?[0-9]+\.[0-9]+\.[0-9]+' "$SRC" 2>/dev/null | while IFS=: read -r n m; do
    printf '%s:%s: stack — "%s" (versão de dependência; vai no plan.md)\n' "$LABEL" "$n" "$m"
  done
}
# O prompt do specify deve pedir a linha **RF cobertos:** (elo forward RF↔spec).
# Simétrica ao check_stack, mas só no modo specify. Grepa o MESMO padrão do trace-prd.sh.
# Como é uma *ausência*, não há linha para ancorar → achado sem número de linha.
# Gatilho: só o pedido do rótulo — NÃO um RF-xx concreto (o skeleton declara "(nenhum)").
check_rf_cobertos() {
  if ! grep -iqE 'RF cobertos:' "$SRC" 2>/dev/null; then
    printf '%s: rf-cobertos-ausente — o prompt não pede a linha **RF cobertos:** (elo forward RF↔spec; veja quality-rules #anatomia-specify)\n' "$LABEL"
  fi
}
# Seção 7: item de NFR (bullet ou id NFR-) sem nenhum dígito → achado.
check_nfr() {
  awk -v label="$LABEL" '
    /^## / { n=$2; sub(/\./,"",n); sect=(n=="7"); next }
    sect && /^[[:space:]]*([-*]|NFR-)/ && $0 !~ /[0-9]/ {
      line=$0
      sub(/^[[:space:]]*[-*][[:space:]]*/,"",line)
      printf "%s:%d: nfr-sem-numero — \"%s\" (dê um número)\n", label, NR, line
    }
  ' "$SRC"
}
# Seção 6: RF-xx antes do primeiro "Épico E#" → solto. Fora da seção 6: RF-xx
# em bullet não-tabela → definição fora do lugar. (match 2-arg = POSIX, portável.)
check_rf() {
  awk -v label="$LABEL" '
    /^## / { n=$2; sub(/\./,"",n); sect=n; if (n=="6") epic=0; next }
    {
      if (sect=="6" && $0 ~ /pico[[:space:]]+[Ee][0-9]/) epic=1
      if ($0 ~ /RF-[0-9]+/) {
        match($0, /RF-[0-9]+/); rf=substr($0, RSTART, RLENGTH)
        if (sect=="6") {
          if (epic==0)
            printf "%s:%d: rf-fora-de-epico — \"%s\" (agrupe sob um Épico E#)\n", label, NR, rf
        } else if ($0 ~ /^[[:space:]]*[-*]/ && $0 !~ /^[[:space:]]*\|/) {
          printf "%s:%d: rf-fora-de-epico — \"%s\" (definido fora da seção 6)\n", label, NR, rf
        }
      }
    }
  ' "$SRC"
}
# Seção 13 (changelog): cada linha de dados da tabela — Cenário ∈ {C1,C2,C3}; todo RF-xx citado existe
# na §6 (ou a linha diz "removido"); todo ADR-xxx citado existe em docs/adr/ (só quando a lista foi
# descoberta). §13 ausente → nada dispara (compatível com PRDs pré-R8 / dia 1).
check_changelog() {
  awk -v label="$LABEL" -v adrs="$adr_ids" '
    BEGIN { na=split(adrs,aa,/[[:space:]]+/); for(i=1;i<=na;i++) if(aa[i]!="") have_adr[aa[i]]=1 }
    /^## / { sec=$2; sub(/\./,"",sec); next }
    sec=="6" {
      t=$0; while (match(t,/RF-[0-9]+/)) { have_rf[substr(t,RSTART,RLENGTH)]=1; t=substr(t,RSTART+RLENGTH) }
      next
    }
    sec=="13" {
      if ($0 !~ /^[[:space:]]*\|/) next
      bar=$0; gsub(/[[:space:]]/,"",bar); if (bar ~ /^\|(:?-+:?\|)+$/) next
      split($0,col,/\|/); cen=col[3]; gsub(/^[[:space:]]+|[[:space:]]+$/,"",cen)
      if (cen=="Cenário" || col[2] ~ /^[[:space:]]*Data[[:space:]]*$/) next
      if (cen !~ /^C[123]$/)
        printf "%s:%d: changelog-cenario-invalido — \"%s\" (use só C1/C2/C3)\n", label, NR, cen
      removido = ($0 ~ /removido/)
      t=$0; while (match(t,/RF-[0-9]+/)) { rf=substr(t,RSTART,RLENGTH); t=substr(t,RSTART+RLENGTH)
        if (!(rf in have_rf) && !removido)
          printf "%s:%d: changelog-rf-inexistente — \"%s\" não existe na §6 (ou declare \"removido\")\n", label, NR, rf }
      if (adrs != "") { t=$0; while (match(t,/ADR-[0-9]+/)) { adr=substr(t,RSTART,RLENGTH); t=substr(t,RSTART+RLENGTH)
        if (!(adr in have_adr))
          printf "%s:%d: changelog-adr-inexistente — \"%s\" não existe em docs/adr/\n", label, NR, adr } }
    }
  ' "$SRC"
}
# Seção 8: restrição apontando um ADR já substituído (Status: Substituído por) → restrição morta.
check_restricao_morta() {
  awk -v label="$LABEL" -v sup="$superseded_ids" '
    BEGIN { ns=split(sup,ss,/[[:space:]]+/); for(i=1;i<=ns;i++) if(ss[i]!="") is_sup[ss[i]]=1 }
    /^## / { sec=$2; sub(/\./,"",sec); next }
    sec=="8" {
      t=$0; while (match(t,/ADR-[0-9]+/)) { adr=substr(t,RSTART,RLENGTH); t=substr(t,RSTART+RLENGTH)
        if (adr in is_sup)
          printf "%s:%d: restricao-morta — a restrição aponta %s, já substituído (veja o Status do ADR)\n", label, NR, adr }
    }
  ' "$SRC"
}

case "$mode" in
  prd)     findings="$(check_stack; check_nfr; check_rf; check_changelog; check_restricao_morta)" ;;
  specify) findings="$(check_stack; check_rf_cobertos)" ;;
esac

if [ -n "$findings" ]; then
  printf '%s\n' "$findings"
  count="$(printf '%s\n' "$findings" | grep -c .)"
  echo "check-prd: $count achado(s)"
  exit 1
else
  echo "check-prd: limpo"
  exit 0
fi
