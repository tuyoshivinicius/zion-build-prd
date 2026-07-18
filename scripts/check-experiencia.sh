#!/usr/bin/env bash
# check-experiencia.sh — verificador do carregador de experiência (A2 / RF-11).
# Verifica; NÃO bloqueia. Exit 0 = limpo, 1 = achados, 2 = erro de uso/ambiente.
# Lido pela Fase 4 de /zion-prd-write (só PRD → só limb-PRD) e de /zion-prd-decompose
# (PRD + backlog → ambos os limbs), que aconselham (não revertem — RN-01, ADR-004).
#
# Uso:
#   check-experiencia.sh <PRD> [backlog]
#
# Gate: "Superfície de uso: sim" na §7 da PRD. Ausente ou "não" → produto sem
# superfície de uso: nada a cobrar (exit 0). Só com surface=sim há achados:
#   - limb-PRD     — nenhum NFR tagueado "(experiência)" na PRD (fora de blockquote).
#   - limb-backlog — (só com arg backlog) nenhuma linha do backlog com a coluna
#                    "Âncora de experiência" preenchida.
# Verifica PRESENÇA da âncora, não vazamento visual (isso continua julgamento humano).
set -u

usage() { echo "uso: check-experiencia.sh <PRD> [backlog]" >&2; exit 2; }

prd="${1:-}"
backlog="${2:-}"
[ -n "$prd" ] || usage
case "$prd" in -*) usage ;; esac
[ -f "$prd" ] || { echo "check-experiencia: arquivo não encontrado: $prd" >&2; exit 2; }
if [ -n "$backlog" ]; then
  [ -f "$backlog" ] || { echo "check-experiencia: backlog não encontrado: $backlog" >&2; exit 2; }
fi

PRD_LABEL="$(basename "$prd")"
BACKLOG_LABEL="$(basename "${backlog:-backlog.md}")"

# Valor do marcador "Superfície de uso: <valor>" (primeira ocorrência, minúsculo).
surface_value() {
  awk '
    /Superfície de uso:/ {
      v=$0
      sub(/^.*Superfície de uso:[[:space:]]*/,"",v)
      sub(/[[:space:]]+$/,"",v)
      print tolower(v)
      exit
    }
  ' "$prd"
}

# Há um NFR tagueado "(experiência)" fora de blockquote? (a guia do template mora em
# blockquote ">"; a âncora real é uma linha de NFR — bullet. Excluir ">" evita
# falso-negativo por boilerplate deixado no lugar.)
has_exp_nfr() {  # exit 0 se há, 1 se não
  awk '/\(experiência\)/ && $0 !~ /^[[:space:]]*>/ { found=1 } END { exit(found?0:1) }' "$prd"
}

# A coluna "Âncora de experiência" da primeira tabela do backlog tem ≥1 célula
# preenchida? Preenchida = conteúdo real (não vazia, não "—", não placeholder _..._).
backlog_anchor_filled() {  # $1 backlog -> exit 0 se preenchida, 1 se não
  awk '
    function trim(s){ gsub(/^[[:space:]]+|[[:space:]]+$/,"",s); return s }
    !colidx && /\|/ && /Âncora de experiência/ {
      n=split($0, c, /\|/)
      for (i=1;i<=n;i++) if (trim(c[i])=="Âncora de experiência") colidx=i
      if (colidx) next
    }
    colidx && /^[[:space:]]*\|[[:space:]]*[-:]/ { next }      # separador |---|
    colidx && /\|/ {
      n=split($0, c, /\|/)
      cell=trim(c[colidx])
      if (cell!="" && cell!="—" && cell !~ /^_.*_$/) found=1
      next
    }
    colidx && !/\|/ { exit }                                  # 1ª linha fora da tabela encerra
    END { exit(found?0:1) }
  ' "$1"
}

surface="$(surface_value)"
case "$surface" in
  sim) ;;
  *) echo "check-experiencia: limpo"; exit 0 ;;
esac

findings=""
add() {  # $1 achado
  if [ -z "$findings" ]; then findings="$1"; else findings="$findings
$1"; fi
}

# limb-PRD: surface=sim ∧ nenhum NFR tagueado "(experiência)".
has_exp_nfr \
  || add "$PRD_LABEL: limb-PRD — produto com superfície de uso mas nenhum NFR tagueado \"(experiência)\" na §7"

# limb-backlog: só quando o backlog é passado.
if [ -n "$backlog" ]; then
  backlog_anchor_filled "$backlog" \
    || add "$BACKLOG_LABEL: limb-backlog — produto com superfície de uso mas nenhuma spec com a coluna \"Âncora de experiência\" preenchida"
fi

if [ -n "$findings" ]; then
  printf '%s\n' "$findings"
  count="$(printf '%s\n' "$findings" | grep -c .)"
  echo "check-experiencia: $count achado(s)"
  exit 1
else
  echo "check-experiencia: limpo"
  exit 0
fi
