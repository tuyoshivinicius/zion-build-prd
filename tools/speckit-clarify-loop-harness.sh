#!/usr/bin/env bash
# Harness sem custo do speckit-clarify-loop: um repo Spec Kit falso e um stub
# determinístico de `claude`, para exercitar o caminho de execução inteiro —
# preflight, fifo, classificação, snapshot, narração e resumo — sem gastar cota.
#
# Uso:  tools/speckit-clarify-loop-harness.sh [flags do loop…]
#       SKCL_NOSENT=1 …   # stub sem sentinela          (R-09)
#       SKCL_LEAK=1   …   # stub vaza CLARIFY_ no spec  (M-06)
#       SKCL_CITA=1   …   # spec base CITA a sentinela  (D-5)
#
# O repo falso mora em /tmp/skcl-harness/repo e é recriado a cada invocação.
# Não é instalado: existe só para o desenvolvimento do loop.
set -u
ROOT=/tmp/skcl-harness
LOOP="$(cd "$(dirname "$0")" && pwd)/speckit-clarify-loop"
SPEC="$ROOT/repo/specs/001-fake/spec.md"

rm -rf "$ROOT"
mkdir -p "$ROOT/bin" "$ROOT/repo/.specify/scripts/bash" "$ROOT/repo/specs/001-fake"
if [ "${SKCL_CITA:-0}" -eq 1 ]; then
  # D-5: um spec que DOCUMENTA o contrato. A ocorrência é preexistente, então a
  # guarda do M-06 não pode abortar por causa dela — nem na rodada 1, nem nunca.
  # 11 linhas.
  printf '%s\n' '# Spec fake' '' '## Requisitos' '' '- RF-01 algo' \
    '' '## Contrato' '' '```' 'CLARIFY_STATE: ASKING' '```' > "$SPEC"
else
  printf '%s\n' '# Spec fake' '' '## Requisitos' '' '- RF-01 algo' > "$SPEC"
fi

cat > "$ROOT/repo/.specify/scripts/bash/check-prerequisites.sh" <<EOF
#!/usr/bin/env bash
printf '{"FEATURE_SPEC":"%s"}\n' "$SPEC"
EOF
chmod +x "$ROOT/repo/.specify/scripts/bash/check-prerequisites.sh"

git -C "$ROOT/repo" init -q
git -C "$ROOT/repo" add -A
git -C "$ROOT/repo" -c user.email=harness@local -c user.name=harness commit -qm 'spec fake'

cat > "$ROOT/bin/claude" <<'STUB'
#!/usr/bin/env bash
# Stub de `claude`. Consome o /speckit-clarify, pergunta, espera o `yes`,
# escreve no spec (o Edit da skill) e fecha com um Completion Report. Sob
# --dry-run o `yes` nunca chega: o read pega EOF e o stub sai sem escrever, que
# é exatamente o que o modo promete.
#
# Cada turno sai DUAS vezes, como no stream real: um evento `assistant` com a
# prosa (que é o que o monitor narra) e o `result` (que é o que o classificador
# lê). Sem o primeiro, a sentinela não apareceria no round-NN.log e o harness
# não modelaria a narração.
#
# Os `\n` ficam LITERAIS de propósito — são escapes de JSON, e viajam como
# argumento de %s justamente para o printf não os interpretar.
SPEC="${SKCL_SPEC:?}"
ask=''; fim=''
if [ "${SKCL_NOSENT:-0}" -eq 0 ]; then
  ask='\n\nCLARIFY_STATE: ASKING'
  # Ordem do D-7: zero ou mais CLARIFY_DECISION, e a CLARIFY_STATE por último.
  fim='\n\nCLARIFY_DECISION: assunto do teste -> A (recomendada)\nCLARIFY_STATE: COMPLETE'
fi
P1='**Recomendada:** Opção A — texto.'"$ask"
P2='## Relatório\n\n### Próximo comando\n\n`/speckit-plan`'"$fim"
IFS= read -r _prompt || exit 0
printf '%s\n' '{"type":"system","subtype":"init","session_id":"fake"}'
printf '%s\n' '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"check-prerequisites.sh --json --paths-only"}}]}}'
printf '%s\n' '{"type":"assistant","message":{"content":[{"type":"text","text":"'"$P1"'"}]}}'
printf '%s\n' '{"type":"result","is_error":false,"total_cost_usd":0.10,"result":"'"$P1"'"}'
IFS= read -r _yes || exit 0
printf '\n## Clarifications\n\n- Q1: A\n' >> "$SPEC"
if [ "${SKCL_LEAK:-0}" -eq 1 ]; then
  # M-06: o vazamento que a guarda existe para pegar — linha NOVA no spec,
  # começada por CLARIFY_ na primeira coluna.
  printf 'CLARIFY_STATE: COMPLETE\n' >> "$SPEC"
fi
printf '%s\n' '{"type":"assistant","message":{"content":[{"type":"text","text":"'"$P2"'"}]}}'
printf '%s\n' '{"type":"result","is_error":false,"total_cost_usd":0.25,"result":"'"$P2"'"}'
STUB
chmod +x "$ROOT/bin/claude"

PATH="$ROOT/bin:$PATH" SKCL_SPEC="$SPEC" \
  SKCL_NOSENT="${SKCL_NOSENT:-0}" SKCL_LEAK="${SKCL_LEAK:-0}" \
  "$LOOP" --repo "$ROOT/repo" "$@"
