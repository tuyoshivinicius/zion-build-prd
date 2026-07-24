#!/usr/bin/env bash
# Harness sem custo do speckit-e2e-loop: um repo Spec Kit falso, um stub
# determinístico de `claude` roteirizado por passo, e um stub de
# speckit-clarify-loop — exercita a máquina inteira (preflight, file-drop,
# máquina de estados, parada-por-achado, retomada) sem gastar cota.
#
# Uso:  tools/speckit-e2e-loop-harness.sh [flags do loop…]
#       SKE_SUFFICIENCY=1 …  # a ponte plan-prompt grava SUFFICIENCY_STOP
#       SKE_STACK=1 …        # o prompt do specify vaza stack (React/Postgres)
#       SKE_ANALYZE_CRIT=1 … # o analyze reporta CRITICAL
#       SKE_CLARIFY_RC=1 …   # o stub de clarify sai rc 1
#       SKE_CUT=<n> …        # o stub de claude trava na n-ésima invocação (corte)
#
# Observação: o file-drop das pontes é lido pelo loop em $STATE_DIR/{next,signal}.txt
# (/tmp/speckit-e2e-loop/<slug>/…), então o stub grava EXATAMENTE ali (SKE_NEXT/
# SKE_SIGNAL apontam para lá) — é onde handle_turn_bridge lê. O corte externo
# (SKE_CUT) conta INVOCAÇÕES do claude; o passo clarify delega ao binário irmão e
# NÃO invoca o claude, então não conta.
set -u
ROOT=/tmp/ske-harness
HERE="$(cd "$(dirname "$0")" && pwd)"
LOOP="$HERE/speckit-e2e-loop"
REPO="$ROOT/repo"
SLUG=preview
SPECDIR="$REPO/specs/003-preview"
STATE="/tmp/speckit-e2e-loop/$SLUG"     # onde o loop mantém next.txt/signal.txt/state

# Modo retomada: se --from está nos args, NÃO reconstrói o repo nem apaga o estado
# — a retomada precisa que o estado e os artefatos do run anterior sobrevivam. E
# um run parcial deixa a tree suja, então injeta --allow-dirty (o resume real também
# precisa: o design exige tree limpa no arranque).
RESUME=0
case " $* " in *" --from "*) RESUME=1 ;; esac
[ "$RESUME" -eq 1 ] && [ -d "$REPO" ] || RESUME=0   # sem run anterior, reconstrói

if [ "$RESUME" -eq 0 ]; then
  rm -rf "$ROOT"
  mkdir -p "$ROOT/bin" "$REPO/.specify/scripts/bash" "$REPO/docs" "$SPECDIR"

  printf '%s\n' '# Backlog' '' '| slug | demo | RFs |' '|---|---|---|' \
    "| $SLUG | vê o preview | RF-01 |" > "$REPO/docs/backlog.md"

  # check-prerequisites.sh falso: só depois do "passo 2" o spec.md existe. O stub
  # de claude cria specs/003-preview/spec.md; aqui apontamos para ele.
  cat > "$REPO/.specify/scripts/bash/check-prerequisites.sh" <<EOF
#!/usr/bin/env bash
printf '{"FEATURE_SPEC":"%s"}\n' "$SPECDIR/spec.md"
EOF
  chmod +x "$REPO/.specify/scripts/bash/check-prerequisites.sh"

  git -C "$REPO" init -q
  git -C "$REPO" add -A
  git -C "$REPO" -c user.email=h@local -c user.name=h commit -qm 'backlog + specify falso'
  # A branch de feature (cursor compartilhado): o stub não roda git, então criamos aqui.
  git -C "$REPO" checkout -q -b specs/003-preview

  # Stub de `claude`. Lê a 1ª mensagem de usuário do FIFO, descobre qual passo é
  # pela linha do slash command, e emite o roteiro daquele passo — inclusive o
  # file-drop das pontes e a escrita dos artefatos do Spec Kit.
  cat > "$ROOT/bin/claude" <<'STUB'
#!/usr/bin/env bash
set -u
NEXT="${SKE_NEXT:?}"; SIGNAL="${SKE_SIGNAL:?}"; SPECDIR="${SKE_SPECDIR:?}"
emit_text() { printf '%s\n' '{"type":"assistant","message":{"content":[{"type":"text","text":"'"$1"'"}]}}'; }
emit_result() { printf '%s\n' '{"type":"result","is_error":false,"total_cost_usd":'"${2:-0.10}"',"result":"'"$1"'"}'; }

# Corte externo (SKE_CUT): na n-ésima invocação o stub trava ANTES de emitir
# qualquer coisa, prendendo o loop no passo n enquanto o teste o mata. O contador
# vive num arquivo porque cada passo é um processo novo do stub.
if [ -n "${SKE_CUT:-}" ]; then
  n=$(( $(cat "${SKE_COUNT:?}" 2>/dev/null || echo 0) + 1 ))
  printf '%s\n' "$n" > "$SKE_COUNT"
  [ "$n" -lt "$SKE_CUT" ] || { sleep 60; exit 0; }
fi

IFS= read -r msg || exit 0
printf '%s\n' '{"type":"system","subtype":"init","session_id":"fake"}'

case "$msg" in
  *zion-prd-specify-prompt*)
    if [ "${SKE_STACK:-0}" = 1 ]; then
      printf '/speckit.specify "faça a spec do preview usando React e Postgres"\n' > "$NEXT"
    else
      printf '/speckit.specify "faça a spec do preview; resultado observável: o usuário vê o preview. RF cobertos: RF-01. Nome da feature: preview."\n' > "$NEXT"
    fi
    printf 'OK\n' > "$SIGNAL"
    emit_text 'prompt do specify pronto'; emit_result 'prompt do specify pronto' ;;
  *speckit.specify*)
    printf '%s\n' '# Spec: preview' '' '**RF cobertos:** RF-01' '' '## Requisitos' '- vê o preview' > "$SPECDIR/spec.md"
    emit_text 'spec.md criado'; emit_result 'spec.md criado' ;;
  *zion-prd-plan-prompt*)
    if [ "${SKE_SUFFICIENCY:-0}" = 1 ]; then
      : > "$NEXT"; printf 'SUFFICIENCY_STOP\n' > "$SIGNAL"
      emit_text 'spec vago demais'; emit_result 'spec vago demais'
    else
      printf '/speckit.plan "plano honrando ADR-001"\n' > "$NEXT"; printf 'OK\n' > "$SIGNAL"
      emit_text 'prompt do plan pronto'; emit_result 'prompt do plan pronto'
    fi ;;
  *speckit.plan*)
    printf '%s\n' '# Plan' '- stack: livre' > "$SPECDIR/plan.md"
    emit_text 'plan.md criado'; emit_result 'plan.md criado' ;;
  *speckit.tasks*)
    printf '%s\n' '# Tasks' '- [ ] T1' > "$SPECDIR/tasks.md"
    emit_text 'tasks.md criado'; emit_result 'tasks.md criado' ;;
  *speckit.analyze*)
    if [ "${SKE_ANALYZE_CRIT:-0}" = 1 ]; then
      emit_text 'achei problema'; emit_result '| ID | Severity | Resumo |\n| A1 | CRITICAL | plan contradiz spec |'
    else
      emit_text 'tudo consistente'; emit_result 'No critical inconsistencies. All LOW.'
    fi ;;
  *zion-prd-trace*)
    emit_text 'reconciliei o canon'; emit_result 'reconciliei §12, backlog e architecture' ;;
  *) emit_text 'passo desconhecido'; emit_result 'passo desconhecido' ;;
esac
STUB
  chmod +x "$ROOT/bin/claude"

  # Stub de speckit-clarify-loop: sai rc 0 (ou SKE_CLARIFY_RC).
  cat > "$ROOT/bin/speckit-clarify-loop" <<'CL'
#!/usr/bin/env bash
exit "${SKE_CLARIFY_RC:-0}"
CL
  chmod +x "$ROOT/bin/speckit-clarify-loop"

  rm -rf "$STATE"
fi

common_env=(
  "PATH=$ROOT/bin:$PATH"
  "SPECKIT_E2E_CHECK_PRD=$HERE/../scripts/check-prd.sh"
  "SKE_NEXT=$STATE/next.txt" "SKE_SIGNAL=$STATE/signal.txt"
  "SKE_SPECDIR=$SPECDIR"
  "SKE_STACK=${SKE_STACK:-0}" "SKE_SUFFICIENCY=${SKE_SUFFICIENCY:-0}"
  "SKE_ANALYZE_CRIT=${SKE_ANALYZE_CRIT:-0}" "SKE_CLARIFY_RC=${SKE_CLARIFY_RC:-0}"
  "SKE_COUNT=$ROOT/turns"
)

# No resume, a tree do repo-alvo está suja (artefatos do run anterior, não
# commitados — o loop nunca commita). O arranque exige tree limpa; --allow-dirty
# é o que o resume real também passaria.
extra_flags=()
[ "$RESUME" -eq 1 ] && extra_flags=( --allow-dirty )

if [ -n "${SKE_CUT:-}" ]; then
  # Corte externo (design §Verificação): trava o loop no passo SKE_CUT, mata em
  # voo, e verifica que o state guardou os done= dos passos ANTERIORES e que o
  # artefato do passo cortado NÃO nasceu — a retomada barata que o run real não teve.
  rm -rf "$STATE"; : > "$ROOT/turns"
  env "${common_env[@]}" "SKE_CUT=$SKE_CUT" "$LOOP" "$SLUG" --repo "$REPO" "$@" >/dev/null 2>&1 &
  loop_pid=$!
  ok=''
  for ((i = 0; i < 300; i++)); do
    if [ "$(cat "$ROOT/turns" 2>/dev/null || echo 0)" -ge "$SKE_CUT" ]; then ok=1; break; fi
    sleep 0.1
  done
  sleep 0.3                                   # deixa o done= do passo anterior assentar
  kill -TERM "$loop_pid" 2>/dev/null
  wait "$loop_pid" 2>/dev/null
  dones="$(grep -c '^done=' "$STATE/state" 2>/dev/null || echo 0)"
  expect=$((SKE_CUT - 1))
  spec_absent=$([ -f "$SPECDIR/spec.md" ] && echo no || echo yes)
  if [ -n "$ok" ] && [ "$dones" -eq "$expect" ]; then
    printf 'corte OK: state tem %s done= (esperado %s); spec.md ausente=%s; retomável\n' \
      "$dones" "$expect" "$spec_absent"
    exit 0
  fi
  printf 'corte FALHOU: state tem %s done= (esperado %s); spec.md ausente=%s\n' \
    "$dones" "$expect" "$spec_absent"
  exit 1
else
  env "${common_env[@]}" "$LOOP" "$SLUG" --repo "$REPO" "${extra_flags[@]}" "$@"
fi
